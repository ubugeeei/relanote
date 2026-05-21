import fs from "node:fs";
import path from "node:path";

const outDir = path.join(process.cwd(), "assets", "diagrams");
const esc = (value) => String(value).replaceAll("&", "&amp;").replaceAll("<", "&lt;").replaceAll(">", "&gt;").replaceAll('"', "&quot;");
const text = (x, y, value, cls = "label", extra = "") => `<text class="${cls}" x="${x}" y="${y}" ${extra}>${esc(value)}</text>`;
const rect = (x, y, w, h, cls = "panel", rx = 16) => `<rect class="${cls}" x="${x}" y="${y}" width="${w}" height="${h}" rx="${rx}"/>`;
const line = (x1, y1, x2, y2, cls = "axis", extra = "") => `<line class="${cls}" x1="${x1}" y1="${y1}" x2="${x2}" y2="${y2}" ${extra}/>`;
const pathEl = (d, cls = "line", extra = "") => `<path class="${cls}" d="${d}" ${extra}/>`;
const circle = (x, y, r, cls = "dot") => `<circle class="${cls}" cx="${x}" cy="${y}" r="${r}"/>`;
const poly = (points, cls = "line", extra = "") => pathEl(`M ${points.map((p) => p.join(" ")).join(" L ")}`, cls, extra);

function svg(title, desc, body) {
  return `<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 960 540" role="img" aria-labelledby="title desc">
<title id="title">${esc(title)}</title>
<desc id="desc">${esc(desc)}</desc>
<defs><marker id="arrow" viewBox="0 0 10 10" refX="9" refY="5" markerWidth="8" markerHeight="8" orient="auto"><path d="M 0 0 L 10 5 L 0 10 Z" fill="context-stroke"/></marker></defs>
<style>
:root{color-scheme:light dark}.bg{fill:#fbfbfd}.panel{fill:#fff;stroke:#d8d8df}.soft{fill:#f2f2f7}.ink{fill:#17171b}.muted{fill:#6e6e73}.label{fill:#242428;font:650 16px -apple-system,BlinkMacSystemFont,"SF Pro Text","Segoe UI",sans-serif}.small{fill:#6e6e73;font:600 12px -apple-system,BlinkMacSystemFont,"SF Pro Text","Segoe UI",sans-serif}.title{fill:#111115;font:760 34px -apple-system,BlinkMacSystemFont,"SF Pro Display","Segoe UI",sans-serif}.desc{fill:#6e6e73;font:500 16px -apple-system,BlinkMacSystemFont,"SF Pro Text","Segoe UI",sans-serif}.mono{fill:#55555b;font:650 13px ui-monospace,SFMono-Regular,Menlo,monospace}.axis{stroke:#8e8e93;stroke-width:1.5}.arrow{stroke:#55555b;stroke-width:2.2;fill:none;marker-end:url(#arrow)}.line{fill:none;stroke:#17171b;stroke-width:3;stroke-linecap:round;stroke-linejoin:round}.hot{stroke:#ff4f7a}.mint{stroke:#00a887}.gold{stroke:#c78800}.violet{stroke:#8e6bff}.hotf{fill:#ff4f7a}.mintf{fill:#00a887}.goldf{fill:#f2a900}.violetf{fill:#8e6bff}.darkf{fill:#242428}.lightf{fill:#fff}.fade{opacity:.22}.fillHot{fill:#ff4f7a;opacity:.12}.fillMint{fill:#00a887;opacity:.13}.fillGold{fill:#f2a900;opacity:.16}.fillViolet{fill:#8e6bff;opacity:.13}.mid{text-anchor:middle}.right{text-anchor:end}@media(prefers-color-scheme:dark){.bg{fill:#08090d}.panel{fill:#121319;stroke:#2d2e36}.soft{fill:#1b1c23}.ink,.title{fill:#f5f5f7}.muted,.desc,.small,.mono{fill:#a1a1aa}.label{fill:#f1f1f4}.axis{stroke:#696a73}.arrow{stroke:#bbbcc6}.line{stroke:#f5f5f7}.darkf{fill:#f5f5f7}.lightf{fill:#121319}}
</style>
<rect class="bg" width="960" height="540"/>
${text(64, 62, title, "title")}
${text(66, 92, desc, "desc")}
${body}
</svg>
`;
}

function card(x, y, w, h, title, sub = "", cls = "panel") {
  return `${rect(x, y, w, h, cls)}${text(x + w / 2, y + 34, title, "label mid")}${sub ? text(x + w / 2, y + h - 18, sub, "small mid") : ""}`;
}

function arrow(x1, y1, x2, y2) { return line(x1, y1, x2, y2, "arrow"); }

function wave(kind, x, y, w, h, cls = "hot") {
  const m = y + h / 2, a = h * 0.33, pts = [];
  for (let i = 0; i <= 80; i++) {
    const t = i / 80, p = t * 4 * Math.PI;
    let v = Math.sin(p);
    if (kind === "triangle") v = 2 * Math.abs(2 * (t * 2 - Math.floor(t * 2 + .5))) - 1;
    if (kind === "square") v = Math.sin(p) >= 0 ? 1 : -1;
    if (kind === "saw") v = 2 * ((t * 2) % 1) - 1;
    pts.push([Number((x + t * w).toFixed(1)), Number((m - v * a).toFixed(1))]);
  }
  return poly(pts, `line ${cls}`);
}

function miniPlot(x, y, w, h, title, d, cls = "hot") {
  return `${rect(x, y, w, h)}${line(x + 22, y + h - 28, x + w - 18, y + h - 28)}${line(x + 22, y + 24, x + 22, y + h - 28)}${pathEl(d, `line ${cls}`)}${text(x + w / 2, y + h - 8, title, "small mid")}`;
}

function spectrum(x, y, bars, cls = "hotf") {
  return bars.map((v, i) => `<rect class="${cls}" x="${x + i * 18}" y="${y + 70 - v * 70}" width="10" height="${v * 70}" rx="3"/>`).join("");
}

function architecture() {
  const xs = [54, 194, 334, 474, 614, 754], names = ["source", "lexer", "parser", "types", "eval", "render"];
  const flow = xs.map((x, i) => card(x, 150, 112, 82, names[i], i === 0 ? ".rela" : "")).join("") + xs.slice(0, -1).map((x) => arrow(x + 112, 191, x + 136, 191)).join("");
  const outputs = [[150, "CLI", "midi/export"], [330, "Studio", "preview.wasm"], [510, "Docs", "code preview"], [690, "LSP", "format/diagnose"]];
  return svg("System architecture", "One MoonBit pipeline, many product surfaces.", `${flow}${line(810, 232, 810, 294, "arrow")}${outputs.map(([x, a, b]) => card(x, 308, 130, 88, a, b, "soft")).join("")}${outputs.map(([x]) => arrow(810, 294, x + 65, 308)).join("")}${text(64, 456, "Important: docs, studio, CLI and editor tools call the same parser/evaluator packages.", "label")}${text(64, 482, "That keeps preview audio and command-line output aligned.", "small")}`);
}

function synthVsAcoustic() {
  const left = `${card(76, 150, 138, 72, "gesture", "pluck / bow")}${arrow(214, 186, 284, 186)}${card(284, 150, 138, 72, "material", "string / reed")}${arrow(422, 186, 492, 186)}${card(492, 150, 138, 72, "body", "resonance")}${arrow(561, 222, 561, 282)}${card(448, 296, 226, 74, "air pressure wave", "physical energy")}`;
  const right = `${card(76, 398, 138, 72, "rela code", "voice Lead")}${arrow(214, 434, 284, 434)}${card(284, 398, 138, 72, "oscillator", "math wave")}${arrow(422, 434, 492, 434)}${card(492, 398, 138, 72, "env/filter", "shape tone")}${arrow(630, 434, 700, 434)}${card(700, 398, 150, 72, "speaker", "air wave")}`;
  return svg("Acoustic vs synthesizer", "Both end as air pressure; the source of the waveform is different.", `${text(76, 132, "Acoustic instrument", "label")}${left}${text(76, 382, "Synthesizer", "label")}${right}${text(704, 190, "sound color comes from the object", "small")}${text(704, 439, "sound color comes from a signal graph", "small")}`);
}

function soundWave() {
  const d = wave("sine", 118, 170, 650, 180, "hot");
  return svg("Sound wave", "Pitch is period; loudness is amplitude.", `${line(108, 260, 810, 260)}${line(118, 142, 118, 380)}${d}${line(118, 170, 118, 260, "axis")}${line(790, 260, 790, 350, "axis")}${text(112, 132, "amplitude", "small")}${text(430, 394, "one period = one cycle", "small mid")}${line(198, 360, 358, 360, "arrow")}${text(640, 142, "higher frequency = shorter period", "small")}${text(640, 166, "higher amplitude = louder", "small")}`);
}

function waveforms() {
  const kinds = [["Sine", "sine", [1, 0, 0, 0, 0], "only fundamental"], ["Triangle", "triangle", [1, 0, .18, 0, .06], "soft odd harmonics"], ["Saw", "saw", [1, .6, .42, .32, .25], "all harmonics"], ["Square", "square", [1, 0, .34, 0, .2], "odd harmonics"]];
  return svg("Waveforms", "The visible shape predicts the harmonic recipe.", kinds.map(([name, kind, bars, note], i) => {
    const x = 60 + i * 225;
    return `${rect(x, 140, 190, 278)}${text(x + 95, 171, name, "label mid")}${wave(kind, x + 24, 190, 142, 62, i % 2 ? "mint" : "hot")}${spectrum(x + 50, 286, bars, i % 2 ? "mintf" : "hotf")}${text(x + 95, 390, note, "small mid")}`;
  }).join("") + text(72, 462, "Read left-to-right: waveform shape above, relative harmonic strength below.", "small"));
}

function adsr() {
  const d = "M 108 398 L 210 158 L 340 250 L 630 250 L 778 398";
  return svg("ADSR envelope", "A note is not just pitch; it is a time shape.", `${rect(84, 132, 760, 306)}${line(108, 398, 808, 398)}${line(108, 142, 108, 398)}${pathEl(d, "line hot")}${line(210, 158, 210, 398, "axis fade")}${line(340, 250, 340, 398, "axis fade")}${line(630, 250, 630, 398, "axis fade")}${text(159, 420, "attack", "small mid")}${text(275, 420, "decay", "small mid")}${text(485, 420, "sustain level", "small mid")}${text(704, 420, "release", "small mid")}${text(128, 155, "peak", "small")}${text(650, 253, "key held", "small")}`);
}

function adsrVariations() {
  const plots = [["Pluck", "M 86 300 L 108 176 L 205 300"], ["Piano", "M 296 300 L 314 166 L 382 228 L 492 300"], ["Pad", "M 506 300 C 560 178 610 176 654 212 L 710 212 C 748 212 764 252 788 300"], ["Organ", "M 716 300 L 732 176 L 860 176 L 880 300"]];
  return svg("Envelope families", "Different instruments are mostly different amplitude stories.", plots.map(([t, d], i) => miniPlot(58 + i * 222, 142, 190, 214, t, d, i % 2 ? "mint" : "hot")).join("") + text(70, 424, "Fast attack and no sustain reads as a pluck; slow attack and long release reads as a pad.", "small"));
}

function pitchEnvelope() {
  return svg("Pitch envelope", "Percussion often starts high and falls fast.", `${rect(94, 140, 720, 300)}${line(138, 382, 760, 382)}${line(138, 174, 138, 382)}${pathEl("M 138 190 C 180 220 222 295 260 336 C 330 378 520 382 760 382", "line hot")}${pathEl("M 138 382 C 154 278 182 268 214 352 C 246 397 330 405 760 407", "line mint")}${text(106, 170, "frequency", "small")}${text(720, 404, "time", "small")}${text(184, 202, "click / punch", "small")}${text(328, 354, "settles to body pitch", "small")}${text(166, 420, "mint curve = amplitude, rose curve = pitch", "small")}`);
}

function filters() {
  const curve = (x, y, i) => [
    `M ${x + 34} ${y + 98} L ${x + 130} ${y + 98} C ${x + 184} ${y + 98} ${x + 176} ${y + 28} ${x + 296} ${y + 28}`,
    `M ${x + 34} ${y + 98} C ${x + 154} ${y + 98} ${x + 146} ${y + 28} ${x + 200} ${y + 28} L ${x + 330} ${y + 28}`,
    `M ${x + 34} ${y + 98} C ${x + 122} ${y + 98} ${x + 132} ${y + 28} ${x + 194} ${y + 28} C ${x + 256} ${y + 28} ${x + 266} ${y + 98} ${x + 340} ${y + 98}`,
    `M ${x + 34} ${y + 28} L ${x + 132} ${y + 28} C ${x + 180} ${y + 28} ${x + 170} ${y + 98} ${x + 198} ${y + 98} C ${x + 226} ${y + 98} ${x + 218} ${y + 28} ${x + 330} ${y + 28}`,
  ][i];
  const panels = ["Low-pass", "High-pass", "Band-pass", "Notch"];
  return svg("Filter types", "Filters decide which part of the spectrum survives.", panels.map((t, i) => {
    const x = 60 + (i % 2) * 450, y = 130 + Math.floor(i / 2) * 180;
    return `${rect(x, y, 388, 138)}${line(x + 28, y + 106, x + 340, y + 106)}${line(x + 28, y + 26, x + 28, y + 106)}${pathEl(curve(x, y, i), i % 2 ? "line mint" : "line hot")}${line(x + 190, y + 30, x + 190, y + 112, "axis fade")}${text(x + 194, y + 128, "cutoff", "small mid")}${text(x + 194, y + 24, t, "label mid")}`;
  }).join(""));
}

function filterResonance() {
  return svg("Filter resonance", "Q boosts the edge of the filter.", `${rect(90, 136, 740, 300)}${line(130, 382, 780, 382)}${line(130, 172, 130, 382)}${pathEl("M 130 242 L 445 242 C 520 242 528 330 610 330 L 780 330", "line mint")}${pathEl("M 130 262 L 450 262 C 494 180 530 348 610 348 L 780 348", "line gold")}${pathEl("M 130 282 L 450 282 C 500 114 522 364 610 364 L 780 364", "line hot")}${line(505, 160, 505, 386, "axis fade")}${text(505, 408, "cutoff", "small mid")}${text(610, 214, "higher resonance = sharper peak", "small")}${text(610, 238, "use carefully for acid / vowel tones", "small")}`);
}

function cutoffComparison() {
  const bars = spectrum(150, 194, [1, .9, .76, .62, .5, .38, .3, .22], "violetf");
  const low = spectrum(460, 208, [1, .82, .2, .08, .02, .01, .01, .01], "mintf");
  const high = spectrum(690, 194, [1, .9, .75, .55, .32, .18, .08, .04], "hotf");
  return svg("Cutoff and brightness", "Lower cutoff removes more upper harmonics, so the tone gets darker.", `${card(118, 146, 190, 168, "source spectrum", "bright saw")}${bars}${arrow(316, 230, 408, 230)}${card(418, 146, 170, 168, "low cutoff", "warm / muted")}${low}${arrow(596, 230, 658, 230)}${card(668, 146, 170, 168, "high cutoff", "open / bright")}${high}${text(120, 404, "Read the bars as harmonic energy. The filter is a moving boundary across the same source.", "small")}`);
}

function lfoModulation() {
  return svg("LFO modulation", "A slow oscillator moves another parameter.", `${rect(78, 132, 320, 260)}${text(238, 166, "LFO: sub-audio wave", "label mid")}${wave("sine", 122, 204, 230, 80, "mint")}${text(238, 326, "rate = speed, depth = range", "small mid")}${arrow(398, 260, 520, 260)}${rect(520, 132, 340, 260)}${text(690, 166, "Pitch being modulated", "label mid")}${pathEl("M 566 262 C 596 222 626 222 656 262 C 686 302 716 302 746 262 C 776 222 806 222 836 262", "line hot")}${line(560, 262, 842, 262, "axis fade")}${text(690, 326, "vibrato: pitch wiggles around the target note", "small mid")}`);
}

function chain() {
  const xs = [72, 236, 400, 564, 728], names = [["oscillator", "raw harmonics"], ["envelope", "time shape"], ["filter", "tone focus"], ["effects", "space / motion"], ["output", "speaker / file"]];
  return svg("Subtractive synthesis chain", "Start rich, then shape time and spectrum.", xs.map((x, i) => card(x, 180, 126, 104, names[i][0], names[i][1], i % 2 ? "soft" : "panel")).join("") + xs.slice(0, -1).map((x) => arrow(x + 126, 232, x + 162, 232)).join("") + text(86, 372, "Relanote presets mostly differ by oscillator recipe, ADSR envelope, filter cutoff and effect choices.", "small"));
}

function mixing() {
  const osc = [[94, "Saw", "mix 0.5"], [94, "Square", "mix 0.3"], [94, "Sine", "mix 0.2"]];
  return svg("Multiple oscillator mixing", "Layer partial sounds before the shared envelope/filter.", `${osc.map(([x, t, s], i) => `${card(x, 142 + i * 96, 150, 70, t, s)}${arrow(244, 177 + i * 96, 402, 270)}`).join("")}${card(402, 226, 150, 88, "mixer", "sum levels", "soft")}${arrow(552, 270, 658, 270)}${card(658, 184, 198, 172, "combined voice", "one playable sound")}${spectrum(704, 240, [.9, .55, .42, .25, .16], "hotf")}${text(92, 448, "The + operator combines oscillator recipes; ADSR and filter then shape the combined voice.", "small")}`);
}

function signalFlow() {
  return svg("Synthesizer signal flow", "Each note becomes a temporary voice; voices meet at the master output.", `${card(72, 148, 150, 82, "events_json", "pitch, beat, voice")}${arrow(222, 189, 306, 189)}${card(306, 118, 160, 72, "voice A", "osc + ADSR")}${card(306, 214, 160, 72, "voice B", "osc + ADSR")}${arrow(466, 154, 568, 236)}${arrow(466, 250, 568, 236)}${card(568, 190, 150, 92, "master mix", "gain + pan", "soft")}${arrow(718, 236, 812, 236)}${card(812, 194, 94, 84, "audio", "browser")}${text(80, 366, "Changing code changes the same event list that drives the preview, so rhythm, layers and synth voice must agree.", "small")}`);
}

function keyboard() {
  const whites = ["C", "D", "E", "F", "G", "A", "B", "C", "D", "E", "F", "G", "A", "B"], blackAt = [0, 1, 3, 4, 5, 7, 8, 10, 11, 12], bw = 52;
  const keys = whites.map((n, i) => `${rect(90 + i * bw, 220, bw, 150, i === 0 || i === 7 ? "fillMint" : "panel", 6)}${text(116 + i * bw, 348, n, "small mid")}`).join("") + blackAt.map((i) => `${rect(126 + i * bw, 220, 34, 94, "darkf", 5)}`).join("");
  return svg("Piano keyboard", "A piano makes the twelve semitone positions visible.", `${keys}${line(90, 392, 454, 392, "arrow")}${text(272, 414, "12 semitones = one octave", "small mid")}${line(90, 184, 454, 184, "arrow")}${text(272, 174, "C4 261.63 Hz", "small mid")}${line(454, 184, 818, 184, "arrow")}${text(636, 174, "C5 523.25 Hz = 2x frequency", "small mid")}`);
}

function intervals() {
  const labs = ["R", "m2", "M2", "m3", "M3", "P4", "A4/d5", "P5", "m6", "M6", "m7", "M7", "P8"];
  return svg("Intervals chart", "Relanote names distance from the current root.", labs.map((l, i) => {
    const x = 66 + i * 66;
    return `${rect(x, 210, 54, 88, i === 0 || i === 12 ? "fillMint" : i === 7 ? "fillHot" : "panel", 8)}${text(x + 27, 245, l, "label mid")}${text(x + 27, 276, `${i} st`, "small mid")}`;
  }).join("") + `${line(92, 350, 884, 350, "arrow")}${text(492, 378, "transpose changes the root, not these interval names", "small mid")}${text(72, 444, "Example: <3> means the third scale degree; M3 means exactly four semitones above root.", "small")}`);
}

function majorMinor() {
  const steps = Array.from({ length: 13 }, (_, i) => 90 + i * 62);
  const major = [0, 2, 4, 5, 7, 9, 11, 12], minor = [0, 2, 3, 5, 7, 8, 10, 12];
  const row = (y, set, name) => `${text(58, y + 6, name, "label")}${steps.map((x, i) => `${line(x, y - 36, x, y + 36, "axis fade")}${text(x, y + 54, `${i}`, "small mid")}${set.includes(i) ? circle(x, y, i === 3 || i === 4 || i === 8 || i === 9 || i === 10 || i === 11 ? 15 : 12, i === 3 || i === 8 || i === 10 ? "hotf" : "mintf") : ""}`).join("")}`;
  return svg("Major vs minor", "The third, sixth and seventh degrees carry the emotional change.", `${line(90, 230, 834, 230)}${row(190, major, "Major")}${row(310, minor, "Minor")}${text(396, 410, "Major has M3 / M6 / M7; natural minor lowers them to m3 / m6 / m7.", "small mid")}`);
}

function circleFifths() {
  const keys = ["C", "G", "D", "A", "E", "B", "F#/Gb", "Db", "Ab", "Eb", "Bb", "F"];
  const nodes = keys.map((k, i) => {
    const a = -Math.PI / 2 + i * Math.PI * 2 / 12, x = 480 + Math.cos(a) * 170, y = 286 + Math.sin(a) * 170;
    return `${circle(x, y, 28, i < 6 ? "mintf" : "hotf")}${text(x, y + 5, k, "small mid lightf")}`;
  }).join("");
  return svg("Circle of fifths", "Neighboring keys differ by one sharp or one flat.", `${circle(480, 286, 170, "fillViolet")}${nodes}${text(480, 282, "clockwise", "label mid")}${text(480, 306, "+ one sharp", "small mid")}${text(480, 470, "counter-clockwise adds flats; opposite keys are a tritone apart.", "small mid")}${arrow(580, 126, 630, 168)}${arrow(380, 446, 330, 404)}`);
}

function detuning() {
  return svg("Detuning", "Tiny frequency offsets create slow beating and width.", `${rect(86, 142, 770, 292)}${wave("sine", 120, 190, 330, 70, "mint")}${wave("sine", 120, 214, 330, 70, "hot")}${arrow(470, 232, 560, 232)}${pathEl("M 570 236 C 610 164 660 164 700 236 C 740 308 790 308 830 236", "line violet")}${pathEl("M 570 236 C 610 308 660 308 700 236 C 740 164 790 164 830 236", "line violet fade")}${text(190, 172, "osc A: -7 cents", "small")}${text(190, 312, "osc B: +7 cents", "small")}${text(682, 350, "combined amplitude breathes", "small mid")}`);
}

function write(name, content) { fs.writeFileSync(path.join(outDir, name), content); }

const diagrams = {
  "architecture-overview.svg": architecture(),
  "synth-vs-acoustic.svg": synthVsAcoustic(),
  "sound-wave.svg": soundWave(),
  "waveforms.svg": waveforms(),
  "adsr-envelope.svg": adsr(),
  "adsr-variations.svg": adsrVariations(),
  "pitch-envelope.svg": pitchEnvelope(),
  "filter-types.svg": filters(),
  "filter-resonance.svg": filterResonance(),
  "filter-cutoff-comparison.svg": cutoffComparison(),
  "lfo-modulation.svg": lfoModulation(),
  "synthesis-chain.svg": chain(),
  "multi-osc-mixing.svg": mixing(),
  "synthesis-signal-flow.svg": signalFlow(),
  "piano-keyboard.svg": keyboard(),
  "intervals-chart.svg": intervals(),
  "major-minor-scales.svg": majorMinor(),
  "circle-of-fifths.svg": circleFifths(),
  "detuning.svg": detuning(),
};

fs.mkdirSync(outDir, { recursive: true });
for (const [name, content] of Object.entries(diagrams)) write(name, content);
