<script setup lang="ts">
import type { TrackInfo } from "../../types/relanote";

const props = defineProps<{
  tracks: TrackInfo[];
  masterVolume: number;
}>();

const emit = defineEmits<{
  "update:trackVolume": [trackId: string, volume: number];
  "update:trackPan": [trackId: string, pan: number];
  "update:masterVolume": [volume: number];
}>();

const formatDb = (value: number): string => {
  if (value <= 0) return "-∞";
  const db = 20 * Math.log10(value);
  return db >= 0 ? `+${db.toFixed(1)}` : db.toFixed(1);
};

const volumeToDb = (volume: number): number => {
  if (volume <= 0) return -60;
  return Math.max(-60, Math.min(6, 20 * Math.log10(volume)));
};

const dbToVolume = (db: number): number => {
  if (db <= -60) return 0;
  return Math.pow(10, db / 20);
};
</script>

<template>
  <div class="mixer-panel">
    <div class="mixer-header">
      <span>Mixer</span>
    </div>

    <div class="mixer-channels">
      <div
        v-for="track in tracks"
        :key="track.id"
        class="channel"
        :style="{ '--track-color': track.color }"
      >
        <div class="channel-label">{{ track.name }}</div>

        <div class="fader-section">
          <div class="meter">
            <div class="meter-fill" :style="{ height: `${track.volume * 100}%` }" />
          </div>

          <input
            type="range"
            class="fader"
            :value="volumeToDb(track.volume)"
            min="-60"
            max="6"
            step="0.5"
            orient="vertical"
            @input="$emit('update:trackVolume', track.id, dbToVolume(parseFloat(($event.target as HTMLInputElement).value)))"
          />
        </div>

        <div class="db-display">{{ formatDb(track.volume) }} dB</div>

        <div class="pan-section">
          <label class="pan-label">Pan</label>
          <input
            type="range"
            class="pan-knob"
            :value="track.pan"
            min="-1"
            max="1"
            step="0.01"
            @input="$emit('update:trackPan', track.id, parseFloat(($event.target as HTMLInputElement).value))"
          />
          <span class="pan-value">{{ track.pan === 0 ? 'C' : track.pan < 0 ? `L${Math.round(Math.abs(track.pan) * 100)}` : `R${Math.round(track.pan * 100)}` }}</span>
        </div>
      </div>

      <div class="channel master">
        <div class="channel-label">Master</div>

        <div class="fader-section">
          <div class="meter">
            <div class="meter-fill master" :style="{ height: `${masterVolume * 100}%` }" />
          </div>

          <input
            type="range"
            class="fader"
            :value="volumeToDb(masterVolume)"
            min="-60"
            max="6"
            step="0.5"
            orient="vertical"
            @input="$emit('update:masterVolume', dbToVolume(parseFloat(($event.target as HTMLInputElement).value)))"
          />
        </div>

        <div class="db-display">{{ formatDb(masterVolume) }} dB</div>
      </div>
    </div>
  </div>
</template>

<style scoped>
.mixer-panel {
  display: flex;
  flex-direction: column;
  background: #1e1e1e;
  border-top: 1px solid #3c3c3c;
  height: 180px;
}

.mixer-header {
  display: flex;
  align-items: center;
  padding: 6px 12px;
  border-bottom: 1px solid #3c3c3c;
  font-size: 12px;
  font-weight: 500;
  color: #cccccc;
  background: #252526;
}

.mixer-channels {
  flex: 1;
  display: flex;
  gap: 1px;
  padding: 8px;
  overflow-x: auto;
}

.channel {
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 4px;
  padding: 8px;
  min-width: 60px;
  background: #252526;
  border-radius: 4px;
}

.channel.master {
  background: #2d2d2d;
  border: 1px solid #3c3c3c;
}

.channel-label {
  font-size: 10px;
  color: #cccccc;
  text-align: center;
  white-space: nowrap;
  overflow: hidden;
  text-overflow: ellipsis;
  max-width: 60px;
  border-bottom: 2px solid var(--track-color, #d97706);
  padding-bottom: 2px;
}

.channel.master .channel-label {
  border-bottom-color: #0e639c;
}

.fader-section {
  display: flex;
  gap: 4px;
  height: 80px;
  align-items: stretch;
}

.meter {
  width: 8px;
  height: 100%;
  background: #1e1e1e;
  border-radius: 2px;
  overflow: hidden;
  display: flex;
  flex-direction: column-reverse;
}

.meter-fill {
  background: linear-gradient(to top, #4caf50 0%, #8bc34a 60%, #ffeb3b 80%, #f44336 100%);
  transition: height 0.1s;
}

.meter-fill.master {
  background: linear-gradient(to top, #0e639c 0%, #3794ff 60%, #ffeb3b 80%, #f44336 100%);
}

.fader {
  writing-mode: vertical-lr;
  direction: rtl;
  width: 20px;
  height: 100%;
  appearance: none;
  background: #3c3c3c;
  border-radius: 2px;
  cursor: pointer;
}

.fader::-webkit-slider-thumb {
  appearance: none;
  width: 20px;
  height: 8px;
  background: #cccccc;
  border-radius: 2px;
  cursor: grab;
}

.fader::-webkit-slider-thumb:hover {
  background: #ffffff;
}

.fader::-webkit-slider-thumb:active {
  cursor: grabbing;
}

.db-display {
  font-size: 9px;
  color: #858585;
  text-align: center;
  font-family: monospace;
}

.pan-section {
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 2px;
}

.pan-label {
  font-size: 9px;
  color: #666666;
}

.pan-knob {
  width: 40px;
  height: 8px;
  appearance: none;
  background: #3c3c3c;
  border-radius: 4px;
  cursor: pointer;
}

.pan-knob::-webkit-slider-thumb {
  appearance: none;
  width: 8px;
  height: 12px;
  background: #858585;
  border-radius: 2px;
  cursor: grab;
}

.pan-knob::-webkit-slider-thumb:hover {
  background: #cccccc;
}

.pan-value {
  font-size: 9px;
  color: #858585;
  font-family: monospace;
}
</style>
