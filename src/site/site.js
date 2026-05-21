let previewRuntime;
let previewAudio;

async function runtime() {
  if (!previewRuntime) {
    previewRuntime = fetch("/preview.wasm")
      .then((res) => res.arrayBuffer())
      .then((bytes) => WebAssembly.instantiate(bytes, {}, {
        builtins: ["js-string"],
        importedStringConstants: "_",
      }))
      .then(({ instance }) => instance.exports)
      .catch(() => null);
  }
  return previewRuntime;
}

function sourceOf(kit) {
  return kit?.querySelector("code")?.innerText ?? "";
}

async function events(source) {
  const wasm = await runtime();
  if (!wasm) return [];
  try { return JSON.parse(wasm.events_json(source)); } catch { return []; }
}

async function summary(source) {
  const wasm = await runtime();
  if (!wasm) return "preview runtime unavailable";
  return wasm.playground_summary(source);
}

async function tempo(source) {
  const wasm = await runtime();
  if (!wasm) return 120;
  const bpm = wasm.preview_tempo(source);
  return bpm > 0 ? bpm : 120;
}

function draw(preview, notes, text) {
  const kit = preview.closest(".code-kit");
  const empty = notes.length === 0;
  preview.hidden = empty;
  kit?.classList.toggle("no-preview", empty);
  if (empty) return;
  const end = Math.max(1, ...notes.map((note) => note.start + note.duration));
  preview.querySelector(".preview-roll").innerHTML = notes.map((note) => {
    const x = 7 + note.start / end * 78;
    const y = 82 - (note.pitch - 54) * 2.35;
    const w = Math.max(8, note.duration / end * 72);
    return `<i style="--x:${x}%;--y:${Math.max(8, Math.min(84, y))}%;--w:${w}%"></i>`;
  }).join("");
  preview.querySelector("span").textContent = text;
}

async function renderPreview(kit) {
  const preview = kit?.querySelector(".code-preview");
  if (!preview) return;
  const source = sourceOf(kit);
  draw(preview, await events(source), await summary(source));
}

function stopPreview() {
  if (previewAudio) previewAudio.close();
  previewAudio = null;
}

function patchFor(voice, lane) {
  const v = (voice || "").toLowerCase();
  const patch = {
    osc: lane % 2 ? "sawtooth" : "triangle",
    sub: "sine",
    filter: "lowpass",
    cutoff: 5200,
    q: 5,
    gain: .15,
    attack: .018,
    release: .06,
    detune: 0,
    pan: (lane % 3 - 1) * .22,
  };
  if (v.includes("bass") || v.includes("acid") || v.includes("moog")) {
    return { ...patch, osc: "sawtooth", cutoff: 820, q: 11, gain: .18, attack: .006, release: .12, detune: -4 };
  }
  if (v.includes("pad") || v.includes("bloom") || v.includes("glass") || v.includes("drift")) {
    return { ...patch, osc: "sawtooth", sub: "triangle", cutoff: 2400, q: 3, gain: .105, attack: .16, release: .42, detune: 7 };
  }
  if (v.includes("fm") || v.includes("bell") || v.includes("rhodes") || v.includes("kalimba")) {
    return { ...patch, osc: "sine", sub: "triangle", cutoff: 9400, q: 2, gain: .13, attack: .003, release: .32, detune: 12 };
  }
  if (v.includes("wave")) {
    return { ...patch, osc: "sawtooth", sub: "square", filter: "bandpass", cutoff: 3600, q: 8, attack: .025, release: .18, detune: 10 };
  }
  if (v.includes("grain")) {
    return { ...patch, osc: "triangle", sub: "sawtooth", filter: "bandpass", cutoff: 2100, q: 10, gain: .12, attack: .05, release: .28, detune: lane % 2 ? 17 : -11 };
  }
  if (v.includes("chip") || v.includes("nes") || v.includes("gameboy")) {
    return { ...patch, osc: "square", sub: "square", cutoff: 7200, q: 1, gain: .12, attack: .002, release: .025 };
  }
  if (v.includes("kick") || v.includes("snare") || v.includes("hat")) {
    return { ...patch, osc: "square", sub: "triangle", filter: "highpass", cutoff: v.includes("hat") ? 5800 : 1200, q: 7, gain: .16, attack: .001, release: .045 };
  }
  return patch;
}

function schedule(ctx, note, base, bps, lane) {
  const patch = patchFor(note.voice, lane);
  const freq = 440 * Math.pow(2, (note.pitch - 69) / 12);
  const t0 = base + note.start / bps;
  const t1 = t0 + note.duration / bps;
  const osc = ctx.createOscillator();
  const sub = ctx.createOscillator();
  const filter = ctx.createBiquadFilter();
  const gain = ctx.createGain();
  const pan = ctx.createStereoPanner ? ctx.createStereoPanner() : null;
  osc.type = patch.osc;
  sub.type = patch.sub;
  osc.frequency.value = freq;
  sub.frequency.value = freq / 2;
  osc.detune.value = patch.detune;
  filter.type = patch.filter;
  filter.frequency.setValueAtTime(patch.cutoff + (note.pitch - 60) * 28, t0);
  filter.Q.value = patch.q;
  gain.gain.setValueAtTime(.0001, t0);
  gain.gain.exponentialRampToValueAtTime(patch.gain, t0 + patch.attack);
  gain.gain.exponentialRampToValueAtTime(.0001, t1 + patch.release);
  if (pan) pan.pan.value = patch.pan;
  osc.connect(filter); sub.connect(filter); filter.connect(gain);
  gain.connect(pan || ctx.destination); if (pan) pan.connect(ctx.destination);
  osc.start(t0); sub.start(t0); osc.stop(t1 + patch.release + .04); sub.stop(t1 + patch.release + .04);
}

async function playSource(source) {
  stopPreview();
  const Audio = window.AudioContext || window.webkitAudioContext;
  if (!Audio) return;
  const notes = await events(source);
  const ctx = new Audio();
  previewAudio = ctx;
  await ctx.resume();
  const bps = await tempo(source) / 60;
  notes.forEach((note, i) => schedule(ctx, note, ctx.currentTime + .04, bps, i));
  const end = Math.max(0, ...notes.map((note) => note.start + note.duration));
  setTimeout(stopPreview, end / bps * 1000 + 360);
}

function play(kit) {
  return playSource(sourceOf(kit));
}

function drawStudioRoll(frame, notes) {
  const roll = frame.querySelector("[data-studio-roll]");
  if (!roll) return;
  const end = Math.max(1, ...notes.map((note) => note.start + note.duration));
  roll.innerHTML = notes.map((note) => {
    const left = 7 + note.start / end * 78;
    const top = 80 - (note.pitch - 54) * 2.2;
    const width = Math.max(9, note.duration / end * 70);
    return `<i style="left:${left}%;top:${Math.max(10, Math.min(80, top))}%;width:${width}%"></i>`;
  }).join("");
}

async function renderStudio(frame) {
  const source = frame.querySelector(".studio-editor code")?.innerText ?? "";
  const notes = await events(source);
  frame.querySelector("[data-studio-summary]").textContent = await summary(source);
  frame.querySelector("[data-studio-diag]").textContent = notes.length ? "Clean: wasm preview rendered" : "No playable notes";
  drawStudioRoll(frame, notes);
}

document.querySelectorAll(".language-rela code").forEach((code) => {
  code.contentEditable = "true";
  code.spellcheck = false;
  renderPreview(code.closest(".code-kit"));
  code.addEventListener("input", () => renderPreview(code.closest(".code-kit")));
});

document.querySelectorAll(".studio-frame").forEach((frame) => {
  renderStudio(frame);
  frame.querySelector(".studio-editor code")?.addEventListener("input", () => renderStudio(frame));
});

document.addEventListener("click", async (event) => {
  const playButton = event.target.closest(".preview-play");
  if (playButton) return play(playButton.closest(".code-kit"));
  const studioPlay = event.target.closest(".studio-play");
  if (studioPlay) return playSource(studioPlay.closest(".studio-frame").querySelector(".studio-editor code")?.innerText ?? "");
  const button = event.target.closest(".code-copy");
  if (!button) return;
  const code = sourceOf(button.closest(".code-kit"));
  try {
    await navigator.clipboard.writeText(code);
    button.textContent = "Copied";
    setTimeout(() => { button.textContent = "Copy"; }, 1200);
  } catch {
    button.textContent = "Select";
  }
});
