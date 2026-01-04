<script setup lang="ts">
import type { TrackInfo } from "../../types/relanote";
import SynthSelector from "./SynthSelector.vue";

const props = defineProps<{
  tracks: TrackInfo[];
  selectedTrackId: string | null;
}>();

const emit = defineEmits<{
  selectTrack: [trackId: string];
  addTrack: [];
  deleteTrack: [trackId: string];
  toggleMute: [trackId: string];
  toggleSolo: [trackId: string];
  updateVolume: [trackId: string, volume: number];
  updateSynth: [trackId: string, synth: string];
  renameTrack: [trackId: string, name: string];
  previewSynth: [synth: string];
}>();

const editingTrackId = ref<string | null>(null);
const editingName = ref("");

const startRename = (track: TrackInfo) => {
  editingTrackId.value = track.id;
  editingName.value = track.name;
};

const finishRename = () => {
  if (editingTrackId.value && editingName.value.trim()) {
    emit("renameTrack", editingTrackId.value, editingName.value.trim());
  }
  editingTrackId.value = null;
};

const handleKeydown = (e: KeyboardEvent) => {
  if (e.key === "Enter") {
    finishRename();
  } else if (e.key === "Escape") {
    editingTrackId.value = null;
  }
};

const hasSoloTracks = computed(() => props.tracks.some((t) => t.solo));
</script>

<template>
  <div class="track-list">
    <div class="track-list-header">
      <span>Tracks</span>
      <button class="add-track-btn" @click="$emit('addTrack')" title="Add Track">
        <svg viewBox="0 0 24 24" fill="currentColor">
          <path d="M19 13h-6v6h-2v-6H5v-2h6V5h2v6h6v2z" />
        </svg>
      </button>
    </div>

    <div class="tracks">
      <div
        v-for="track in tracks"
        :key="track.id"
        class="track-item"
        :class="{
          selected: track.id === selectedTrackId,
          muted: track.muted || (hasSoloTracks && !track.solo),
        }"
        @click="$emit('selectTrack', track.id)"
      >
        <div class="track-color" :style="{ background: track.color }" />

        <div class="track-info">
          <input
            v-if="editingTrackId === track.id"
            v-model="editingName"
            class="track-name-input"
            @blur="finishRename"
            @keydown="handleKeydown"
            @click.stop
            ref="nameInput"
            autofocus
          />
          <span
            v-else
            class="track-name"
            @dblclick.stop="startRename(track)"
          >
            {{ track.name }}
          </span>
          <div class="track-synth-row" @click.stop>
            <SynthSelector
              :selected-synth="track.synth"
              @update:selected-synth="(synth) => $emit('updateSynth', track.id, synth)"
              @preview="(synth) => $emit('previewSynth', synth)"
            />
          </div>
        </div>

        <div class="track-controls" @click.stop>
          <button
            class="track-btn"
            :class="{ active: track.solo }"
            @click="$emit('toggleSolo', track.id)"
            title="Solo"
          >
            S
          </button>
          <button
            class="track-btn"
            :class="{ active: track.muted }"
            @click="$emit('toggleMute', track.id)"
            title="Mute"
          >
            M
          </button>
        </div>

        <button
          class="delete-btn"
          @click.stop="$emit('deleteTrack', track.id)"
          :disabled="tracks.length <= 1"
          title="Delete Track"
        >
          <svg viewBox="0 0 24 24" fill="currentColor">
            <path d="M19 6.41L17.59 5 12 10.59 6.41 5 5 6.41 10.59 12 5 17.59 6.41 19 12 13.41 17.59 19 19 17.59 13.41 12 19 6.41z" />
          </svg>
        </button>
      </div>
    </div>
  </div>
</template>

<style scoped>
.track-list {
  display: flex;
  flex-direction: column;
  height: 100%;
  background: #252526;
  border-right: 1px solid #3c3c3c;
  min-width: 200px;
}

.track-list-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 8px 12px;
  border-bottom: 1px solid #3c3c3c;
  font-size: 12px;
  font-weight: 500;
  color: #cccccc;
}

.add-track-btn {
  width: 24px;
  height: 24px;
  display: flex;
  align-items: center;
  justify-content: center;
  background: transparent;
  border: none;
  border-radius: 4px;
  color: #858585;
  cursor: pointer;
}

.add-track-btn:hover {
  background: #3c3c3c;
  color: #cccccc;
}

.add-track-btn svg {
  width: 16px;
  height: 16px;
}

.tracks {
  flex: 1;
  overflow-y: auto;
}

.track-item {
  display: flex;
  align-items: center;
  gap: 8px;
  padding: 8px 12px;
  cursor: pointer;
  transition: background 0.15s;
  border-bottom: 1px solid #2d2d2d;
}

.track-item:hover {
  background: #2a2a2a;
}

.track-item.selected {
  background: #37373d;
}

.track-item.muted {
  opacity: 0.5;
}

.track-color {
  width: 4px;
  height: 32px;
  border-radius: 2px;
  flex-shrink: 0;
}

.track-info {
  flex: 1;
  min-width: 0;
  display: flex;
  flex-direction: column;
  gap: 2px;
}

.track-name {
  font-size: 13px;
  color: #cccccc;
  white-space: nowrap;
  overflow: hidden;
  text-overflow: ellipsis;
}

.track-name-input {
  width: 100%;
  padding: 2px 4px;
  background: #3c3c3c;
  border: 1px solid #0e639c;
  border-radius: 2px;
  color: #cccccc;
  font-size: 13px;
}

.track-name-input:focus {
  outline: none;
}

.track-synth-row {
  margin-top: 2px;
}

.track-controls {
  display: flex;
  gap: 2px;
}

.track-btn {
  width: 20px;
  height: 20px;
  display: flex;
  align-items: center;
  justify-content: center;
  background: #3c3c3c;
  border: none;
  border-radius: 2px;
  color: #858585;
  font-size: 10px;
  font-weight: 600;
  cursor: pointer;
}

.track-btn:hover {
  background: #4c4c4c;
  color: #cccccc;
}

.track-btn.active {
  background: #d97706;
  color: white;
}

.delete-btn {
  width: 20px;
  height: 20px;
  display: flex;
  align-items: center;
  justify-content: center;
  background: transparent;
  border: none;
  border-radius: 2px;
  color: #666666;
  cursor: pointer;
  opacity: 0;
  transition: opacity 0.15s;
}

.track-item:hover .delete-btn {
  opacity: 1;
}

.delete-btn:hover:not(:disabled) {
  color: #f14c4c;
}

.delete-btn:disabled {
  cursor: not-allowed;
  opacity: 0.3;
}

.delete-btn svg {
  width: 12px;
  height: 12px;
}
</style>
