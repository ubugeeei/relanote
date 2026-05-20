import fs from "node:fs";
import path from "node:path";
import { execFileSync } from "node:child_process";

const root = process.cwd();
const dist = path.join(root, "dist");
const docs = path.join(root, "docs");

const groups = [
  ["Guide", "guide"],
  ["Tutorial", "tutorial"],
  ["Reference", "reference"],
  ["Deep Dive", "deep-dive"],
  ["More", ""],
];

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
  let inUl = false;
  let inOl = false;
  let para = [];
  const closePara = () => {
    if (para.length) html.push(`<p>${inline(para.join(" "), fromFile)}</p>`);
    para = [];
  };
  const closeLists = () => {
    if (inUl) html.push("</ul>");
    if (inOl) html.push("</ol>");
    inUl = false;
    inOl = false;
  };
  for (const line of lines) {
    if (line.startsWith("```")) {
      closePara();
      closeLists();
      html.push(inCode ? "</code></pre>" : "<pre><code>");
      inCode = !inCode;
      continue;
    }
    if (inCode) {
      html.push(escapeHtml(line));
      continue;
    }
    if (!line.trim()) {
      closePara();
      closeLists();
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
  return html.join("\n");
}

function nav(files) {
  const items = files.filter((file) => slug(file) !== "index");
  return groups.map(([label, prefix]) => {
    const groupFiles = items.filter((file) => {
      const s = slug(file);
      return prefix ? s.startsWith(`${prefix}/`) : !s.includes("/");
    });
    if (!groupFiles.length) return "";
    const links = groupFiles.map((file) => {
      return `<a href="${pageUrl(file)}">${escapeHtml(titleOf(file))}</a>`;
    }).join("");
    return `<section><h3>${label}</h3>${links}</section>`;
  }).join("");
}

function shell({ title, content, navHtml }) {
  return `<!doctype html>
<html lang="en">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>${escapeHtml(title)} | relanote</title>
<link rel="stylesheet" href="/site.css">
</head>
<body>
<header><a class="brand" href="/docs/">relanote</a><a href="/playground/">Playground</a><a href="https://github.com/ubugeeei/relanote">GitHub</a></header>
<div class="layout">
<aside><details open><summary>Documentation</summary>${navHtml}</details></aside>
<main>${content}</main>
</div>
</body>
</html>`;
}

function writeCss() {
  fs.writeFileSync(path.join(dist, "site.css"), `
:root{color-scheme:light dark;--bg:#f8fafc;--fg:#0f172a;--muted:#64748b;--line:#dbe3ee;--panel:#fff;--brand:#0f766e}
@media(prefers-color-scheme:dark){:root{--bg:#0b1020;--fg:#e5edf5;--muted:#94a3b8;--line:#263246;--panel:#121a2a;--brand:#2dd4bf}}
*{box-sizing:border-box}body{margin:0;background:var(--bg);color:var(--fg);font:16px/1.65 system-ui,-apple-system,BlinkMacSystemFont,"Segoe UI",sans-serif}
header{position:sticky;top:0;z-index:2;display:flex;gap:1rem;align-items:center;height:3.25rem;padding:0 1rem;border-bottom:1px solid var(--line);background:var(--panel)}
a{color:var(--brand);text-decoration:none}a:hover{text-decoration:underline}.brand{font-weight:800;color:var(--fg);margin-right:auto}
.layout{display:grid;grid-template-columns:18rem minmax(0,1fr);max-width:1180px;margin:0 auto}
aside{border-right:1px solid var(--line);min-height:calc(100vh - 3.25rem);padding:1rem;position:sticky;top:3.25rem;align-self:start;max-height:calc(100vh - 3.25rem);overflow:auto}
summary{font-weight:700;cursor:pointer;margin-bottom:.75rem}aside h3{font-size:.8rem;text-transform:uppercase;letter-spacing:.06em;color:var(--muted);margin:1rem 0 .35rem}
aside a{display:block;padding:.28rem 0;color:var(--fg);font-size:.92rem}main{min-width:0;padding:2rem 1.5rem 4rem;max-width:820px}
h1{font-size:2.4rem;line-height:1.1;margin:.2rem 0 1rem}h2{margin-top:2rem;border-top:1px solid var(--line);padding-top:1rem}h3{margin-top:1.5rem}
pre{overflow:auto;background:var(--panel);border:1px solid var(--line);border-radius:.45rem;padding:1rem}code{font-family:ui-monospace,SFMono-Regular,Menlo,monospace}
p code,li code{background:var(--panel);border:1px solid var(--line);border-radius:.25rem;padding:.05rem .25rem}img{max-width:100%}hr{border:0;border-top:1px solid var(--line);margin:2rem 0}
@media(max-width:860px){.layout{grid-template-columns:1fr}aside{position:relative;top:0;min-height:0;max-height:none;border-right:0;border-bottom:1px solid var(--line)}main{padding-top:1rem}}
`);
}

function build() {
  clean();
  const files = walk(docs).sort();
  const navHtml = nav(files);
  fs.mkdirSync(path.join(dist, "docs"), { recursive: true });
  for (const file of files) {
    fs.mkdirSync(path.dirname(outPath(file)), { recursive: true });
    const content = renderMarkdown(fs.readFileSync(file, "utf8"), file);
    fs.writeFileSync(outPath(file), shell({ title: titleOf(file), content, navHtml }));
  }
  fs.copyFileSync(path.join(dist, "docs", "index.html"), path.join(dist, "index.html"));
  writeCss();
  copyIfExists(path.join(root, "assets"), path.join(dist, "assets"));
  copyIfExists(path.join(root, "examples"), path.join(dist, "examples"));
  fs.mkdirSync(path.join(dist, "playground"), { recursive: true });
  fs.copyFileSync(path.join(root, "web", "App.mbtv"), path.join(dist, "playground", "App.mbtv"));
  execFileSync("moon", ["run", ".mooncakes/ubugeeei/vapor_moon/src/cmd/vapor_moon", "--", "compile", "web/App.mbtv"], { stdio: ["ignore", fs.openSync(path.join(dist, "playground", "compile.snapshot"), "w"), "inherit"] });
  fs.writeFileSync(path.join(dist, "playground", "index.html"), shell({
    title: "Playground",
    navHtml,
    content: `<h1>Playground</h1><p>The Vapor Moon source is available as <a href="/playground/App.mbtv">App.mbtv</a>.</p><p>The compile snapshot is available as <a href="/playground/compile.snapshot">compile.snapshot</a>.</p>`,
  }));
}

build();
