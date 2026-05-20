function escapeHtml(text) {
  return text
    .replaceAll("&", "&amp;")
    .replaceAll("<", "&lt;")
    .replaceAll(">", "&gt;");
}

export function homeIntro() {
  return `<section class="top-hero"><div class="hero-grid"><div class="hero-copy"><p class="eyebrow">relative + note</p><h1>relanote</h1><p class="lede">Compose by distance: notes as relationships, phrases as motion, structure as something you can move without breaking.</p><p><a class="pill primary" href="/docs/guide/introduction.html">Read the guide</a><a class="pill" href="/playground/">Open studio</a></p></div><div class="hero-stage" aria-hidden="true"><span class="rel-axis"></span><span class="rel-line r1"></span><span class="rel-line r2"></span><span class="rel-line r3"></span><span class="note-node root">R</span><span class="note-node n3">+M3</span><span class="note-node n5">+P5</span><span class="note-node n8">+P8</span><div class="code-card"><b>main.rela</b><code>root <span class="tok-op">+</span> <span class="tok-type">M3</span> <span class="tok-op">+</span> <span class="tok-type">P5</span> <span class="tok-op">|&gt;</span> <span class="tok-fn">move</span></code></div><div class="roll-card"><i></i><i></i><i></i><i></i></div></div></div></section><section class="home-strip"><div><b>Relative first</b><span>Every pitch is described from a living reference, so transposition changes place rather than meaning.</span></div><div><b>Motion as material</b><span>Intervals, blocks, chords, rhythm, and transforms stay readable as gestures.</span></div><div><b>Designed to compose</b><span>Edit, inspect, hear, export, and iterate without leaving the language surface.</span></div></section>`;
}

export function playgroundContent() {
  return `<section class="studio-page"><div class="studio-intro"><p class="eyebrow">DAW-shaped source studio</p><h1>Editor, synth, timeline.</h1><p class="lede">A browser studio where relative notation, playback, synthesis, piano roll, staff preview, diagnostics, and export controls sit on one instrument-like surface.</p><p><a class="pill primary" href="/playground/App.mbtv">View Vapor Moon component</a><a class="pill" href="/playground/compile.snapshot">Compile snapshot</a></p></div><section class="studio-frame"><header><b>relanote Studio</b><nav><span><i class="ico save"></i>Save</span><span><i class="ico share"></i>Share</span><span><i class="ico midi"></i>MIDI</span></nav></header><aside class="studio-files"><b>Project</b><span class="active">main.rela</span><span>lead-motion.rela</span><span>pad-layer.rela</span><button>Import</button></aside><main class="studio-editor"><div class="transport"><button class="studio-play" type="button"><i class="ico play"></i>Play</button><span data-studio-summary>loading runtime</span><i></i></div><div class="ruler"><i></i><i></i><i></i><i></i><i></i><i></i><i></i><i></i></div><pre><code contenteditable="true" spellcheck="false"><span class="tok-kw">scale</span> Major = { R, M2, M3, P4, P5, M6, M7 }
<span class="tok-kw">let</span> theme = | &lt;1&gt; &lt;3&gt; &lt;5&gt; &lt;8&gt; |:4
theme</code></pre></main><aside class="studio-inspector"><section><b>Synth</b><div class="mini-synth"><i></i><i></i><i></i></div></section><section><b>Staff</b><div class="mini-staff"><i></i><i></i><i></i><i></i><em></em></div></section><section><b>Piano Roll</b><div class="mini-roll" data-studio-roll></div></section><section><b>Diagnostics</b><pre data-studio-diag>Clean: no diagnostics</pre></section></aside><footer><span>Melody</span><span>Harmony</span><span>Synth bus</span><span>Render bus</span></footer></section></section>`;
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
