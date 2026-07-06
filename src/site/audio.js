let previewAudio;
let previewTimer;
let previewSession = 0;

function clearPreviewTimer() {
  if (previewTimer) clearTimeout(previewTimer);
  previewTimer = null;
}

function closePreviewContext(ctx) {
  if (!ctx) return;
  try {
    if (ctx.state !== "closed") ctx.close().catch(() => {});
  } catch {}
}

function beginPreview() {
  previewSession += 1;
  clearPreviewTimer();
  const ctx = previewAudio;
  previewAudio = null;
  closePreviewContext(ctx);
  return previewSession;
}

function finishPreview(session) {
  if (session !== previewSession) return;
  clearPreviewTimer();
  const ctx = previewAudio;
  previewAudio = null;
  closePreviewContext(ctx);
}

function stopPreview() {
  beginPreview();
}

function patchFor(voice, lane) {
  const v = (voice || "").toLowerCase();
  const base = {
    wave: "velvet", filter: "lowpass", cutoff: 5200, q: 3, gain: .105,
    attack: .018, release: .14, subGain: .08, bodyGain: .08, pan: (lane % 9 - 4) * .18,
    room: .34, width: .3, drive: .05, fm: 0, fmRatio: 2.01, click: 0, kind: "tone",
  };
  if (v.includes("kick")) return { ...base, kind: "kick", gain: .22, room: .035, width: 0, pan: 0, click: .14 };
  if (v.includes("snare")) return { ...base, kind: "snare", gain: .11, room: .42, width: .42, click: .34 };
  if (v.includes("hat")) return { ...base, kind: "hat", gain: .04, room: .32, width: .68, click: .24 };
  if (v.includes("sub")) return { ...base, wave: "silk", cutoff: 300, q: 9, gain: .17, subGain: .76, bodyGain: .04, attack: .008, release: .24, pan: 0, room: .025, width: 0, drive: .09 };
  if (v.includes("acid")) return { ...base, wave: "reed", cutoff: 1150, q: 15, gain: .115, subGain: .38, bodyGain: .11, attack: .006, release: .22, room: .12, width: .12, drive: .18, fm: .025, sweep: 2.6 };
  if (v.includes("bass") || v.includes("moog")) return { ...base, wave: "bloom", cutoff: 720, q: 10, gain: .13, subGain: .46, bodyGain: .12, attack: .008, release: .24, pan: base.pan * .12, room: .08, width: .08, drive: .14 };
  if (v.includes("rhodes")) return { ...base, wave: "glass", cutoff: 7600, q: 2, gain: .075, attack: .006, release: .78, room: .44, width: .62, drive: .04, fm: .33, fmRatio: 2.98, click: .014 };
  if (v.includes("bell") || v.includes("kalimba")) return { ...base, wave: "glass", cutoff: 10400, q: 2, gain: .064, attack: .003, release: .72, room: .54, width: .76, drive: .025, fm: .58, fmRatio: 3.97, click: .025 };
  if (v.includes("pad") || v.includes("bloom") || v.includes("glass") || v.includes("drift")) return { ...base, wave: "bloom", cutoff: 2300, q: 2.4, gain: .062, attack: .34, release: 1.28, subGain: .045, bodyGain: .1, room: .78, width: .98, drive: .035, fm: .018, fmRatio: 1.5 };
  if (v.includes("wave") || v.includes("supersaw") || v.includes("formant")) return { ...base, wave: v.includes("formant") ? "reed" : "fold", filter: "bandpass", cutoff: 3600, q: 7, gain: .076, attack: .02, release: .4, subGain: .04, bodyGain: .08, room: .62, width: .94, pan: base.pan * 1.2, drive: .09, fm: .035, fmRatio: 1.99, sweep: 1.35 };
  if (v.includes("grain") || v.includes("vocal") || v.includes("shimmer") || v.includes("far")) return { ...base, wave: "glass", filter: "bandpass", cutoff: 2600, q: 9, gain: .058, attack: .075, release: .86, subGain: .02, bodyGain: .06, room: .9, width: 1, pan: base.pan * 1.35, drive: .03, fm: .08, fmRatio: 2.52, click: .03 };
  if (v.includes("modular") || v.includes("lead")) return { ...base, wave: "reed", filter: "bandpass", cutoff: 4200, q: 8, gain: .08, attack: .015, release: .32, room: .5, width: .78, pan: base.pan * 1.1, drive: .1, fm: .055, fmRatio: 2.01 };
  if (v.includes("chip") || v.includes("nes") || v.includes("gameboy")) return { ...base, wave: "fold", cutoff: 5300, q: 4, gain: .052, attack: .004, release: .08, room: .2, width: .42, drive: .045, fm: .03 };
  return base;
}

function registerGain(freq, voice) {
  let gain = 1;
  if (freq < 38) gain *= .5;
  else if (freq < 60) gain *= .8;
  else if (freq < 120) gain *= .94;
  else if (freq > 5600) gain *= .2;
  else if (freq > 3000) gain *= .33;
  else if (freq > 1500) gain *= .52;
  const v = (voice || "").toLowerCase();
  if (v.includes("pad") || v.includes("bloom") || v.includes("glass") || v.includes("drift")) gain *= .7;
  if (v.includes("hat") || v.includes("bell") || v.includes("kalimba") || v.includes("shimmer")) gain *= .46;
  if ((v.includes("sub") || v.includes("bass")) && freq > 240) gain *= .52;
  return gain;
}

function mixer(ctx) {
  const n = window.RelanoteNodes;
  const dry = ctx.createGain();
  const room = ctx.createGain();
  const pre = ctx.createBiquadFilter();
  const verb = ctx.createConvolver();
  const delay = ctx.createDelay(1.4);
  const fb = ctx.createGain();
  const wet = ctx.createGain();
  const glue = n.drive(ctx, .045);
  const low = ctx.createBiquadFilter();
  const mud = ctx.createBiquadFilter();
  const air = ctx.createBiquadFilter();
  const comp = ctx.createDynamicsCompressor();
  dry.gain.value = .78; room.gain.value = .9; wet.gain.value = .3;
  pre.type = "highpass"; pre.frequency.value = 165;
  verb.buffer = n.impulse(ctx, 3.2);
  delay.delayTime.value = .37; fb.gain.value = .22;
  low.type = "lowshelf"; low.frequency.value = 58; low.gain.value = 1.4;
  mud.type = "peaking"; mud.frequency.value = 285; mud.Q.value = .85; mud.gain.value = -2.7;
  air.type = "highshelf"; air.frequency.value = 7800; air.gain.value = -1;
  comp.threshold.value = -20; comp.knee.value = 26; comp.ratio.value = 3.4; comp.attack.value = .005; comp.release.value = .22;
  dry.connect(low); low.connect(mud); mud.connect(air); air.connect(glue); glue.connect(comp);
  room.connect(pre); pre.connect(verb); verb.connect(wet); wet.connect(comp);
  room.connect(delay); delay.connect(fb); fb.connect(delay); delay.connect(wet);
  comp.connect(ctx.destination);
  return { dry, room };
}

function percussion(ctx, note, base, bps, lane, bus, patch) {
  const n = window.RelanoteNodes;
  const freq = 440 * Math.pow(2, (note.pitch - 69) / 12);
  const t0 = base + note.start / bps;
  const t1 = t0 + Math.min(note.duration / bps, patch.kind === "hat" ? .08 : .22);
  const amp = ctx.createGain();
  const filter = ctx.createBiquadFilter();
  const sat = n.drive(ctx, patch.kind === "kick" ? .12 : .07);
  amp.gain.setValueAtTime(.0001, t0);
  amp.gain.exponentialRampToValueAtTime(patch.gain * registerGain(freq, note.voice), t0 + .004);
  amp.gain.exponentialRampToValueAtTime(.0001, t1 + .08);
  filter.type = patch.kind === "kick" ? "lowpass" : "bandpass";
  filter.frequency.setValueAtTime(patch.kind === "kick" ? 150 : patch.kind === "snare" ? 1900 : 8500, t0);
  filter.Q.value = patch.kind === "hat" ? 1.3 : 5.2;
  filter.connect(sat); sat.connect(amp); n.connectSpace(ctx, amp, bus, patch, freq);
  if (patch.kind !== "hat") {
    const body = ctx.createOscillator();
    body.type = patch.kind === "kick" ? "sine" : "triangle";
    body.frequency.setValueAtTime(patch.kind === "kick" ? freq * 3.1 : freq * 1.55, t0);
    body.frequency.exponentialRampToValueAtTime(patch.kind === "kick" ? Math.max(36, freq * .62) : freq * 1.08, t0 + .07);
    body.connect(filter); n.startStop([body], t0, t1 + .1);
  }
  const noiseCut = patch.kind === "hat" ? 9200 : patch.kind === "snare" ? 2400 : 3600;
  n.noiseBurst(ctx, filter, t0, t1 + .04, patch.click, patch.kind === "hat" ? "highpass" : "bandpass", noiseCut);
}

function tune(osc, freq, patch, t0, v, detune) {
  osc.setPeriodicWave(window.RelanoteNodes.wave(osc.context, patch.wave));
  osc.frequency.setValueAtTime(freq, t0);
  osc.detune.value = detune;
  if (v.includes("acid") || v.includes("formant")) osc.frequency.linearRampToValueAtTime(freq * 1.012, t0 + .09);
}

function schedule(ctx, note, base, bps, lane, bus) {
  const n = window.RelanoteNodes;
  const patch = patchFor(note.voice, lane);
  if (patch.kind !== "tone") return percussion(ctx, note, base, bps, lane, bus, patch);
  const v = (note.voice || "").toLowerCase();
  const freq = 440 * Math.pow(2, (note.pitch - 69) / 12);
  const t0 = base + note.start / bps;
  const t1 = t0 + note.duration / bps;
  const osc = ctx.createOscillator();
  const det = ctx.createOscillator();
  const body = ctx.createOscillator();
  const og = ctx.createGain();
  const dg = ctx.createGain();
  const bg = ctx.createGain();
  const filter = ctx.createBiquadFilter();
  const sat = n.drive(ctx, patch.drive);
  const amp = ctx.createGain();
  tune(osc, freq, patch, t0, v, patch.pan > 0 ? 5 : -5);
  tune(det, freq, patch, t0, v, patch.pan > 0 ? -13 : 13);
  body.type = "sine"; body.frequency.setValueAtTime(freq * (v.includes("bell") ? 2 : .5), t0);
  filter.type = patch.filter;
  const cut = Math.max(55, Math.min(15000, patch.cutoff + Math.log2(freq / 220) * 360));
  filter.frequency.setValueAtTime(cut, t0);
  if (patch.sweep) filter.frequency.exponentialRampToValueAtTime(Math.min(15000, cut * patch.sweep), t0 + .11);
  filter.Q.value = patch.q;
  og.gain.value = .72; dg.gain.value = patch.width * .2; bg.gain.value = freq < 1200 ? patch.bodyGain : patch.bodyGain * .22;
  amp.gain.setValueAtTime(.0001, t0);
  amp.gain.exponentialRampToValueAtTime(patch.gain * registerGain(freq, note.voice), t0 + patch.attack);
  amp.gain.exponentialRampToValueAtTime(.0001, t1 + patch.release);
  n.noiseBurst(ctx, filter, t0, t0 + .025, patch.click, "bandpass", Math.min(9000, cut * 1.5));
  osc.connect(og); det.connect(dg); body.connect(bg);
  og.connect(filter); dg.connect(filter); bg.connect(filter); filter.connect(sat); sat.connect(amp);
  n.connectSpace(ctx, amp, bus, patch, freq);
  const mods = [...n.addFm(ctx, osc, freq, t0, t1, patch), ...n.addFm(ctx, det, freq, t0, t1, { ...patch, fm: patch.fm * .55 })];
  n.startStop([osc, det, body, ...mods], t0, t1 + patch.release + .08);
}

async function playSource(source, eventReader, tempoReader) {
  const session = beginPreview();
  const Audio = window.AudioContext || window.webkitAudioContext;
  if (!Audio || !window.RelanoteNodes) return;
  const [notes, tempo] = await Promise.all([
    eventReader(source).catch(() => []),
    tempoReader(source).catch(() => 120),
  ]);
  if (session !== previewSession) return;
  const playable = Array.isArray(notes) ? notes : [];
  if (!playable.length) return;
  let ctx;
  try {
    ctx = new Audio();
  } catch {
    return;
  }
  if (session !== previewSession) {
    closePreviewContext(ctx);
    return;
  }
  previewAudio = ctx;
  try {
    await ctx.resume();
    if (session !== previewSession) {
      closePreviewContext(ctx);
      return;
    }
    const bus = mixer(ctx);
    const bpm = Number.isFinite(tempo) && tempo > 0 ? tempo : 120;
    const bps = bpm / 60;
    const base = ctx.currentTime + .06;
    playable.forEach((note, i) => schedule(ctx, note, base, bps, i, bus));
    const end = Math.max(0, ...playable.map((note) => note.start + note.duration));
    previewTimer = setTimeout(() => finishPreview(session), end / bps * 1000 + 1700);
  } catch {
    finishPreview(session);
  }
}

window.RelanoteAudio = { playSource, stopPreview };
