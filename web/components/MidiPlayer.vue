<script setup lang="ts">
import type { AudioNoteEvent } from "../types/relanote";
import { useAudioSynth } from "../composables/useAudioSynth";

const props = defineProps<{
  notes: AudioNoteEvent[];
  midiData: number[] | null;
  tempo: number;
  totalBeats: number;
}>();

const emit = defineEmits<{
  "update:currentBeat": [beat: number];
  exportMidi: [];
}>();

const { init, playNotes, stopAll, isInitialized } = useAudioSynth();

const isPlaying = ref(false);
const currentBeat = ref(0);
let abortController: AbortController | null = null;

const beatsPerSecond = computed(() => props.tempo / 60);

const formatTime = (beats: number) => {
  const seconds = beats / beatsPerSecond.value;
  const mins = Math.floor(seconds / 60);
  const secs = Math.floor(seconds % 60);
  return `${mins}:${secs.toString().padStart(2, "0")}`;
};

const progress = computed(() => {
  if (props.totalBeats <= 0) return 0;
  return (currentBeat.value / props.totalBeats) * 100;
});

const play = async () => {
  if (props.notes.length === 0) return;

  await init();

  isPlaying.value = true;
  abortController = new AbortController();

  try {
    await playNotes(
      props.notes,
      props.tempo,
      (beat) => {
        currentBeat.value = beat;
        emit("update:currentBeat", beat);
      },
      abortController.signal
    );
  } catch {
    // Aborted
  }

  isPlaying.value = false;
  currentBeat.value = 0;
  emit("update:currentBeat", 0);
};

const pause = () => {
  if (abortController) {
    abortController.abort();
    abortController = null;
  }
  stopAll();
  isPlaying.value = false;
};

const stop = () => {
  if (abortController) {
    abortController.abort();
    abortController = null;
  }
  stopAll();
  isPlaying.value = false;
  currentBeat.value = 0;
  emit("update:currentBeat", 0);
};

const seek = (event: MouseEvent) => {
  const target = event.currentTarget as HTMLElement;
  const rect = target.getBoundingClientRect();
  const ratio = Math.max(0, Math.min(1, (event.clientX - rect.left) / rect.width));
  currentBeat.value = ratio * props.totalBeats;
  emit("update:currentBeat", currentBeat.value);
};

onUnmounted(() => {
  stop();
});
</script>

<template>
  <div class="midi-player">
    <div class="player-controls">
      <button
        class="control-btn play-btn"
        @click="isPlaying ? pause() : play()"
        :disabled="notes.length === 0"
        :title="isPlaying ? 'Pause' : 'Play'"
      >
        <span v-if="isPlaying">⏸</span>
        <span v-else>▶</span>
      </button>
      <button
        class="control-btn"
        @click="stop"
        :disabled="notes.length === 0"
        title="Stop"
      >
        ⏹
      </button>
    </div>

    <div class="progress-container" @click="seek">
      <div class="progress-bar">
        <div class="progress-fill" :style="{ width: progress + '%' }" />
      </div>
    </div>

    <div class="time-display">
      {{ formatTime(currentBeat) }} / {{ formatTime(totalBeats) }}
    </div>

    <button
      class="export-btn"
      @click="$emit('exportMidi')"
      :disabled="!midiData"
      title="Export MIDI"
    >
      💾
    </button>
  </div>
</template>

<style scoped>
.midi-player {
  display: flex;
  align-items: center;
  gap: 12px;
  padding: 8px 12px;
  background: #252526;
  border-radius: 8px;
}

.player-controls {
  display: flex;
  gap: 4px;
}

.control-btn {
  width: 32px;
  height: 32px;
  display: flex;
  align-items: center;
  justify-content: center;
  background: #3c3c3c;
  border: none;
  border-radius: 4px;
  color: #cccccc;
  font-size: 14px;
  cursor: pointer;
  transition: background 0.15s;
}

.control-btn.play-btn {
  background: #0e639c;
}

.control-btn.play-btn:hover:not(:disabled) {
  background: #1177bb;
}

.control-btn:hover:not(:disabled) {
  background: #4c4c4c;
}

.control-btn:disabled {
  opacity: 0.5;
  cursor: not-allowed;
}

.progress-container {
  flex: 1;
  cursor: pointer;
  padding: 8px 0;
}

.progress-bar {
  height: 6px;
  background: #3c3c3c;
  border-radius: 3px;
  overflow: hidden;
}

.progress-fill {
  height: 100%;
  background: linear-gradient(90deg, #b45309, #d97706);
  transition: width 0.05s linear;
}

.time-display {
  color: #858585;
  font-size: 12px;
  font-family: monospace;
  min-width: 80px;
  text-align: center;
}

.export-btn {
  width: 32px;
  height: 32px;
  display: flex;
  align-items: center;
  justify-content: center;
  background: transparent;
  border: none;
  border-radius: 4px;
  color: #cccccc;
  font-size: 16px;
  cursor: pointer;
}

.export-btn:hover:not(:disabled) {
  background: #3c3c3c;
}

.export-btn:disabled {
  opacity: 0.5;
  cursor: not-allowed;
}
</style>
