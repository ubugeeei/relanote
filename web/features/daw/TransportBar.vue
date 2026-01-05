<script setup lang="ts">
const props = defineProps<{
  isPlaying: boolean;
  isPaused: boolean;
  tempo: number;
  playheadPosition: number;
  totalBeats: number;
  loopEnabled: boolean;
}>();

const emit = defineEmits<{
  play: [];
  pause: [];
  stop: [];
  skipBack: [];
  skipForward: [];
  "update:tempo": [tempo: number];
  toggleLoop: [];
}>();

const beatsPerSecond = computed(() => props.tempo / 60);

const formatTime = (beats: number): string => {
  const seconds = beats / beatsPerSecond.value;
  const mins = Math.floor(seconds / 60);
  const secs = Math.floor(seconds % 60);
  return `${mins}:${secs.toString().padStart(2, "0")}`;
};

const formatBeats = (beats: number): string => {
  const bar = Math.floor(beats / 4) + 1;
  const beat = Math.floor(beats % 4) + 1;
  return `${bar}.${beat}`;
};

const progress = computed(() => {
  if (props.totalBeats <= 0) return 0;
  return (props.playheadPosition / props.totalBeats) * 100;
});

const handleTempoChange = (e: Event) => {
  const value = parseInt((e.target as HTMLInputElement).value);
  if (!isNaN(value)) {
    emit("update:tempo", value);
  }
};

const handleTempoBlur = (e: FocusEvent) => {
  const value = parseInt((e.target as HTMLInputElement).value);
  if (isNaN(value) || value < 20) {
    emit("update:tempo", 20);
  } else if (value > 300) {
    emit("update:tempo", 300);
  }
};
</script>

<template>
  <div class="transport-bar">
    <div class="transport-controls">
      <button
        class="transport-btn"
        @click="$emit('skipBack')"
        title="Skip Back"
      >
        <svg viewBox="0 0 24 24" fill="currentColor">
          <path d="M6 6h2v12H6V6zm3.5 6l8.5 6V6l-8.5 6z" />
        </svg>
      </button>

      <button
        class="transport-btn play-btn"
        @click="() => { console.log('[DEBUG] Play button clicked, isPlaying:', isPlaying); isPlaying ? $emit('pause') : $emit('play'); }"
        :title="isPlaying ? 'Pause' : 'Play'"
      >
        <svg v-if="isPlaying" viewBox="0 0 24 24" fill="currentColor">
          <path d="M6 4h4v16H6V4zm8 0h4v16h-4V4z" />
        </svg>
        <svg v-else viewBox="0 0 24 24" fill="currentColor">
          <path d="M8 5v14l11-7L8 5z" />
        </svg>
      </button>

      <button
        class="transport-btn"
        @click="$emit('stop')"
        title="Stop"
      >
        <svg viewBox="0 0 24 24" fill="currentColor">
          <path d="M6 6h12v12H6V6z" />
        </svg>
      </button>

      <button
        class="transport-btn"
        @click="$emit('skipForward')"
        title="Skip Forward"
      >
        <svg viewBox="0 0 24 24" fill="currentColor">
          <path d="M6 18l8.5-6L6 6v12zm2-12v12l6.5-6L8 6zm8 0v12h2V6h-2z" />
        </svg>
      </button>
    </div>

    <div class="transport-time">
      <div class="time-display">
        <span class="time-label">Time</span>
        <span class="time-value">{{ formatTime(playheadPosition) }}</span>
      </div>
      <div class="time-display">
        <span class="time-label">Bar</span>
        <span class="time-value">{{ formatBeats(playheadPosition) }}</span>
      </div>
    </div>

    <div class="progress-section">
      <div class="progress-bar">
        <div class="progress-fill" :style="{ width: progress + '%' }" />
      </div>
    </div>

    <div class="tempo-section">
      <span class="tempo-label">BPM</span>
      <input
        type="number"
        class="tempo-input"
        :value="tempo"
        min="20"
        max="300"
        @input="handleTempoChange"
        @blur="handleTempoBlur"
      />
    </div>

    <button
      class="transport-btn loop-btn"
      :class="{ active: loopEnabled }"
      @click="$emit('toggleLoop')"
      title="Loop"
    >
      <svg viewBox="0 0 24 24" fill="currentColor">
        <path d="M12 4V1L8 5l4 4V6c3.31 0 6 2.69 6 6 0 1.01-.25 1.97-.7 2.8l1.46 1.46C19.54 15.03 20 13.57 20 12c0-4.42-3.58-8-8-8zm0 14c-3.31 0-6-2.69-6-6 0-1.01.25-1.97.7-2.8L5.24 7.74C4.46 8.97 4 10.43 4 12c0 4.42 3.58 8 8 8v3l4-4-4-4v3z" />
      </svg>
    </button>
  </div>
</template>

<style scoped>
.transport-bar {
  display: flex;
  align-items: center;
  gap: 16px;
  padding: 8px 16px;
  background: #252526;
  border-bottom: 1px solid #3c3c3c;
}

.transport-controls {
  display: flex;
  gap: 4px;
}

.transport-btn {
  width: 32px;
  height: 32px;
  display: flex;
  align-items: center;
  justify-content: center;
  background: #3c3c3c;
  border: none;
  border-radius: 4px;
  color: #cccccc;
  cursor: pointer;
  transition: all 0.15s;
}

.transport-btn:hover {
  background: #4c4c4c;
}

.transport-btn svg {
  width: 18px;
  height: 18px;
}

.transport-btn.play-btn {
  background: #0e639c;
}

.transport-btn.play-btn:hover {
  background: #1177bb;
}

.transport-btn.loop-btn.active {
  background: #d97706;
  color: white;
}

.transport-time {
  display: flex;
  gap: 16px;
}

.time-display {
  display: flex;
  flex-direction: column;
  align-items: center;
  min-width: 60px;
}

.time-label {
  font-size: 10px;
  color: #666666;
  text-transform: uppercase;
}

.time-value {
  font-size: 14px;
  font-family: monospace;
  color: #cccccc;
}

.progress-section {
  flex: 1;
  min-width: 200px;
  padding: 0 16px;
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

.tempo-section {
  display: flex;
  align-items: center;
  gap: 8px;
}

.tempo-label {
  font-size: 11px;
  color: #666666;
  text-transform: uppercase;
}

.tempo-input {
  width: 60px;
  height: 28px;
  padding: 0 8px;
  background: #3c3c3c;
  border: 1px solid #4c4c4c;
  border-radius: 4px;
  color: #cccccc;
  font-size: 13px;
  font-family: monospace;
  text-align: center;
}

.tempo-input:focus {
  outline: none;
  border-color: #0e639c;
}

.tempo-input::-webkit-inner-spin-button,
.tempo-input::-webkit-outer-spin-button {
  -webkit-appearance: none;
  margin: 0;
}
</style>
