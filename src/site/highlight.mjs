const kw = new Set(
  "and as catch const else enum false fn for if import in let match mut pub return struct true type using while with scale chord part section song".split(" "),
);

function escapeHtml(text) {
  return text
    .replaceAll("&", "&amp;")
    .replaceAll("<", "&lt;")
    .replaceAll(">", "&gt;");
}

function preview(source, name) {
  if (name !== "rela") return "";
  const notes = [...source.matchAll(/<(\d+)>|\b([A-G][#b]?\d|R|[PMmAd]\d)\b/g)].slice(0, 9);
  if (!notes.length) return "";
  const bars = notes.map((_, i) => {
    const x = 8 + i * 9;
    const y = 18 + (i % 5) * 13;
    const w = 12 + (i % 3) * 5;
    return `<i style="--x:${x}%;--y:${y}%;--w:${w}%"></i>`;
  }).join("");
  return `<aside class="code-preview" aria-label="Code preview"><b>Preview <button class="preview-play" type="button">Play</button></b><div class="preview-roll">${bars}</div><span>${notes.length} events</span></aside>`;
}

function tokenClass(token) {
  if (/^["'`]/.test(token)) return "str";
  if (/^(#|\/\/|;)/.test(token)) return "comment";
  if (/^\d/.test(token)) return "num";
  if (/^[A-Z][\w]*$/.test(token)) return "type";
  if (kw.has(token)) return "kw";
  if (/^[{}()[\],.:|=+\-*/<>]+$/.test(token)) return "op";
  return "";
}

function highlightLine(line) {
  const token = /"(?:\\.|[^"])*"|'(?:\\.|[^'])*'|`(?:\\.|[^`])*`|#.*|\/\/.*|;.*|\b\d+(?:\.\d+)?\b|\b[A-Za-z_][\w!?]*\b|[{}()[\],.:|=+\-*/<>]+/g;
  let out = "";
  let at = 0;
  for (const match of line.matchAll(token)) {
    out += escapeHtml(line.slice(at, match.index));
    const cls = tokenClass(match[0]);
    const text = escapeHtml(match[0]);
    out += cls ? `<span class="tok-${cls}">${text}</span>` : text;
    at = match.index + match[0].length;
  }
  return out + escapeHtml(line.slice(at));
}

export function highlightCode(source, lang = "") {
  const name = lang.replace(/[^a-z0-9_-]/gi, "").toLowerCase() || "text";
  const code = source.split(/\r?\n/).map(highlightLine).join("\n");
  return `<figure class="code-kit language-${name}"><figcaption><span>${name}</span><button class="code-copy" type="button">Copy</button></figcaption><div class="code-wrap"><pre class="code-block language-${name}"><code>${code}</code></pre>${preview(source, name)}</div></figure>`;
}
