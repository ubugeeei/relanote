import fs from "node:fs";
import path from "node:path";
import { execFileSync } from "node:child_process";
import { highlightCode } from "./highlight.mjs";
import { homeIntro, shell } from "./views.mjs";

const root = process.cwd();
const dist = path.join(root, "dist");
const docs = path.join(root, "docs");
const site = path.join(root, "src", "site");

const groups = [
  ["Guide", "guide"],
  ["Tutorial", "tutorial"],
  ["Reference", "reference"],
  ["Deep Dive", "deep-dive"],
  ["More", ""],
];
const orderedSlugs = "guide/introduction guide/installation guide/quick-start guide/blocks guide/intervals guide/scales-and-chords guide/rhythm guide/functions guide/control-flow guide/pipes guide/layers guide/parts-and-sections guide/mixing guide/synth guide/presets guide/microtones tutorial/getting-started tutorial/first-melody tutorial/building-chords tutorial/creating-a-song tutorial/synth-sounds reference/syntax reference/types reference/intervals reference/builtins reference/modules reference/cli deep-dive/architecture deep-dive/language-design deep-dive/moonbit-implementation deep-dive/music-theory deep-dive/advanced-harmony deep-dive/synthesizer-basics deep-dive/sound-synthesis deep-dive/preset-reference showcase cookbook glossary faq".split(" ");

function clean() {
  fs.rmSync(dist, { recursive: true, force: true });
  fs.mkdirSync(dist, { recursive: true });
}

function copyIfExists(from, to) {
  if (fs.existsSync(from)) fs.cpSync(from, to, { recursive: true });
}

function walk(dir) {
  return fs.readdirSync(dir, { withFileTypes: true }).flatMap((entry) => {
    const full = path.join(dir, entry.name);
    if (entry.isDirectory()) return walk(full);
    if (entry.name.endsWith(".md")) return [full];
    return [];
  });
}

function slug(file) {
  return path.relative(docs, file).replaceAll(path.sep, "/").replace(/\.md$/, "");
}

function rank(file) {
  const i = orderedSlugs.indexOf(slug(file));
  return i < 0 ? 999 : i;
}

function pageUrl(file) {
  const s = slug(file);
  return s === "index" ? "/docs/" : `/docs/${s}.html`;
}

function outPath(file) {
  const s = slug(file);
  return path.join(dist, "docs", s === "index" ? "index.html" : `${s}.html`);
}

function stripFrontmatter(src) {
  if (!src.startsWith("---\n")) return src;
  const end = src.indexOf("\n---", 4);
  return end < 0 ? src : src.slice(src.indexOf("\n", end + 4) + 1);
}

function titleOf(file) {
  const body = stripFrontmatter(fs.readFileSync(file, "utf8"));
  const heading = body.split(/\r?\n/).find((line) => line.startsWith("# "));
  if (heading) return heading.replace(/^#\s+/, "").trim();
  if (slug(file) === "index") return "Overview";
  return path.basename(file, ".md").replaceAll("-", " ");
}

function escapeHtml(text) {
  return text
    .replaceAll("&", "&amp;")
    .replaceAll("<", "&lt;")
    .replaceAll(">", "&gt;");
}

function href(raw, fromFile) {
  if (/^(https?:|mailto:|#)/.test(raw)) return raw;
  if (raw.startsWith("/")) {
    const [target, hash = ""] = raw.split("#");
    if (/^\/(guide|tutorial|reference|deep-dive)\//.test(target)) {
      const next = path.posix.extname(target) ? target : `${target}.html`;
      return `/docs${next}${hash ? `#${hash}` : ""}`;
    }
    return raw.replace(/\.md($|#)/, ".html$1");
  }
  const base = path.dirname(pageUrl(fromFile));
  const resolved = path.posix.normalize(path.posix.join(base, raw));
  if (resolved.endsWith(".md")) return resolved.replace(/\.md$/, ".html");
  if (!path.posix.extname(resolved) && raw.startsWith(".")) return `${resolved}.html`;
  if (!path.posix.extname(resolved) && !raw.includes("#")) return `${resolved}.html`;
  return resolved.replace(/\.md(#.*)?$/, ".html$1");
}

function inline(text, fromFile) {
  let out = escapeHtml(text);
  out = out.replace(/`([^`]+)`/g, "<code>$1</code>");
  out = out.replace(/\*\*([^*]+)\*\*/g, "<strong>$1</strong>");
  out = out.replace(/\[([^\]]+)\]\(([^)]+)\)/g, (_, label, raw) => {
    return `<a href="${href(raw, fromFile)}">${label}</a>`;
  });
  return out;
}

function renderMarkdown(src, fromFile) {
  const lines = stripFrontmatter(src).split(/\r?\n/);
  const html = [];
  let inCode = false;
  let code = [];
  let codeLang = "";
  let inUl = false;
  let inOl = false;
  let inTable = false;
  let para = [];
  const closePara = () => {
    if (para.length) html.push(`<p>${inline(para.join(" "), fromFile)}</p>`);
    para = [];
  };
  const closeLists = () => {
    if (inUl) html.push("</ul>");
    if (inOl) html.push("</ol>");
    if (inTable) html.push("</tbody></table>");
    inUl = inOl = inTable = false;
  };
  const attr = (text) => escapeHtml(text).replaceAll('"', "&quot;");
  for (const line of lines) {
    if (line.startsWith("```")) {
      closePara();
      closeLists();
      if (inCode) html.push(highlightCode(code.join("\n"), codeLang));
      else codeLang = line.slice(3).trim().split(/\s+/)[0] || "";
      code = [];
      inCode = !inCode;
      continue;
    }
    if (inCode) { code.push(line); continue; }
    if (!line.trim()) {
      closePara();
      closeLists();
      continue;
    }
    const image = line.trim().match(/^<img\s+[^>]*src="([^"]+)"[^>]*alt="([^"]*)"[^>]*\/?>$/);
    if (image) {
      closePara();
      closeLists();
      html.push(`<figure class="doc-figure"><img src="${attr(href(image[1], fromFile))}" alt="${attr(image[2])}"></figure>`);
      continue;
    }
    const table = line.trim();
    if (/^\|.*\|$/.test(table)) {
      closePara();
      const cells = table.slice(1, -1).split("|").map((cell) => cell.trim());
      if (cells.every((cell) => /^:?-{3,}:?$/.test(cell))) continue;
      if (!inTable) {
        closeLists();
        html.push("<table><tbody>");
        inTable = true;
      }
      html.push(`<tr>${cells.map((cell) => `<td>${inline(cell, fromFile)}</td>`).join("")}</tr>`);
      continue;
    }
    const h = line.match(/^(#{1,4})\s+(.*)$/);
    if (h) {
      closePara();
      closeLists();
      html.push(`<h${h[1].length}>${inline(h[2], fromFile)}</h${h[1].length}>`);
      continue;
    }
    const ul = line.match(/^\s*[-*]\s+(.*)$/);
    if (ul) {
      closePara();
      if (!inUl) html.push("<ul>");
      inUl = true;
      html.push(`<li>${inline(ul[1], fromFile)}</li>`);
      continue;
    }
    const ol = line.match(/^\s*\d+\.\s+(.*)$/);
    if (ol) {
      closePara();
      if (!inOl) html.push("<ol>");
      inOl = true;
      html.push(`<li>${inline(ol[1], fromFile)}</li>`);
      continue;
    }
    if (line.trim() === "---") {
      closePara();
      closeLists();
      html.push("<hr>");
      continue;
    }
    para.push(line.trim());
  }
  closePara();
  closeLists();
  if (inCode) html.push(highlightCode(code.join("\n"), codeLang));
  return html.join("\n");
}

function nav(files, activeFile = null) {
  const items = files.filter((file) => slug(file) !== "index");
  const activeUrl = activeFile ? pageUrl(activeFile) : "";
  return groups.map(([label, prefix]) => {
    const groupFiles = items.filter((file) => {
      const s = slug(file);
      return prefix ? s.startsWith(`${prefix}/`) : !s.includes("/");
    });
    if (!groupFiles.length) return "";
    const links = groupFiles.map((file) => {
      const current = pageUrl(file) === activeUrl ? ` class="active"` : "";
      return `<a${current} href="${pageUrl(file)}">${escapeHtml(titleOf(file))}</a>`;
    }).join("");
    return `<section><h3>${label}</h3>${links}</section>`;
  }).join("");
}

function writeCss() {
  fs.copyFileSync(path.join(site, "site.css"), path.join(dist, "site.css"));
  fs.copyFileSync(path.join(site, "chromatic.css"), path.join(dist, "chromatic.css"));
  fs.copyFileSync(path.join(site, "audio_nodes.js"), path.join(dist, "audio_nodes.js"));
  fs.copyFileSync(path.join(site, "audio.js"), path.join(dist, "audio.js"));
  fs.copyFileSync(path.join(site, "site.js"), path.join(dist, "site.js"));
}

function writeRuntime() { execFileSync("moon", ["build", "--target", "wasm-gc", "src/preview_wasm"], { stdio: "inherit" }); fs.copyFileSync(path.join(root, "_build", "wasm-gc", "debug", "build", "src", "preview_wasm", "preview_wasm.wasm"), path.join(dist, "preview.wasm")); }

function build() {
  clean();
  const files = walk(docs).sort((a, b) => rank(a) - rank(b) || slug(a).localeCompare(slug(b)));
  fs.mkdirSync(path.join(dist, "docs"), { recursive: true });
  for (const file of files) {
    fs.mkdirSync(path.dirname(outPath(file)), { recursive: true });
    const isHome = slug(file) === "index";
    let content = renderMarkdown(fs.readFileSync(file, "utf8"), file);
    if (isHome) content = homeIntro() + content;
    fs.writeFileSync(outPath(file), shell({ title: titleOf(file), content, navHtml: nav(files, file), pageClass: isHome ? "home" : "doc" }));
  }
  fs.copyFileSync(path.join(dist, "docs", "index.html"), path.join(dist, "index.html"));
  writeCss();
  writeRuntime();
  copyIfExists(path.join(root, "assets"), path.join(dist, "assets"));
  copyIfExists(path.join(root, "assets", "diagrams"), path.join(dist, "diagrams"));
  copyIfExists(path.join(root, "examples"), path.join(dist, "examples"));
  fs.mkdirSync(path.join(dist, "playground"), { recursive: true });
  fs.writeFileSync(path.join(dist, "playground", "index.html"), shell({ title: "Studio", navHtml: nav(files), content: `<p class="eyebrow">Studio is backstage</p><h1>Studio is being rebuilt.</h1><p class="lede">The public surface is temporarily hidden while the editor, synth, and DAW experience are redesigned. The showcase carries the listening experience for now.</p><p><a class="pill primary" href="/docs/showcase.html">Hear the showcase</a></p>` }));
}

build();
