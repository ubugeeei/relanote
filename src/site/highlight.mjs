const kw = new Set(
  "and as catch const else enum false fn for if import in let match mut pub return struct true type using while with scale chord part section song".split(" "),
);

function escapeHtml(text) {
  return text
    .replaceAll("&", "&amp;")
    .replaceAll("<", "&lt;")
    .replaceAll(">", "&gt;");
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
  return `<pre class="code-block language-${name}"><code>${code}</code></pre>`;
}
