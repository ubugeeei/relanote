function laneHash(lane, seed = 0) {
  const x = Math.sin((lane + 1) * 78.233 + seed * 37.719) * 43758.5453;
  return x - Math.floor(x);
}

function spatialize(patch, voice, lane) {
  const v = (voice || "").toLowerCase();
  const p = { ...patch };
  if (v.includes("center") || v.includes("mono")) {
    p.pan = 0; p.width *= .35; p.panDrift = 0;
  }
  if (v.includes("left")) p.pan = -Math.max(.38, Math.abs(p.pan));
  if (v.includes("right")) p.pan = Math.max(.38, Math.abs(p.pan));
  if (v.includes("near")) {
    p.room *= .48; p.width *= .55; p.preDelay = .005;
  }
  if (v.includes("far") || v.includes("ghost") || v.includes("wash")) {
    p.room = Math.min(1, p.room + .28);
    p.width = Math.max(p.width, .82);
    p.preDelay = Math.max(p.preDelay || 0, .034 + laneHash(lane, 4) * .025);
    p.gain *= v.includes("ghost") ? .68 : .84;
  }
  if (v.includes("pan") || v.includes("orbit") || v.includes("scatter") || v.includes("swerve")) {
    p.width = Math.max(p.width, .88);
    p.panDrift = Math.max(p.panDrift || 0, .18 + laneHash(lane, 1) * .36);
    p.panRate = .045 + laneHash(lane, 2) * .17;
    if (Math.abs(p.pan) < .18) p.pan = (laneHash(lane, 3) * 2 - 1) * .55;
  }
  if (v.includes("delay") || v.includes("echo") || v.includes("throw")) {
    p.echo = Math.max(p.echo || 0, .08 + laneHash(lane, 5) * .08);
    p.echoTime = .16 + laneHash(lane, 6) * .23;
    p.room = Math.min(1, p.room + .16);
    p.preDelay = Math.max(p.preDelay || 0, .02);
  }
  if (v.includes("micro") || v.includes("human") || v.includes("strum") || v.includes("ghost")) {
    p.microShift = Math.max(p.microShift || 0, .006 + laneHash(lane, 7) * .018);
  }
  if (v.includes("dust") || v.includes("mist") || v.includes("grain")) {
    p.airGain = Math.max(p.airGain || 0, .012);
    p.shimmerGain = Math.max(p.shimmerGain || 0, .012);
    p.width = Math.max(p.width, .9);
  }
  if (v.includes("lead")) {
    p.microDetune = Math.max(p.microDetune || 0, 3 + laneHash(lane, 8) * 8);
  }
  return p;
}

function patchFor(voice, lane) {
  const v = (voice || "").toLowerCase();
  const base = {
    wave: "velvet", filter: "lowpass", cutoff: 5200, q: 3, gain: .105,
    attack: .018, decay: .16, sustain: .72, release: .14,
    subGain: .08, bodyGain: .08, overtoneGain: 0, overtoneRatio: 2, overtoneWave: "silk",
    detailGain: 0, detailRatio: 3, detailWave: "silk", vibratoDepth: 0,
    pan: (lane % 9 - 4) * .18,
    room: .34, width: .3, drive: .05, fm: 0, fmRatio: 2.01, click: 0, breathGain: 0,
    panDrift: 0, panRate: 0, preDelay: .012, echo: 0, echoTime: .23, microShift: 0,
    microDetune: 0, airGain: 0, shimmerGain: 0, kind: "tone",
  };
  if (v.includes("kick")) return spatialize({ ...base, kind: "kick", gain: .24, room: .035, width: 0, pan: 0, click: .14 }, v, lane);
  if (v.includes("snare")) return spatialize({ ...base, kind: "snare", gain: .11, room: .42, width: .42, click: .34 }, v, lane);
  if (v.includes("hat") || v.includes("tick")) return spatialize({ ...base, kind: "hat", gain: v.includes("tick") ? .048 : .082, room: .28, width: .72, click: .32 }, v, lane);
  if (v.includes("sub")) return spatialize({ ...base, wave: "silk", cutoff: 300, q: 9, gain: .205, subGain: .82, bodyGain: .05, attack: .008, decay: .2, sustain: .86, release: .32, pan: 0, room: .025, width: 0, drive: .08 }, v, lane);
  if (v.includes("acid")) return spatialize({ ...base, wave: "reed", cutoff: 1150, q: 15, gain: .105, subGain: .38, bodyGain: .1, attack: .01, decay: .14, sustain: .48, release: .26, room: .12, width: .12, drive: .15, fm: .018, sweep: 2.1 }, v, lane);
  if (v.includes("upright") || v.includes("woodbass")) return spatialize({ ...base, wave: "wood", cutoff: 980, q: 5.8, gain: .13, subGain: .5, bodyGain: .16, overtoneGain: .045, overtoneRatio: 2, detailGain: .035, detailRatio: 3.02, detailWave: "wood", attack: .028, decay: .28, sustain: .72, release: .46, pan: base.pan * .08, room: .16, width: .12, drive: .06, click: .012 }, v, lane);
  if (v.includes("bass") || v.includes("moog")) return spatialize({ ...base, wave: "bloom", cutoff: 720, q: 10, gain: .13, subGain: .46, bodyGain: .12, attack: .012, decay: .22, sustain: .68, release: .28, pan: base.pan * .12, room: .08, width: .08, drive: .13 }, v, lane);
  if (v.includes("epiano") || v.includes("electricpiano") || v.includes("tine") || v.includes("pickup") || v.includes("bark")) return spatialize({ ...base, wave: "tine", cutoff: 6400, q: 2.6, gain: .072, subGain: .025, bodyGain: .11, overtoneGain: .095, overtoneRatio: 2.01, overtoneWave: "velvet", detailGain: .052, detailRatio: 3.01, detailWave: "tine", vibratoDepth: 3.5, vibratoRate: 5.7, vibratoDelay: .18, attack: .007, decay: .55, sustain: .34, release: 1.15, room: .5, width: .72, drive: .045, fm: .22, fmRatio: 2.98, click: .014, breathGain: .006 }, v, lane);
  if (v.includes("piano")) return spatialize({ ...base, wave: v.includes("felt") ? "felt" : "wood", cutoff: 6800, q: 2.1, gain: .068, subGain: .035, bodyGain: .13, overtoneGain: .07, overtoneRatio: 2, overtoneWave: "velvet", detailGain: .038, detailRatio: 3.96, detailWave: "glass", attack: .006, decay: .62, sustain: .26, release: 1.05, room: .42, width: .56, drive: .028, fm: .12, fmRatio: 2.01, click: .02 }, v, lane);
  if (v.includes("guitar")) return spatialize({ ...base, wave: "wood", filter: "bandpass", cutoff: 3300, q: 4.2, gain: .064, subGain: .018, bodyGain: .08, overtoneGain: .09, overtoneRatio: 2, overtoneWave: "glass", detailGain: .04, detailRatio: 2.98, detailWave: "wood", attack: .005, decay: .34, sustain: .34, release: .62, room: .48, width: .66, drive: .04, fm: .018, fmRatio: 2.02, click: .026, breathGain: .01 }, v, lane);
  if (v.includes("sax")) return spatialize({ ...base, wave: "brass", filter: "bandpass", cutoff: 1850, q: 4.8, gain: .074, subGain: .025, bodyGain: .12, overtoneGain: .08, overtoneRatio: 2, overtoneWave: "velvet", detailGain: .045, detailRatio: 3.03, detailWave: "reed", vibratoDepth: 12, vibratoRate: 5.4, vibratoDelay: .16, attack: .085, decay: .25, sustain: .86, release: .72, room: .46, width: .58, drive: .075, fm: .024, fmRatio: 1.01, breathGain: .035 }, v, lane);
  if (v.includes("rhodes")) return spatialize({ ...base, wave: "glass", cutoff: 7200, q: 2, gain: .074, attack: .012, decay: .48, sustain: .38, release: .9, room: .44, width: .62, drive: .035, fm: .28, fmRatio: 2.98, click: .01, overtoneGain: .035, overtoneRatio: 2 }, v, lane);
  if (v.includes("bell") || v.includes("kalimba")) return spatialize({ ...base, wave: "glass", cutoff: 9200, q: 1.6, gain: .058, attack: .006, decay: .72, sustain: .2, release: 1.15, room: .58, width: .78, drive: .02, fm: .42, fmRatio: 3.97, click: .015, overtoneGain: .045, overtoneRatio: 2.01 }, v, lane);
  if (v.includes("string")) return spatialize({ ...base, wave: "string", cutoff: 4200, q: 2.5, gain: .052, attack: .18, decay: .42, sustain: .78, release: 1.35, bodyGain: .1, overtoneGain: .06, overtoneRatio: 2, overtoneWave: "velvet", detailGain: .02, detailRatio: 3, detailWave: "felt", room: .7, width: .86, drive: .025, fm: .012, fmRatio: 1.5 }, v, lane);
  if (v.includes("pad") || v.includes("bloom") || v.includes("glass") || v.includes("drift")) return spatialize({ ...base, wave: "bloom", cutoff: 2450, q: 2.1, gain: .06, attack: .38, decay: .42, sustain: .82, release: 1.45, subGain: .045, bodyGain: .11, room: .78, width: .98, drive: .03, fm: .014, fmRatio: 1.5 }, v, lane);
  if (v.includes("vapor") || v.includes("supersaw")) return spatialize({ ...base, wave: "bloom", filter: "lowpass", cutoff: 6200, q: 2.8, gain: .082, attack: .045, decay: .3, sustain: .76, release: .78, subGain: .035, bodyGain: .12, overtoneGain: .075, overtoneRatio: 2, overtoneWave: "glass", room: .64, width: .96, pan: base.pan * 1.05, drive: .055, fm: .036, fmRatio: 1.51, sweep: 1.12 }, v, lane);
  if (v.includes("wave") || v.includes("formant")) return spatialize({ ...base, wave: v.includes("formant") ? "reed" : "fold", filter: "bandpass", cutoff: 3200, q: 5.2, gain: .07, attack: .038, decay: .28, sustain: .64, release: .7, subGain: .03, bodyGain: .08, overtoneGain: .05, overtoneRatio: 2, overtoneWave: "velvet", room: .64, width: .9, pan: base.pan * 1.15, drive: .06, fm: .028, fmRatio: 1.99, sweep: 1.18 }, v, lane);
  if (v.includes("grain") || v.includes("vocal") || v.includes("shimmer") || v.includes("far") || v.includes("dust") || v.includes("mist")) return spatialize({ ...base, wave: v.includes("dust") ? "dust" : "glass", filter: "bandpass", cutoff: 2600, q: 8, gain: .054, attack: .095, decay: .34, sustain: .58, release: 1.05, subGain: .02, bodyGain: .06, overtoneGain: .025, overtoneRatio: 2, room: .9, width: 1, pan: base.pan * 1.35, drive: .025, fm: .065, fmRatio: 2.52, click: .018 }, v, lane);
  if (v.includes("modular") || v.includes("lead")) return spatialize({ ...base, wave: "bloom", filter: "lowpass", cutoff: 5600, q: 3.4, gain: .086, attack: .055, decay: .32, sustain: .78, release: .82, subGain: .035, bodyGain: .11, overtoneGain: .085, overtoneRatio: 2, overtoneWave: "glass", room: .58, width: .86, pan: base.pan * 1.05, drive: .065, fm: .04, fmRatio: 1.5, sweep: 1.08 }, v, lane);
  if (v.includes("chip") || v.includes("nes") || v.includes("gameboy")) return spatialize({ ...base, wave: "fold", cutoff: 5300, q: 4, gain: .052, attack: .004, release: .08, room: .2, width: .42, drive: .045, fm: .03 }, v, lane);
  return spatialize(base, v, lane);
}

function registerGain(freq, voice) {
  const v = (voice || "").toLowerCase();
  if (v.includes("hat") || v.includes("tick")) return freq > 1500 ? .88 : .98;
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
  if (v.includes("dust") || v.includes("mist") || v.includes("air")) gain *= .82;
  if ((v.includes("sub") || v.includes("bass")) && freq > 240) gain *= .52;
  return gain;
}

function timingOffset(note, lane, patch) {
  if (!patch.microShift) return 0;
  const seed = note.start * 1.7 + note.pitch * .11 + lane * .37;
  return (Math.sin(seed) * .5 + .5) * patch.microShift;
}

window.RelanotePatches = { patchFor, registerGain, timingOffset };
