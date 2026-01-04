import type { AudioNoteEvent, SynthData, ADSRData } from "../types/relanote";

interface Voice {
  oscillators: OscillatorNode[];
  noiseSource?: AudioBufferSourceNode;
  gainNode: GainNode;
  filterNode?: BiquadFilterNode;
}

// Create a unique key for each voice (synth name + pitch)
const getVoiceKey = (midiNote: number, synthName?: string): string => {
  return synthName ? `${synthName}:${midiNote}` : `default:${midiNote}`;
};

// Default ADSR for notes without synth data
const DEFAULT_ADSR: ADSRData = {
  attack: 0.02,
  decay: 0.1,
  sustain: 0.7,
  release: 0.1,
};

export function useAudioSynth() {
  let audioContext: AudioContext | null = null;
  let masterGain: GainNode | null = null;
  let noiseBuffer: AudioBuffer | null = null;
  const activeVoices = new Map<string, Voice>();

  const isInitialized = ref(false);

  const init = async () => {
    if (audioContext) return;

    audioContext = new AudioContext();
    masterGain = audioContext.createGain();
    masterGain.gain.value = 0.3;
    masterGain.connect(audioContext.destination);

    // Create noise buffer for noise oscillators
    noiseBuffer = createNoiseBuffer(audioContext);

    // Resume context if suspended (required by browsers)
    if (audioContext.state === "suspended") {
      await audioContext.resume();
    }

    isInitialized.value = true;
  };

  // Create white noise buffer
  const createNoiseBuffer = (ctx: AudioContext): AudioBuffer => {
    const bufferSize = ctx.sampleRate * 2; // 2 seconds of noise
    const buffer = ctx.createBuffer(1, bufferSize, ctx.sampleRate);
    const data = buffer.getChannelData(0);
    for (let i = 0; i < bufferSize; i++) {
      data[i] = Math.random() * 2 - 1;
    }
    return buffer;
  };

  // Create pulse wave using PeriodicWave
  const createPulseOscillator = (
    ctx: AudioContext,
    frequency: number,
    dutyCycle: number
  ): OscillatorNode => {
    const oscillator = ctx.createOscillator();
    oscillator.frequency.value = frequency;

    // Create pulse wave using Fourier series
    const harmonics = 64;
    const real = new Float32Array(harmonics);
    const imag = new Float32Array(harmonics);

    real[0] = 0;
    imag[0] = 0;

    for (let n = 1; n < harmonics; n++) {
      // Pulse wave Fourier series: (2/nπ) * sin(n * π * duty) for cosine terms
      real[n] = 0;
      imag[n] = (2 / (n * Math.PI)) * Math.sin(n * Math.PI * dutyCycle);
    }

    const wave = ctx.createPeriodicWave(real, imag, { disableNormalization: true });
    oscillator.setPeriodicWave(wave);

    return oscillator;
  };

  const midiToFrequency = (midiNote: number): number => {
    return 440 * Math.pow(2, (midiNote - 69) / 12);
  };

  const noteOn = (midiNote: number, velocity: number = 100, synth?: SynthData) => {
    if (!audioContext || !masterGain) return;

    // Debug: log synth data
    console.log('[AudioSynth] noteOn:', { midiNote, velocity, synth });

    const voiceKey = getVoiceKey(midiNote, synth?.name);

    // Stop existing voice on same note (same synth + pitch)
    noteOffByKey(voiceKey);

    const adsr = synth?.envelope || DEFAULT_ADSR;
    const baseFreq = midiToFrequency(midiNote);
    const volume = (velocity / 127) * 0.5;

    const gainNode = audioContext.createGain();
    const oscillators: OscillatorNode[] = [];
    let noiseSource: AudioBufferSourceNode | undefined;
    let filterNode: BiquadFilterNode | undefined;

    // Create filter if synth has one
    if (synth?.filter) {
      filterNode = audioContext.createBiquadFilter();
      filterNode.type = synth.filter.filter_type;
      filterNode.frequency.value = synth.filter.cutoff;
      // Convert resonance 0-1 to Q value (0.0001 to 30)
      filterNode.Q.value = synth.filter.resonance * 25 + 0.5;
    }

    // Create oscillators based on synth data or default
    if (synth && synth.oscillators.length > 0) {
      for (const oscData of synth.oscillators) {
        // Calculate frequency with octave offset
        const freq = baseFreq * Math.pow(2, oscData.octave_offset);

        if (oscData.waveform === "noise") {
          // Create noise source
          if (noiseBuffer) {
            noiseSource = audioContext.createBufferSource();
            noiseSource.buffer = noiseBuffer;
            noiseSource.loop = true;

            const noiseGain = audioContext.createGain();
            noiseGain.gain.value = oscData.mix;

            noiseSource.connect(noiseGain);
            if (filterNode) {
              noiseGain.connect(filterNode);
            } else {
              noiseGain.connect(gainNode);
            }
            noiseSource.start();
          }
        } else if (oscData.waveform === "pulse") {
          // Create pulse wave oscillator
          const osc = createPulseOscillator(audioContext, freq, oscData.pulse_duty);
          osc.detune.value = oscData.detune_cents + (synth.detune_cents || 0);

          const oscGain = audioContext.createGain();
          oscGain.gain.value = oscData.mix;

          osc.connect(oscGain);
          if (filterNode) {
            oscGain.connect(filterNode);
          } else {
            oscGain.connect(gainNode);
          }
          osc.start();
          oscillators.push(osc);
        } else {
          // Standard waveforms
          const osc = audioContext.createOscillator();
          osc.type = oscData.waveform;
          osc.frequency.value = freq;
          osc.detune.value = oscData.detune_cents + (synth.detune_cents || 0);

          const oscGain = audioContext.createGain();
          oscGain.gain.value = oscData.mix;

          osc.connect(oscGain);
          if (filterNode) {
            oscGain.connect(filterNode);
          } else {
            oscGain.connect(gainNode);
          }
          osc.start();
          oscillators.push(osc);
        }
      }
    } else {
      // Default: single triangle oscillator
      const osc = audioContext.createOscillator();
      osc.type = "triangle";
      osc.frequency.value = baseFreq;
      osc.connect(gainNode);
      osc.start();
      oscillators.push(osc);
    }

    // Connect filter to gain if present
    if (filterNode) {
      filterNode.connect(gainNode);
    }

    // ADSR envelope
    const now = audioContext.currentTime;
    gainNode.gain.setValueAtTime(0, now);
    gainNode.gain.linearRampToValueAtTime(volume, now + adsr.attack);
    gainNode.gain.linearRampToValueAtTime(
      volume * adsr.sustain,
      now + adsr.attack + adsr.decay
    );

    // Pitch envelope (for drums like kicks - frequency sweeps from high to low)
    if (synth?.pitch_envelope) {
      const { start_hz, end_hz, time_seconds } = synth.pitch_envelope;
      for (const osc of oscillators) {
        // Override the frequency with pitch envelope
        osc.frequency.setValueAtTime(start_hz, now);
        osc.frequency.exponentialRampToValueAtTime(
          Math.max(end_hz, 0.01), // Prevent 0 or negative values for exponential ramp
          now + time_seconds
        );
      }
    }

    gainNode.connect(masterGain);

    activeVoices.set(voiceKey, { oscillators, noiseSource, gainNode, filterNode });
  };

  const noteOffByKey = (voiceKey: string) => {
    if (!audioContext) return;

    const voice = activeVoices.get(voiceKey);
    if (voice) {
      const { oscillators, noiseSource, gainNode, filterNode } = voice;
      const now = audioContext.currentTime;

      // Get release time from current gain envelope or use default
      const releaseTime = 0.1;

      // Fade out
      gainNode.gain.cancelScheduledValues(now);
      gainNode.gain.setValueAtTime(gainNode.gain.value, now);
      gainNode.gain.linearRampToValueAtTime(0, now + releaseTime);

      setTimeout(() => {
        for (const osc of oscillators) {
          osc.stop();
          osc.disconnect();
        }
        if (noiseSource) {
          noiseSource.stop();
          noiseSource.disconnect();
        }
        gainNode.disconnect();
        if (filterNode) {
          filterNode.disconnect();
        }
      }, releaseTime * 1000 + 50);

      activeVoices.delete(voiceKey);
    }
  };

  const noteOff = (midiNote: number, synthName?: string) => {
    noteOffByKey(getVoiceKey(midiNote, synthName));
  };

  const stopAll = () => {
    activeVoices.forEach((_, voiceKey) => noteOffByKey(voiceKey));
  };

  const playNotes = async (
    notes: AudioNoteEvent[],
    tempo: number,
    onBeatUpdate?: (beat: number) => void,
    signal?: AbortSignal
  ) => {
    await init();
    if (!audioContext) return;

    // Debug: log all notes with synth data
    console.log('[AudioSynth] playNotes called:', { noteCount: notes.length, tempo });
    console.log('[AudioSynth] first few notes:', notes.slice(0, 5));

    const beatsPerSecond = tempo / 60;
    const startTime = audioContext.currentTime;

    // Schedule all notes
    const scheduledEvents: Array<{
      time: number;
      type: "on" | "off";
      pitch: number;
      velocity: number;
      synth?: SynthData;
    }> = [];

    for (const note of notes) {
      const noteStartTime = note.start / beatsPerSecond;
      const noteEndTime = (note.start + note.duration) / beatsPerSecond;

      scheduledEvents.push({
        time: noteStartTime,
        type: "on",
        pitch: note.pitch,
        velocity: note.velocity,
        synth: note.synth,
      });
      scheduledEvents.push({
        time: noteEndTime,
        type: "off",
        pitch: note.pitch,
        velocity: 0,
        synth: note.synth,
      });
    }

    // Sort by time
    scheduledEvents.sort((a, b) => a.time - b.time);

    // Play events
    for (const event of scheduledEvents) {
      if (signal?.aborted) {
        stopAll();
        return;
      }

      const currentTime = audioContext.currentTime - startTime;
      const waitTime = event.time - currentTime;

      if (waitTime > 0) {
        await new Promise<void>((resolve, reject) => {
          const timeout = setTimeout(resolve, waitTime * 1000);
          signal?.addEventListener("abort", () => {
            clearTimeout(timeout);
            reject(new Error("Aborted"));
          });
        }).catch(() => {
          stopAll();
          return;
        });
      }

      if (signal?.aborted) {
        stopAll();
        return;
      }

      if (event.type === "on") {
        noteOn(event.pitch, event.velocity, event.synth);
      } else {
        noteOff(event.pitch, event.synth?.name);
      }

      // Update beat position
      if (onBeatUpdate) {
        const elapsed = audioContext.currentTime - startTime;
        onBeatUpdate(elapsed * beatsPerSecond);
      }
    }

    // Wait for last notes to finish
    await new Promise((resolve) => setTimeout(resolve, 200));
    stopAll();
  };

  const close = () => {
    stopAll();
    if (audioContext) {
      audioContext.close();
      audioContext = null;
      masterGain = null;
      noiseBuffer = null;
    }
    isInitialized.value = false;
  };

  return {
    isInitialized,
    init,
    noteOn,
    noteOff,
    stopAll,
    playNotes,
    close,
  };
}
