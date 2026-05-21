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
    subGain: .16,
    noise: 0,
    detune: 0,
    pan: (lane % 3 - 1) * .22,
  };
  if (v.includes("bass") || v.includes("acid") || v.includes("moog")) {
    return { ...patch, osc: "sawtooth", cutoff: 760, q: 12, gain: .17, subGain: .42, attack: .006, release: .14, detune: -4, pan: patch.pan * .22 };
  }
  if (v.includes("pad") || v.includes("bloom") || v.includes("glass") || v.includes("drift")) {
    return { ...patch, osc: "sawtooth", sub: "triangle", cutoff: 2300, q: 3, gain: .082, subGain: .08, attack: .24, release: .58, detune: 8 };
  }
  if (v.includes("fm") || v.includes("bell") || v.includes("rhodes") || v.includes("kalimba")) {
    return { ...patch, osc: "sine", sub: "triangle", cutoff: 9800, q: 2, gain: .105, subGain: .04, attack: .003, release: .36, detune: 12 };
  }
  if (v.includes("wave")) {
    return { ...patch, osc: "sawtooth", sub: "square", filter: "bandpass", cutoff: 3600, q: 8, gain: .11, subGain: .06, attack: .025, release: .2, detune: 10 };
  }
  if (v.includes("grain")) {
    return { ...patch, osc: "triangle", sub: "sawtooth", filter: "bandpass", cutoff: 2100, q: 10, gain: .095, subGain: .05, attack: .06, release: .32, detune: lane % 2 ? 17 : -11, noise: .05 };
  }
  if (v.includes("chip") || v.includes("nes") || v.includes("gameboy")) {
    return { ...patch, osc: "square", sub: "square", cutoff: 7000, q: 1, gain: .09, subGain: 0, attack: .002, release: .025 };
  }
  if (v.includes("kick") || v.includes("snare") || v.includes("hat")) {
    return { ...patch, osc: v.includes("kick") ? "sine" : "square", sub: "triangle", filter: v.includes("kick") ? "lowpass" : "highpass", cutoff: v.includes("hat") ? 6800 : v.includes("snare") ? 1600 : 140, q: 7, gain: v.includes("hat") ? .045 : .12, subGain: v.includes("kick") ? .5 : 0, attack: .001, release: v.includes("hat") ? .035 : .08, noise: v.includes("kick") ? .03 : .22, pan: v.includes("kick") ? 0 : patch.pan };
  }
  return patch;
}

function registerGain(freq, voice) {
  let gain = 1;
  if (freq < 55) gain *= .62;
  else if (freq < 120) gain *= .82;
  else if (freq > 2600) gain *= .38;
  else if (freq > 1200) gain *= .58;
  const v = (voice || "").toLowerCase();
  if (v.includes("pad") || v.includes("bloom") || v.includes("glass")) gain *= .72;
  if (v.includes("hat") || v.includes("bell") || v.includes("kalimba")) gain *= .55;
  return gain;
}

function noiseBurst(ctx, dest, t0, t1, amount) {
  if (!amount) return;
  const n = Math.max(1, Math.ceil((t1 - t0) * ctx.sampleRate));
  const buffer = ctx.createBuffer(1, n, ctx.sampleRate);
  const data = buffer.getChannelData(0);
  for (let i = 0; i < n; i++) data[i] = (Math.random() * 2 - 1) * (1 - i / n);
  const src = ctx.createBufferSource();
  const gain = ctx.createGain();
  src.buffer = buffer;
  gain.gain.value = amount;
  src.connect(gain); gain.connect(dest);
  src.start(t0); src.stop(t1);
}

function schedule(ctx, note, base, bps, lane, master) {
  const patch = patchFor(note.voice, lane);
  const freq = 440 * Math.pow(2, (note.pitch - 69) / 12);
  const t0 = base + note.start / bps;
  const t1 = t0 + note.duration / bps;
  const osc = ctx.createOscillator();
  const sub = ctx.createOscillator();
  const oscGain = ctx.createGain();
  const subGain = ctx.createGain();
  const filter = ctx.createBiquadFilter();
  const gain = ctx.createGain();
  const pan = ctx.createStereoPanner ? ctx.createStereoPanner() : null;
  osc.type = patch.osc;
  sub.type = patch.sub;
  osc.frequency.value = freq;
  sub.frequency.value = freq / 2;
  osc.detune.value = patch.detune;
  filter.type = patch.filter;
  filter.frequency.setValueAtTime(Math.max(50, Math.min(16000, patch.cutoff + Math.log2(freq / 220) * 420)), t0);
  filter.Q.value = patch.q;
  oscGain.gain.value = .86;
  subGain.gain.value = freq < 900 ? patch.subGain : 0;
  gain.gain.setValueAtTime(.0001, t0);
  gain.gain.exponentialRampToValueAtTime(patch.gain * registerGain(freq, note.voice), t0 + patch.attack);
  gain.gain.exponentialRampToValueAtTime(.0001, t1 + patch.release);
  if (pan) pan.pan.value = freq < 140 ? patch.pan * .18 : patch.pan;
  noiseBurst(ctx, filter, t0, t1 + patch.release, patch.noise);
  osc.connect(oscGain); sub.connect(subGain);
  oscGain.connect(filter); subGain.connect(filter); filter.connect(gain);
  gain.connect(pan || master); if (pan) pan.connect(master);
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
  const master = ctx.createGain();
  const low = ctx.createBiquadFilter();
  const high = ctx.createBiquadFilter();
  const delay = ctx.createDelay(.8);
  const wet = ctx.createGain();
  const fb = ctx.createGain();
  const comp = ctx.createDynamicsCompressor();
  master.gain.value = .86;
  low.type = "lowshelf"; low.frequency.value = 85; low.gain.value = -1.3;
  high.type = "highshelf"; high.frequency.value = 5200; high.gain.value = -1.8;
  delay.delayTime.value = .28; wet.gain.value = .16; fb.gain.value = .2;
  comp.threshold.value = -18; comp.knee.value = 18; comp.ratio.value = 3.2;
  master.connect(low); low.connect(high); high.connect(comp);
  master.connect(delay); delay.connect(fb); fb.connect(delay); delay.connect(wet); wet.connect(comp);
  comp.connect(ctx.destination);
  const bps = await tempo(source) / 60;
  notes.forEach((note, i) => schedule(ctx, note, ctx.currentTime + .04, bps, i, master));
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
