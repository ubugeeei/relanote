function escapeHtml(text) {
  return text
    .replaceAll("&", "&amp;")
    .replaceAll("<", "&lt;")
    .replaceAll(">", "&gt;");
}

export function homeIntro() {
  return `<section class="top-hero"><div class="hero-grid"><div class="hero-copy"><p class="eyebrow">MoonBit music language</p><h1>relanote</h1><p class="lede">Relative musical structure, typed and rendered through one MoonBit pipeline.</p><p><a class="pill primary" href="/docs/guide/introduction.html">Read the guide</a><a class="pill" href="/playground/">Open studio</a></p></div><div class="hero-stage" aria-hidden="true"><span class="gate g1"></span><span class="gate g2"></span><span class="gate g3"></span><div class="code-card"><b>main.rela</b><code>theme <span class="tok-op">|&gt;</span> <span class="tok-fn">transpose</span> <span class="tok-type">P5</span> <span class="tok-op">|&gt;</span> <span class="tok-fn">repeat</span> <span class="tok-num">2</span></code></div><div class="roll-card"><i></i><i></i><i></i><i></i></div></div></div></section><section class="home-strip"><div><b>Relative first</b><span>Intervals, blocks, chords, rhythm, and transforms stay musical after movement.</span></div><div><b>Typed pipeline</b><span>Parser, checker, evaluator, formatter, LSP, render, and studio share the same source tree.</span></div><div><b>Designed to compose</b><span>Edit, inspect, hear, export, and iterate without leaving the language surface.</span></div></section>`;
}

export function playgroundContent() {
  return `<section class="studio-page"><div class="studio-intro"><p class="eyebrow">Vapor Moon studio</p><h1>Compose, inspect, render.</h1><p class="lede">A DAW-shaped workspace for Relanote source: file stack, transport, editor, staff, piano roll, diagnostics, console, and export paths in one surface.</p><p><a class="pill primary" href="/playground/App.mbtv">View Vapor Moon component</a><a class="pill" href="/playground/compile.snapshot">Compile snapshot</a></p></div><section class="studio-frame"><header><b>relanote Studio</b><nav><span><i class="ico save"></i>Save</span><span><i class="ico share"></i>Share</span><span><i class="ico midi"></i>MIDI</span></nav></header><aside class="studio-files"><b>Files</b><span class="active">main.rela</span><span>ambient-pad.rela</span><span>drums.rela</span><button>Import</button></aside><main class="studio-editor"><div class="transport"><button><i class="ico play"></i>Play</button><span>9 notes / 8 beats</span><i></i></div><div class="ruler"><i></i><i></i><i></i><i></i><i></i><i></i><i></i><i></i></div><pre><code><span class="tok-kw">scale</span> Major = { R, M2, M3, P4, P5, M6, M7 }
<span class="tok-kw">let</span> theme = | &lt;1&gt; &lt;3&gt; &lt;5&gt; &lt;8&gt; |
theme |&gt; repeat 2 |&gt; transpose P5</code></pre></main><aside class="studio-inspector"><section><b>Staff</b><div class="mini-staff"><i></i><i></i><i></i><i></i><em></em></div></section><section><b>Piano Roll</b><div class="mini-roll"><i></i><i></i><i></i><i></i></div></section><section><b>Diagnostics</b><pre>Clean: no diagnostics</pre></section></aside><footer><span>Melody</span><span>Harmony</span><span>Render bus</span></footer></section></section>`;
}

export function shell({ title, content, navHtml, pageClass = "doc" }) {
  return `<!doctype html>
<html lang="en">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>${escapeHtml(title)} | relanote</title>
<meta name="description" content="Relative music structure, typed and rendered through MoonBit.">
<meta property="og:title" content="${escapeHtml(title)} | relanote">
<meta property="og:description" content="Relative music structure, typed and rendered through MoonBit.">
<meta property="og:image" content="https://relanote.void.app/assets/og-image.svg">
<meta name="twitter:card" content="summary_large_image">
<link rel="stylesheet" href="/site.css">
<link rel="stylesheet" href="/chromatic.css">
<script defer src="/site.js"></script>
</head>
<body>
<header class="site-topbar"><a class="brand" href="/docs/"><img src="/assets/logo-icon.svg" alt="">relanote</a><nav><a href="/docs/">Docs</a><a href="/playground/">Studio</a><a href="https://github.com/ubugeeei/relanote">GitHub</a></nav></header>
${pageClass === "home" ? `<main class="top-home">${content}</main>` : pageClass === "playground" ? `<main class="studio-home">${content}</main>` : `
<div class="site-shell">
<aside class="sidebar"><div class="nav-title">Documentation</div>${navHtml}</aside>
<main class="content ${pageClass}">${content}</main>
</div>`}
</body>
</html>`;
}
