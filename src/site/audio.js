let previewAudio;

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
    cutoff: 5400,
    q: 4,
    gain: .13,
    attack: .014,
    release: .1,
    subGain: .1,
    noise: 0,
    detune: lane % 2 ? 7 : -7,
    pan: (lane % 5 - 2) * .16,
    room: .22,
    width: .18,
  };
  if (v.includes("kick")) return { ...patch, osc: "sine", cutoff: 130, q: 8, gain: .18, subGain: .64, attack: .001, release: .12, noise: .035, pan: 0, room: .035, width: 0 };
  if (v.includes("snare")) return { ...patch, osc: "square", filter: "highpass", cutoff: 1200, q: 5, gain: .1, subGain: 0, attack: .001, release: .1, noise: .33, room: .28, width: .34 };
  if (v.includes("hat")) return { ...patch, osc: "square", filter: "highpass", cutoff: 7200, q: 2, gain: .034, subGain: 0, attack: .001, release: .045, noise: .28, room: .22, width: .58 };
  if (v.includes("sub")) return { ...patch, osc: "triangle", cutoff: 420, q: 8, gain: .15, subGain: .58, attack: .006, release: .16, detune: -2, pan: 0, room: .04, width: .02 };
  if (v.includes("bass") || v.includes("acid") || v.includes("moog")) return { ...patch, osc: "sawtooth", cutoff: v.includes("acid") ? 1180 : 740, q: 13, gain: .145, subGain: .42, attack: .005, release: .18, detune: -5, pan: patch.pan * .18, room: .08, width: .08 };
  if (v.includes("pad") || v.includes("bloom") || v.includes("glass") || v.includes("drift")) return { ...patch, osc: "sawtooth", sub: "triangle", cutoff: 2600, q: 3, gain: .072, subGain: .06, attack: .28, release: .92, detune: 12, room: .62, width: .86 };
  if (v.includes("fm") || v.includes("bell") || v.includes("rhodes") || v.includes("kalimba")) return { ...patch, osc: "sine", sub: "triangle", cutoff: 10800, q: 2, gain: .083, subGain: .025, attack: .003, release: .5, detune: 9, room: .48, width: .72 };
  if (v.includes("wave")) return { ...patch, osc: "sawtooth", sub: "square", filter: "bandpass", cutoff: 3900, q: 8, gain: .09, subGain: .045, attack: .02, release: .3, detune: 11, room: .42, width: .76 };
  if (v.includes("grain")) return { ...patch, osc: "triangle", sub: "sawtooth", filter: "bandpass", cutoff: 2400, q: 10, gain: .078, subGain: .035, attack: .065, release: .58, detune: lane % 2 ? 19 : -13, noise: .055, room: .66, width: .92 };
  if (v.includes("chip") || v.includes("nes") || v.includes("gameboy")) return { ...patch, osc: "square", sub: "square", cutoff: 6900, q: 1, gain: .07, subGain: 0, attack: .002, release: .04, room: .1, width: .26 };
  return patch;
}

function registerGain(freq, voice) {
  let gain = 1;
  if (freq < 38) gain *= .42;
  else if (freq < 58) gain *= .62;
  else if (freq < 120) gain *= .8;
  else if (freq > 5200) gain *= .22;
  else if (freq > 2800) gain *= .34;
  else if (freq > 1400) gain *= .54;
  const v = (voice || "").toLowerCase();
  if (v.includes("pad") || v.includes("bloom") || v.includes("glass") || v.includes("drift")) gain *= .72;
  if (v.includes("hat") || v.includes("bell") || v.includes("kalimba") || v.includes("shimmer")) gain *= .5;
  if ((v.includes("sub") || v.includes("bass")) && freq > 240) gain *= .58;
  return gain;
}

function impulse(ctx, seconds) {
  const length = Math.floor(ctx.sampleRate * seconds);
  const buffer = ctx.createBuffer(2, length, ctx.sampleRate);
  for (let c = 0; c < 2; c++) {
    const data = buffer.getChannelData(c);
    for (let i = 0; i < length; i++) {
      const fade = Math.pow(1 - i / length, 2.4);
      data[i] = (Math.random() * 2 - 1) * fade * (c ? .82 : 1);
    }
  }
  return buffer;
}

function mixer(ctx) {
  const dry = ctx.createGain();
  const room = ctx.createGain();
  const pre = ctx.createBiquadFilter();
  const verb = ctx.createConvolver();
  const delay = ctx.createDelay(1.2);
  const fb = ctx.createGain();
  const wet = ctx.createGain();
  const low = ctx.createBiquadFilter();
  const mud = ctx.createBiquadFilter();
  const air = ctx.createBiquadFilter();
  const comp = ctx.createDynamicsCompressor();
  dry.gain.value = .86; room.gain.value = .78; wet.gain.value = .24;
  pre.type = "highpass"; pre.frequency.value = 150;
  delay.delayTime.value = .33; fb.gain.value = .23;
  verb.buffer = impulse(ctx, 2.7);
  low.type = "lowshelf"; low.frequency.value = 70; low.gain.value = -1.4;
  mud.type = "peaking"; mud.frequency.value = 320; mud.Q.value = .8; mud.gain.value = -2.4;
  air.type = "highshelf"; air.frequency.value = 7200; air.gain.value = -1.2;
  comp.threshold.value = -18; comp.knee.value = 24; comp.ratio.value = 3.4;
  comp.attack.value = .004; comp.release.value = .17;
  dry.connect(low); low.connect(mud); mud.connect(air); air.connect(comp);
  room.connect(pre); pre.connect(verb); verb.connect(wet); wet.connect(comp);
  room.connect(delay); delay.connect(fb); fb.connect(delay); delay.connect(wet);
  comp.connect(ctx.destination);
  return { dry, room };
}

function noiseBurst(ctx, dest, t0, t1, amount) {
  if (!amount) return;
  const n = Math.max(1, Math.ceil((t1 - t0) * ctx.sampleRate));
  const buffer = ctx.createBuffer(1, n, ctx.sampleRate);
  const data = buffer.getChannelData(0);
  for (let i = 0; i < n; i++) data[i] = (Math.random() * 2 - 1) * Math.pow(1 - i / n, 1.6);
  const src = ctx.createBufferSource();
  const gain = ctx.createGain();
  src.buffer = buffer;
  gain.gain.value = amount;
  src.connect(gain); gain.connect(dest);
  src.start(t0); src.stop(t1);
}

function connectSpace(ctx, amp, bus, patch, freq) {
  const pan = ctx.createStereoPanner ? ctx.createStereoPanner() : null;
  const room = ctx.createGain();
  room.gain.value = patch.room * (freq < 135 ? .16 : 1);
  if (pan) {
    pan.pan.value = freq < 140 ? patch.pan * .12 : patch.pan;
    amp.connect(pan); pan.connect(bus.dry);
  } else {
    amp.connect(bus.dry);
  }
  amp.connect(room); room.connect(bus.room);
  if (!ctx.createDelay || !ctx.createStereoPanner || patch.width < .15) return;
  const spread = ctx.createDelay(.05);
  const wide = ctx.createGain();
  const widePan = ctx.createStereoPanner();
  spread.delayTime.value = .009 + patch.width * .018;
  wide.gain.value = patch.width * (freq < 180 ? .08 : .18);
  widePan.pan.value = patch.pan > 0 ? -.62 : .62;
  amp.connect(spread); spread.connect(wide); wide.connect(widePan); widePan.connect(bus.dry);
}

function tuneNode(node, freq, patch, t0, v) {
  if (v.includes("kick")) {
    node.frequency.setValueAtTime(freq * 2.7, t0);
    node.frequency.exponentialRampToValueAtTime(freq, t0 + .055);
    return;
  }
  node.frequency.setValueAtTime(freq, t0);
  if (v.includes("acid")) node.frequency.linearRampToValueAtTime(freq * 1.01, t0 + .08);
  node.detune.value = patch.detune;
}

function schedule(ctx, note, base, bps, lane, bus) {
  const patch = patchFor(note.voice, lane);
  const v = (note.voice || "").toLowerCase();
  const freq = 440 * Math.pow(2, (note.pitch - 69) / 12);
  const t0 = base + note.start / bps;
  const t1 = t0 + note.duration / bps;
  const osc = ctx.createOscillator();
  const det = ctx.createOscillator();
  const sub = ctx.createOscillator();
  const oscGain = ctx.createGain();
  const detGain = ctx.createGain();
  const subGain = ctx.createGain();
  const filter = ctx.createBiquadFilter();
  const amp = ctx.createGain();
  osc.type = patch.osc; det.type = patch.osc; sub.type = patch.sub;
  tuneNode(osc, freq, patch, t0, v);
  tuneNode(det, freq, { ...patch, detune: -patch.detune }, t0, v);
  sub.frequency.setValueAtTime(freq / 2, t0);
  filter.type = patch.filter;
  filter.frequency.setValueAtTime(Math.max(50, Math.min(15000, patch.cutoff + Math.log2(freq / 220) * 390)), t0);
  if (v.includes("acid")) filter.frequency.exponentialRampToValueAtTime(Math.min(6500, patch.cutoff * 2.4), t0 + .075);
  filter.Q.value = patch.q;
  oscGain.gain.value = .78; detGain.gain.value = patch.width * .22; subGain.gain.value = freq < 760 ? patch.subGain : 0;
  amp.gain.setValueAtTime(.0001, t0);
  amp.gain.exponentialRampToValueAtTime(patch.gain * registerGain(freq, note.voice), t0 + patch.attack);
  amp.gain.exponentialRampToValueAtTime(.0001, t1 + patch.release);
  noiseBurst(ctx, filter, t0, t1 + patch.release, patch.noise);
  osc.connect(oscGain); det.connect(detGain); sub.connect(subGain);
  oscGain.connect(filter); detGain.connect(filter); subGain.connect(filter); filter.connect(amp);
  connectSpace(ctx, amp, bus, patch, freq);
  [osc, det, sub].forEach((node) => { node.start(t0); node.stop(t1 + patch.release + .06); });
}

async function playSource(source, eventReader, tempoReader) {
  stopPreview();
  const Audio = window.AudioContext || window.webkitAudioContext;
  if (!Audio) return;
  const notes = await eventReader(source);
  if (!notes.length) return;
  const ctx = new Audio();
  previewAudio = ctx;
  await ctx.resume();
  const bus = mixer(ctx);
  const bps = await tempoReader(source) / 60;
  notes.forEach((note, i) => schedule(ctx, note, ctx.currentTime + .06, bps, i, bus));
  const end = Math.max(0, ...notes.map((note) => note.start + note.duration));
  setTimeout(stopPreview, end / bps * 1000 + 1500);
}

window.RelanoteAudio = { playSource, stopPreview };
