let previewAudio;

function stopPreview() {
  if (previewAudio) previewAudio.close();
  previewAudio = null;
}

function patchFor(voice, lane) {
  const v = (voice || "").toLowerCase();
  const base = {
    wave: "velvet", filter: "lowpass", cutoff: 5200, q: 3, gain: .105,
    attack: .018, decay: .16, sustain: .72, release: .14,
    subGain: .08, bodyGain: .08, overtoneGain: 0, overtoneRatio: 2, overtoneWave: "silk",
    detailGain: 0, detailRatio: 3, detailWave: "silk", vibratoDepth: 0,
    pan: (lane % 9 - 4) * .18,
    room: .34, width: .3, drive: .05, fm: 0, fmRatio: 2.01, click: 0, breathGain: 0, kind: "tone",
  };
  if (v.includes("kick")) return { ...base, kind: "kick", gain: .24, room: .035, width: 0, pan: 0, click: .14 };
  if (v.includes("snare")) return { ...base, kind: "snare", gain: .11, room: .42, width: .42, click: .34 };
  if (v.includes("hat")) return { ...base, kind: "hat", gain: .082, room: .28, width: .72, click: .32 };
  if (v.includes("sub")) return { ...base, wave: "silk", cutoff: 300, q: 9, gain: .205, subGain: .82, bodyGain: .05, attack: .008, decay: .2, sustain: .86, release: .32, pan: 0, room: .025, width: 0, drive: .08 };
  if (v.includes("acid")) return { ...base, wave: "reed", cutoff: 1150, q: 15, gain: .105, subGain: .38, bodyGain: .1, attack: .01, decay: .14, sustain: .48, release: .26, room: .12, width: .12, drive: .15, fm: .018, sweep: 2.1 };
  if (v.includes("upright") || v.includes("woodbass")) return { ...base, wave: "wood", cutoff: 980, q: 5.8, gain: .13, subGain: .5, bodyGain: .16, overtoneGain: .045, overtoneRatio: 2, detailGain: .035, detailRatio: 3.02, detailWave: "wood", attack: .028, decay: .28, sustain: .72, release: .46, pan: base.pan * .08, room: .16, width: .12, drive: .06, click: .012 };
  if (v.includes("bass") || v.includes("moog")) return { ...base, wave: "bloom", cutoff: 720, q: 10, gain: .13, subGain: .46, bodyGain: .12, attack: .012, decay: .22, sustain: .68, release: .28, pan: base.pan * .12, room: .08, width: .08, drive: .13 };
  if (v.includes("epiano") || v.includes("electricpiano") || v.includes("tine") || v.includes("pickup") || v.includes("bark")) return { ...base, wave: "tine", cutoff: 6400, q: 2.6, gain: .072, subGain: .025, bodyGain: .11, overtoneGain: .095, overtoneRatio: 2.01, overtoneWave: "velvet", detailGain: .052, detailRatio: 3.01, detailWave: "tine", vibratoDepth: 3.5, vibratoRate: 5.7, vibratoDelay: .18, attack: .007, decay: .55, sustain: .34, release: 1.15, room: .5, width: .72, drive: .045, fm: .22, fmRatio: 2.98, click: .014, breathGain: .006 };
  if (v.includes("piano")) return { ...base, wave: "wood", cutoff: 6800, q: 2.1, gain: .068, subGain: .035, bodyGain: .13, overtoneGain: .07, overtoneRatio: 2, overtoneWave: "velvet", detailGain: .038, detailRatio: 3.96, detailWave: "glass", attack: .006, decay: .62, sustain: .26, release: 1.05, room: .42, width: .56, drive: .028, fm: .12, fmRatio: 2.01, click: .02 };
  if (v.includes("guitar")) return { ...base, wave: "wood", filter: "bandpass", cutoff: 3300, q: 4.2, gain: .064, subGain: .018, bodyGain: .08, overtoneGain: .09, overtoneRatio: 2, overtoneWave: "glass", detailGain: .04, detailRatio: 2.98, detailWave: "wood", attack: .005, decay: .34, sustain: .34, release: .62, room: .48, width: .66, drive: .04, fm: .018, fmRatio: 2.02, click: .026, breathGain: .01 };
  if (v.includes("sax")) return { ...base, wave: "brass", filter: "bandpass", cutoff: 1850, q: 4.8, gain: .074, subGain: .025, bodyGain: .12, overtoneGain: .08, overtoneRatio: 2, overtoneWave: "velvet", detailGain: .045, detailRatio: 3.03, detailWave: "reed", vibratoDepth: 12, vibratoRate: 5.4, vibratoDelay: .16, attack: .085, decay: .25, sustain: .86, release: .72, room: .46, width: .58, drive: .075, fm: .024, fmRatio: 1.01, breathGain: .035 };
  if (v.includes("rhodes")) return { ...base, wave: "glass", cutoff: 7200, q: 2, gain: .074, attack: .012, decay: .48, sustain: .38, release: .9, room: .44, width: .62, drive: .035, fm: .28, fmRatio: 2.98, click: .01, overtoneGain: .035, overtoneRatio: 2 };
  if (v.includes("bell") || v.includes("kalimba")) return { ...base, wave: "glass", cutoff: 9200, q: 1.6, gain: .058, attack: .006, decay: .72, sustain: .2, release: 1.15, room: .58, width: .78, drive: .02, fm: .42, fmRatio: 3.97, click: .015, overtoneGain: .045, overtoneRatio: 2.01 };
  if (v.includes("pad") || v.includes("bloom") || v.includes("glass") || v.includes("drift")) return { ...base, wave: "bloom", cutoff: 2450, q: 2.1, gain: .06, attack: .38, decay: .42, sustain: .82, release: 1.45, subGain: .045, bodyGain: .11, room: .78, width: .98, drive: .03, fm: .014, fmRatio: 1.5 };
  if (v.includes("vapor") || v.includes("supersaw")) return { ...base, wave: "bloom", filter: "lowpass", cutoff: 6200, q: 2.8, gain: .082, attack: .045, decay: .3, sustain: .76, release: .78, subGain: .035, bodyGain: .12, overtoneGain: .075, overtoneRatio: 2, overtoneWave: "glass", room: .64, width: .96, pan: base.pan * 1.05, drive: .055, fm: .036, fmRatio: 1.51, sweep: 1.12 };
  if (v.includes("wave") || v.includes("formant")) return { ...base, wave: v.includes("formant") ? "reed" : "fold", filter: "bandpass", cutoff: 3200, q: 5.2, gain: .07, attack: .038, decay: .28, sustain: .64, release: .7, subGain: .03, bodyGain: .08, overtoneGain: .05, overtoneRatio: 2, overtoneWave: "velvet", room: .64, width: .9, pan: base.pan * 1.15, drive: .06, fm: .028, fmRatio: 1.99, sweep: 1.18 };
  if (v.includes("grain") || v.includes("vocal") || v.includes("shimmer") || v.includes("far")) return { ...base, wave: "glass", filter: "bandpass", cutoff: 2600, q: 8, gain: .054, attack: .095, decay: .34, sustain: .58, release: 1.05, subGain: .02, bodyGain: .06, overtoneGain: .025, overtoneRatio: 2, room: .9, width: 1, pan: base.pan * 1.35, drive: .025, fm: .065, fmRatio: 2.52, click: .018 };
  if (v.includes("modular") || v.includes("lead")) return { ...base, wave: "bloom", filter: "lowpass", cutoff: 5600, q: 3.4, gain: .086, attack: .055, decay: .32, sustain: .78, release: .82, subGain: .035, bodyGain: .11, overtoneGain: .085, overtoneRatio: 2, overtoneWave: "glass", room: .58, width: .86, pan: base.pan * 1.05, drive: .065, fm: .04, fmRatio: 1.5, sweep: 1.08 };
  if (v.includes("chip") || v.includes("nes") || v.includes("gameboy")) return { ...base, wave: "fold", cutoff: 5300, q: 4, gain: .052, attack: .004, release: .08, room: .2, width: .42, drive: .045, fm: .03 };
  return base;
}

function registerGain(freq, voice) {
  const v = (voice || "").toLowerCase();
  if (v.includes("hat")) return freq > 1500 ? .82 : .95;
  let gain = 1;
  if (freq < 38) gain *= v.includes("sub") ? 1.05 : .5;
  else if (freq < 60) gain *= v.includes("sub") ? 1.16 : .8;
  else if (freq < 120) gain *= .94;
  else if (freq > 5600) gain *= .2;
  else if (freq > 3000) gain *= .33;
  else if (freq > 1500) gain *= .52;
  if (v.includes("sub") && freq < 120) gain *= 1.12;
  if (v.includes("pad") || v.includes("bloom") || v.includes("glass") || v.includes("drift")) gain *= .7;
  if (v.includes("bell") || v.includes("kalimba") || v.includes("shimmer")) gain *= .46;
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
  low.type = "lowshelf"; low.frequency.value = 58; low.gain.value = 2.1;
  mud.type = "peaking"; mud.frequency.value = 285; mud.Q.value = .85; mud.gain.value = -2.7;
  air.type = "highshelf"; air.frequency.value = 7800; air.gain.value = .6;
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
  if (patch.kind === "hat") {
    [2.21, 2.77, 3.19].forEach((r) => n.toneTap(ctx, filter, t0, t1 + .035, freq * r, .012, "metal"));
  } else if (patch.kind === "snare") {
    n.toneTap(ctx, filter, t0, t1 + .12, freq * .74, .026, "wood");
    n.toneTap(ctx, filter, t0, t1 + .06, freq * 1.48, .016, "metal");
  } else {
    n.toneTap(ctx, filter, t0, t1 + .08, Math.max(42, freq * .52), .032, "silk");
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

function contour(param, t0, t1, peak, patch) {
  const attackEnd = Math.min(t1, t0 + Math.max(.001, patch.attack));
  const sustain = Math.max(.0001, peak * Math.max(.02, Math.min(1, patch.sustain ?? .72)));
  param.setValueAtTime(.0001, t0);
  param.exponentialRampToValueAtTime(Math.max(.0001, peak), attackEnd);
  if (t1 > attackEnd + .006) {
    const decayEnd = Math.min(t1, attackEnd + Math.max(.001, patch.decay ?? .16));
    param.exponentialRampToValueAtTime(sustain, decayEnd);
    if (t1 > decayEnd + .006) param.setValueAtTime(sustain, t1);
  }
  param.exponentialRampToValueAtTime(.0001, t1 + Math.max(.015, patch.release));
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
  const overtone = ctx.createOscillator();
  const og = ctx.createGain();
  const dg = ctx.createGain();
  const bg = ctx.createGain();
  const hg = ctx.createGain();
  const filter = ctx.createBiquadFilter();
  const sat = n.drive(ctx, patch.drive);
  const amp = ctx.createGain();
  tune(osc, freq, patch, t0, v, patch.pan > 0 ? 5 : -5);
  tune(det, freq, patch, t0, v, patch.pan > 0 ? -13 : 13);
  overtone.setPeriodicWave(n.wave(ctx, patch.overtoneWave || patch.wave));
  overtone.frequency.setValueAtTime(freq * (patch.overtoneRatio || 2), t0);
  overtone.detune.value = patch.pan > 0 ? 3 : -3;
  body.type = "sine"; body.frequency.setValueAtTime(freq * (v.includes("bell") ? 2 : .5), t0);
  filter.type = patch.filter;
  const cut = Math.max(55, Math.min(15000, patch.cutoff + Math.log2(freq / 220) * 360));
  filter.frequency.setValueAtTime(cut, t0);
  if (patch.sweep) filter.frequency.exponentialRampToValueAtTime(Math.min(15000, cut * patch.sweep), t0 + Math.max(.11, patch.attack + patch.decay));
  filter.Q.value = patch.q;
  og.gain.value = .72; dg.gain.value = patch.width * .2; bg.gain.value = freq < 1200 ? patch.bodyGain : patch.bodyGain * .22;
  hg.gain.value = freq < 2600 ? patch.overtoneGain : patch.overtoneGain * .2;
  contour(amp.gain, t0, t1, patch.gain * registerGain(freq, note.voice), patch);
  if (patch.detailGain) {
    n.toneTap(ctx, filter, t0, t1 + patch.release * .45, freq * patch.detailRatio, patch.detailGain, patch.detailWave);
    if (v.includes("piano")) n.toneTap(ctx, filter, t0, t1 + .75, freq * 4.97, .014, "glass");
    if (v.includes("guitar")) n.toneTap(ctx, filter, t0, t1 + .28, freq * 5.01, .012, "tine");
    if (v.includes("sax")) n.toneTap(ctx, filter, t0, t1 + .35, freq * 1.51, .018, "brass");
  }
  n.noiseBurst(ctx, filter, t0, t0 + .025, patch.click, "bandpass", Math.min(9000, cut * 1.5));
  n.noiseBurst(ctx, filter, t0, t1 + patch.release * .35, patch.breathGain, "bandpass", Math.min(9000, cut * 1.4));
  osc.connect(og); det.connect(dg); body.connect(bg);
  overtone.connect(hg);
  og.connect(filter); dg.connect(filter); bg.connect(filter); hg.connect(filter); filter.connect(sat); sat.connect(amp);
  n.connectSpace(ctx, amp, bus, patch, freq);
  const mods = [
    ...n.addFm(ctx, osc, freq, t0, t1, patch),
    ...n.addFm(ctx, det, freq, t0, t1, { ...patch, fm: patch.fm * .55 }),
    ...n.addVibrato(ctx, osc, t0, t1, patch),
    ...n.addVibrato(ctx, det, t0, t1, { ...patch, vibratoDepth: patch.vibratoDepth * .7 }),
  ];
  n.startStop([osc, det, body, overtone, ...mods], t0, t1 + patch.release + .08);
}

async function playSource(source, eventReader, tempoReader) {
  stopPreview();
  const Audio = window.AudioContext || window.webkitAudioContext;
  if (!Audio || !window.RelanoteNodes) return;
  const notes = await eventReader(source);
  if (!notes.length) return;
  const ctx = new Audio();
  previewAudio = ctx;
  await ctx.resume();
  const bus = mixer(ctx);
  const bps = await tempoReader(source) / 60;
  notes.forEach((note, i) => schedule(ctx, note, ctx.currentTime + .06, bps, i, bus));
  const end = Math.max(0, ...notes.map((note) => note.start + note.duration));
  setTimeout(stopPreview, end / bps * 1000 + 1700);
}

window.RelanoteAudio = { playSource, stopPreview };
