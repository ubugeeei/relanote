import type { NoteEvent } from "../types/relanote";

interface Voice {
  oscillator: OscillatorNode;
  gainNode: GainNode;
}

export function useAudioSynth() {
  let audioContext: AudioContext | null = null;
  let masterGain: GainNode | null = null;
  const activeVoices = new Map<number, Voice>();

  const isInitialized = ref(false);

  const init = async () => {
    if (audioContext) return;

    audioContext = new AudioContext();
    masterGain = audioContext.createGain();
    masterGain.gain.value = 0.3;
    masterGain.connect(audioContext.destination);

    // Resume context if suspended (required by browsers)
    if (audioContext.state === "suspended") {
      await audioContext.resume();
    }

    isInitialized.value = true;
  };

  const midiToFrequency = (midiNote: number): number => {
    return 440 * Math.pow(2, (midiNote - 69) / 12);
  };

  const noteOn = (midiNote: number, velocity: number = 100) => {
    if (!audioContext || !masterGain) return;

    // Stop existing voice on same note
    noteOff(midiNote);

    const oscillator = audioContext.createOscillator();
    const gainNode = audioContext.createGain();

    // Use a warm sine-like tone (combination of sine and triangle)
    oscillator.type = "triangle";
    oscillator.frequency.value = midiToFrequency(midiNote);

    // Velocity-based volume with envelope
    const volume = (velocity / 127) * 0.5;
    gainNode.gain.setValueAtTime(0, audioContext.currentTime);
    gainNode.gain.linearRampToValueAtTime(volume, audioContext.currentTime + 0.02);

    oscillator.connect(gainNode);
    gainNode.connect(masterGain);
    oscillator.start();

    activeVoices.set(midiNote, { oscillator, gainNode });
  };

  const noteOff = (midiNote: number) => {
    if (!audioContext) return;

    const voice = activeVoices.get(midiNote);
    if (voice) {
      const { oscillator, gainNode } = voice;

      // Fade out to avoid clicks
      gainNode.gain.linearRampToValueAtTime(0, audioContext.currentTime + 0.1);

      setTimeout(() => {
        oscillator.stop();
        oscillator.disconnect();
        gainNode.disconnect();
      }, 150);

      activeVoices.delete(midiNote);
    }
  };

  const stopAll = () => {
    activeVoices.forEach((_, midiNote) => noteOff(midiNote));
  };

  const playNotes = async (
    notes: NoteEvent[],
    tempo: number,
    onBeatUpdate?: (beat: number) => void,
    signal?: AbortSignal
  ) => {
    await init();
    if (!audioContext) return;

    const beatsPerSecond = tempo / 60;
    const startTime = audioContext.currentTime;

    // Schedule all notes
    const scheduledEvents: Array<{
      time: number;
      type: "on" | "off";
      pitch: number;
      velocity: number;
    }> = [];

    for (const note of notes) {
      const noteStartTime = note.start / beatsPerSecond;
      const noteEndTime = (note.start + note.duration) / beatsPerSecond;

      scheduledEvents.push({
        time: noteStartTime,
        type: "on",
        pitch: note.pitch,
        velocity: note.velocity,
      });
      scheduledEvents.push({
        time: noteEndTime,
        type: "off",
        pitch: note.pitch,
        velocity: 0,
      });
    }

    // Sort by time
    scheduledEvents.sort((a, b) => a.time - b.time);

    // Find total duration
    const totalDuration = Math.max(...notes.map((n) => n.start + n.duration)) / beatsPerSecond;

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
        noteOn(event.pitch, event.velocity);
      } else {
        noteOff(event.pitch);
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
