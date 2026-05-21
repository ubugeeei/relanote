let previewAudio;

function stopPreview() {
  if (previewAudio) previewAudio.close();
  previewAudio = null;
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
  const p = window.RelanotePatches;
  const freq = 440 * Math.pow(2, (note.pitch - 69) / 12);
  const t0 = base + note.start / bps + p.timingOffset(note, lane, patch);
  const t1 = t0 + Math.min(note.duration / bps, patch.kind === "hat" ? .08 : .22);
  const amp = ctx.createGain();
  const filter = ctx.createBiquadFilter();
  const sat = n.drive(ctx, patch.kind === "kick" ? .12 : .07);
  amp.gain.setValueAtTime(.0001, t0);
  amp.gain.exponentialRampToValueAtTime(patch.gain * p.registerGain(freq, note.voice), t0 + .004);
  amp.gain.exponentialRampToValueAtTime(.0001, t1 + .08);
  filter.type = patch.kind === "kick" ? "lowpass" : "bandpass";
  filter.frequency.setValueAtTime(patch.kind === "kick" ? 150 : patch.kind === "snare" ? 1900 : 8500, t0);
  filter.Q.value = patch.kind === "hat" ? 1.3 : 5.2;
  filter.connect(sat); sat.connect(amp);
  const spaceMods = n.connectSpace(ctx, amp, bus, patch, freq, t0, t1);
  if (patch.kind !== "hat") {
    const body = ctx.createOscillator();
    body.type = patch.kind === "kick" ? "sine" : "triangle";
    body.frequency.setValueAtTime(patch.kind === "kick" ? freq * 3.1 : freq * 1.55, t0);
    body.frequency.exponentialRampToValueAtTime(patch.kind === "kick" ? Math.max(36, freq * .62) : freq * 1.08, t0 + .07);
    body.connect(filter); n.startStop([body, ...spaceMods], t0, t1 + .1);
  } else if (spaceMods.length) {
    n.startStop(spaceMods, t0, t1 + .1);
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
  const p = window.RelanotePatches;
  const patch = p.patchFor(note.voice, lane);
  if (patch.kind !== "tone") return percussion(ctx, note, base, bps, lane, bus, patch);
  const v = (note.voice || "").toLowerCase();
  const freq = 440 * Math.pow(2, (note.pitch - 69) / 12);
  const t0 = base + note.start / bps + p.timingOffset(note, lane, patch);
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
  tune(osc, freq, patch, t0, v, (patch.pan > 0 ? 5 : -5) + (patch.microDetune || 0));
  tune(det, freq, patch, t0, v, (patch.pan > 0 ? -13 : 13) - (patch.microDetune || 0) * .8);
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
  contour(amp.gain, t0, t1, patch.gain * p.registerGain(freq, note.voice), patch);
  if (patch.detailGain) {
    n.toneTap(ctx, filter, t0, t1 + patch.release * .45, freq * patch.detailRatio, patch.detailGain, patch.detailWave);
    if (v.includes("piano")) n.toneTap(ctx, filter, t0, t1 + .75, freq * 4.97, .014, "glass");
    if (v.includes("guitar")) n.toneTap(ctx, filter, t0, t1 + .28, freq * 5.01, .012, "tine");
    if (v.includes("sax")) n.toneTap(ctx, filter, t0, t1 + .35, freq * 1.51, .018, "brass");
  }
  if (patch.shimmerGain) {
    n.toneTap(ctx, filter, t0 + .012, t1 + patch.release * .55, freq * 7.01, patch.shimmerGain, "air");
    n.toneTap(ctx, filter, t0 + .027, t1 + patch.release * .45, freq * 9.97, patch.shimmerGain * .7, "glass");
  }
  n.noiseBurst(ctx, filter, t0, t0 + .025, patch.click, "bandpass", Math.min(9000, cut * 1.5));
  n.noiseBurst(ctx, filter, t0, t1 + patch.release * .35, patch.breathGain, "bandpass", Math.min(9000, cut * 1.4));
  n.noiseBurst(ctx, filter, t0, t1 + patch.release * .55, patch.airGain, "highpass", Math.min(12000, cut * 1.8));
  osc.connect(og); det.connect(dg); body.connect(bg);
  overtone.connect(hg);
  og.connect(filter); dg.connect(filter); bg.connect(filter); hg.connect(filter); filter.connect(sat); sat.connect(amp);
  const spaceMods = n.connectSpace(ctx, amp, bus, patch, freq, t0, t1);
  const mods = [
    ...n.addFm(ctx, osc, freq, t0, t1, patch),
    ...n.addFm(ctx, det, freq, t0, t1, { ...patch, fm: patch.fm * .55 }),
    ...n.addVibrato(ctx, osc, t0, t1, patch),
    ...n.addVibrato(ctx, det, t0, t1, { ...patch, vibratoDepth: patch.vibratoDepth * .7 }),
  ];
  n.startStop([osc, det, body, overtone, ...mods, ...spaceMods], t0, t1 + patch.release + .08);
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
