function cached(ctx, key, factory) {
  ctx._relaCache ||= {};
  if (!ctx._relaCache[key]) ctx._relaCache[key] = factory();
  return ctx._relaCache[key];
}

function wave(ctx, name) {
  return cached(ctx, `wave:${name}`, () => {
    const real = new Float32Array(12);
    const imag = new Float32Array(12);
    const bank = {
      velvet: [0, 1, .28, .16, .07, .035, .018, .012],
      glass: [0, 1, .08, .35, .04, .18, .02, .09, .015],
      reed: [0, 1, .48, .16, .31, .06, .11, .035],
      bloom: [0, 1, .38, .19, .12, .08, .045, .03, .018],
      fold: [0, .82, .52, -.24, .18, -.13, .07, -.045],
      silk: [0, 1, .18, .08, .04, .025, .016, .01],
      tine: [0, 1, .04, .34, .025, .22, .018, .11, .012],
      wood: [0, 1, .32, .12, .08, .045, .025, .014],
      brass: [0, 1, .56, .22, .31, .14, .09, .04],
      metal: [0, .55, .2, .64, .12, .36, .08, .2, .05],
      felt: [0, 1, .22, .12, .055, .036, .018, .012, .007],
      air: [0, .35, .18, .09, .045, .025, .014, .008],
      dust: [0, .62, -.18, .3, -.12, .17, -.06, .08, -.03],
      string: [0, 1, .44, .2, .12, .07, .04, .025, .016],
      plasma: [0, .86, .48, -.18, .26, -.09, .13, -.04, .06],
    }[name] || [0, 1, .24, .09, .04];
    bank.forEach((value, i) => { if (i < imag.length) imag[i] = value; });
    return ctx.createPeriodicWave(real, imag, { disableNormalization: false });
  });
}

function drive(ctx, amount) {
  const node = ctx.createWaveShaper();
  const curve = new Float32Array(512);
  const k = amount * 24;
  for (let i = 0; i < curve.length; i++) {
    const x = i / (curve.length - 1) * 2 - 1;
    curve[i] = Math.tanh(x * (1 + k)) / Math.tanh(1 + k);
  }
  node.curve = curve;
  node.oversample = "4x";
  return node;
}

function impulse(ctx, seconds) {
  return cached(ctx, `impulse:${seconds}`, () => {
    const length = Math.floor(ctx.sampleRate * seconds);
    const buffer = ctx.createBuffer(2, length, ctx.sampleRate);
    for (let c = 0; c < 2; c++) {
      const data = buffer.getChannelData(c);
      for (let i = 0; i < length; i++) {
        const age = i / length;
        const tail = Math.pow(1 - age, 2.7);
        const early = i < ctx.sampleRate * .08 ? .34 : 1;
        const sway = 1 + Math.sin(age * 41 + c * 1.7) * .09;
        data[i] = (Math.random() * 2 - 1) * tail * early * sway * (c ? .78 : 1);
      }
    }
    return buffer;
  });
}

function noiseBuffer(ctx, seconds) {
  return cached(ctx, `noise:${seconds}`, () => {
    const length = Math.max(1, Math.ceil(ctx.sampleRate * seconds));
    const buffer = ctx.createBuffer(1, length, ctx.sampleRate);
    const data = buffer.getChannelData(0);
    let last = 0;
    for (let i = 0; i < length; i++) {
      last = last * .55 + (Math.random() * 2 - 1) * .45;
      data[i] = last;
    }
    return buffer;
  });
}

function noiseBurst(ctx, dest, t0, t1, amount, filterType = "bandpass", cutoff = 4200) {
  if (!amount) return;
  const src = ctx.createBufferSource();
  const filter = ctx.createBiquadFilter();
  const gain = ctx.createGain();
  src.buffer = noiseBuffer(ctx, Math.max(.03, t1 - t0));
  filter.type = filterType;
  filter.frequency.setValueAtTime(cutoff, t0);
  filter.Q.value = filterType === "highpass" ? .8 : 4.5;
  gain.gain.setValueAtTime(.0001, t0);
  gain.gain.exponentialRampToValueAtTime(amount, t0 + .003);
  gain.gain.exponentialRampToValueAtTime(.0001, t1);
  src.connect(filter); filter.connect(gain); gain.connect(dest);
  src.start(t0); src.stop(t1);
}

function toneTap(ctx, dest, t0, t1, freq, amount, waveName = "silk") {
  if (!amount || freq < 18) return;
  const osc = ctx.createOscillator();
  const gain = ctx.createGain();
  osc.setPeriodicWave(wave(ctx, waveName));
  osc.frequency.setValueAtTime(Math.min(15000, freq), t0);
  gain.gain.setValueAtTime(.0001, t0);
  gain.gain.exponentialRampToValueAtTime(amount, t0 + .006);
  gain.gain.exponentialRampToValueAtTime(.0001, t1);
  osc.connect(gain); gain.connect(dest);
  osc.start(t0); osc.stop(t1 + .04);
}

function addVibrato(ctx, osc, t0, t1, patch) {
  if (!patch.vibratoDepth) return [];
  const lfo = ctx.createOscillator();
  const depth = ctx.createGain();
  lfo.type = "sine";
  lfo.frequency.setValueAtTime(patch.vibratoRate || 5.2, t0);
  depth.gain.setValueAtTime(.0001, t0);
  depth.gain.linearRampToValueAtTime(.0001, t0 + (patch.vibratoDelay || .04));
  depth.gain.linearRampToValueAtTime(patch.vibratoDepth, t0 + (patch.vibratoDelay || .04) + .08);
  depth.gain.linearRampToValueAtTime(.0001, t1 + patch.release);
  lfo.connect(depth); depth.connect(osc.detune);
  return [lfo];
}

function clamp(v, lo, hi) {
  return Math.max(lo, Math.min(hi, v));
}

function connectSpace(ctx, amp, bus, patch, freq, t0 = 0, t1 = 0) {
  const mods = [];
  const pan = ctx.createStereoPanner ? ctx.createStereoPanner() : null;
  const room = ctx.createGain();
  const send = patch.room * (freq < 135 ? .12 : 1);
  room.gain.value = send;
  if (pan) {
    const basePan = freq < 150 ? patch.pan * .08 : clamp(patch.pan, -.88, .88);
    pan.pan.setValueAtTime(basePan, t0 || ctx.currentTime);
    if (patch.panDrift && t1 > t0) {
      const lfo = ctx.createOscillator();
      const depth = ctx.createGain();
      lfo.type = "sine";
      lfo.frequency.setValueAtTime(patch.panRate || .08, t0);
      depth.gain.setValueAtTime((freq < 150 ? .1 : 1) * patch.panDrift, t0);
      lfo.connect(depth);
      depth.connect(pan.pan);
      mods.push(lfo);
    }
    amp.connect(pan); pan.connect(bus.dry);
  } else {
    amp.connect(bus.dry);
  }
  if (patch.preDelay && ctx.createDelay) {
    const pre = ctx.createDelay(.12);
    pre.delayTime.value = patch.preDelay;
    amp.connect(pre);
    pre.connect(room);
  } else {
    amp.connect(room);
  }
  room.connect(bus.room);
  if (!ctx.createDelay || !ctx.createStereoPanner) return mods;
  if (patch.echo) {
    const echo = ctx.createDelay(.9);
    const echoGain = ctx.createGain();
    const echoPan = ctx.createStereoPanner();
    echo.delayTime.value = patch.echoTime || .23;
    echoGain.gain.value = patch.echo * (freq < 150 ? .15 : 1);
    echoPan.pan.value = clamp(-(patch.pan || .35) + (patch.echoSide || 0), -.9, .9);
    amp.connect(echo);
    echo.connect(echoGain);
    echoGain.connect(echoPan);
    echoPan.connect(bus.room);
  }
  if (patch.width < .12) return mods;
  const a = ctx.createDelay(.07);
  const b = ctx.createGain();
  const p = ctx.createStereoPanner();
  a.delayTime.value = .009 + patch.width * .024;
  b.gain.value = patch.width * (freq < 180 ? .04 : .18);
  p.pan.value = patch.pan > 0 ? -.7 : .7;
  amp.connect(a); a.connect(b); b.connect(p); p.connect(bus.dry);
  return mods;
}

function addFm(ctx, osc, freq, t0, t1, patch) {
  if (!patch.fm) return [];
  const mod = ctx.createOscillator();
  const depth = ctx.createGain();
  mod.type = "sine";
  mod.frequency.setValueAtTime(freq * patch.fmRatio, t0);
  depth.gain.setValueAtTime(freq * patch.fm, t0);
  depth.gain.exponentialRampToValueAtTime(.0001, t1 + patch.release);
  mod.connect(depth); depth.connect(osc.frequency);
  return [mod];
}

function startStop(nodes, t0, t1) {
  nodes.forEach((node) => { node.start(t0); node.stop(t1); });
}

window.RelanoteNodes = { addFm, addVibrato, connectSpace, drive, impulse, noiseBurst, startStop, toneTap, wave };
