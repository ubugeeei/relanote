<script setup lang="ts">
import type { PianoRollNote, AudioNoteEvent } from "../../types/relanote";
import { useAudioSynth } from "../../composables/useAudioSynth";
import { useDawState } from "./useDawState";
import PianoRoll from "./PianoRoll.vue";
import TransportBar from "./TransportBar.vue";
import Toolbar from "./Toolbar.vue";
import TrackList from "./TrackList.vue";
import MixerPanel from "./MixerPanel.vue";

const props = defineProps<{
  code: string;
  audioData: { notes: AudioNoteEvent[]; tempo: number; total_beats: number } | null;
}>();

const emit = defineEmits<{
  "update:code": [code: string];
}>();

const { notesToCode } = useRelanote();

const {
  state,
  isPlaying,
  isPaused,
  selectedTrack,
  totalBeats,
  masterVolume,
  addTrack,
  deleteTrack,
  selectTrack,
  updateTrack,
  toggleMute,
  toggleSolo,
  updateSynth,
  updateVolume,
  updatePan,
  setMasterVolume,
  updateNotes,
  setTool,
  gridSnapOptions,
  setGridSnap,
  zoomIn,
  zoomOut,
  play,
  pause,
  stop,
  setPlayheadPosition,
  setTempo,
  toggleLoop,
} = useDawState();

const { init, noteOn, playNotes, stopAll } = useAudioSynth();

// Mixer panel visibility
const showMixer = ref(true);

// Sync direction tracking to prevent infinite loops
const syncFromCode = ref(false);
const syncDebounce = ref<ReturnType<typeof setTimeout> | null>(null);

// Note preview when clicking piano keys or drawing
const handleNotePreview = async (pitch: number) => {
  await init();
  noteOn(pitch, 100);
};

const handleNotePreviewStop = () => {
  stopAll();
};

// Handle scroll update
const handleScrollUpdate = (scroll: { x: number; y: number }) => {
  state.scroll = scroll;
};

// Handle notes update from piano roll -> sync to code
const handleNotesUpdate = (notes: PianoRollNote[]) => {
  updateNotes(notes);

  // Debounced sync to code
  if (syncDebounce.value) {
    clearTimeout(syncDebounce.value);
  }

  syncDebounce.value = setTimeout(() => {
    if (selectedTrack.value) {
      const code = notesToCode(notes, selectedTrack.value.synth, 60);
      if (code) {
        emit("update:code", code);
      }
    }
  }, 500);
};

// Sync from code -> piano roll when audioData changes
watch(
  () => props.audioData,
  (newData) => {
    if (!newData || newData.notes.length === 0) return;

    // Convert AudioNoteEvent[] to PianoRollNote[]
    const pianoRollNotes: PianoRollNote[] = newData.notes.map((n, i) => ({
      id: `code-${i}-${n.start}-${n.pitch}`,
      pitch: n.pitch,
      start: n.start,
      duration: n.duration,
      velocity: n.velocity,
      selected: false,
    }));

    // Update tempo from code
    if (newData.tempo && newData.tempo !== state.tempo) {
      setTempo(newData.tempo);
    }

    // Only update if different (to prevent infinite loops)
    if (selectedTrack.value) {
      const currentNotes = selectedTrack.value.notes;
      const isDifferent =
        pianoRollNotes.length !== currentNotes.length ||
        pianoRollNotes.some(
          (n, i) =>
            !currentNotes[i] ||
            n.pitch !== currentNotes[i].pitch ||
            Math.abs(n.start - currentNotes[i].start) > 0.001 ||
            Math.abs(n.duration - currentNotes[i].duration) > 0.001
        );

      if (isDifferent) {
        syncFromCode.value = true;
        updateNotes(pianoRollNotes);
        nextTick(() => {
          syncFromCode.value = false;
        });
      }
    }
  },
  { deep: true }
);

// Playback
let playbackAbortController: AbortController | null = null;

const handlePlay = async () => {
  await init();
  play();

  playbackAbortController = new AbortController();

  // Use audioData from props which includes synth information
  const notes: AudioNoteEvent[] = props.audioData?.notes || [];

  try {
    await playNotes(
      notes,
      state.tempo,
      (beat) => setPlayheadPosition(beat),
      playbackAbortController.signal
    );
  } catch {
    // Aborted
  }

  stop();
};

const handlePause = () => {
  if (playbackAbortController) {
    playbackAbortController.abort();
    playbackAbortController = null;
  }
  stopAll();
  pause();
};

const handleStop = () => {
  if (playbackAbortController) {
    playbackAbortController.abort();
    playbackAbortController = null;
  }
  stopAll();
  stop();
};

const handleSkipBack = () => {
  setPlayheadPosition(0);
};

const handleSkipForward = () => {
  setPlayheadPosition(totalBeats.value);
};

// Handle track rename
const handleRenameTrack = (trackId: string, name: string) => {
  updateTrack(trackId, { name });
};

// Handle synth preview
const handlePreviewSynth = async (synth: string) => {
  await init();
  // Play a short note with the synth
  noteOn(60, 100); // C4
  setTimeout(() => stopAll(), 300);
};

// Keyboard shortcuts
const handleKeydown = (e: KeyboardEvent) => {
  const target = e.target as HTMLElement;

  // Ignore if typing in input, textarea, or contenteditable
  if (
    target.tagName === "INPUT" ||
    target.tagName === "TEXTAREA" ||
    target.isContentEditable ||
    target.closest(".monaco-editor")
  ) {
    return;
  }

  if (e.code === "Space") {
    e.preventDefault();
    if (isPlaying.value) {
      handlePause();
    } else {
      handlePlay();
    }
  } else if (e.code === "KeyV") {
    setTool("select");
  } else if (e.code === "KeyD") {
    setTool("draw");
  } else if (e.code === "KeyE") {
    setTool("erase");
  }
};

onMounted(() => {
  window.addEventListener("keydown", handleKeydown);
});

onUnmounted(() => {
  window.removeEventListener("keydown", handleKeydown);
  handleStop();
});
</script>

<template>
  <div class="daw-view">
    <TransportBar
      :is-playing="isPlaying"
      :is-paused="isPaused"
      :tempo="state.tempo"
      :playhead-position="state.playheadPosition"
      :total-beats="totalBeats"
      :loop-enabled="state.loop.enabled"
      @play="handlePlay"
      @pause="handlePause"
      @stop="handleStop"
      @skip-back="handleSkipBack"
      @skip-forward="handleSkipForward"
      @update:tempo="setTempo"
      @toggle-loop="toggleLoop"
    />

    <Toolbar
      :tool="state.tool"
      :grid-snap="state.gridSnap"
      :grid-snap-options="gridSnapOptions"
      @update:tool="setTool"
      @update:grid-snap="setGridSnap"
      @zoom-in="zoomIn"
      @zoom-out="zoomOut"
    />

    <div class="daw-main">
      <TrackList
        :tracks="state.tracks"
        :selected-track-id="state.selectedTrackId"
        @select-track="selectTrack"
        @add-track="addTrack"
        @delete-track="deleteTrack"
        @toggle-mute="toggleMute"
        @toggle-solo="toggleSolo"
        @update-synth="updateSynth"
        @preview-synth="handlePreviewSynth"
        @rename-track="handleRenameTrack"
      />

      <div class="daw-content">
        <div class="piano-roll-wrapper">
          <PianoRoll
            v-if="selectedTrack"
            :notes="selectedTrack.notes"
            :grid-snap="state.gridSnap"
            :zoom="state.zoom"
            :scroll="state.scroll"
            :tool="state.tool"
            :playhead-position="state.playheadPosition"
            :total-beats="totalBeats"
            :is-playing="isPlaying"
            @update:notes="handleNotesUpdate"
            @update:scroll="handleScrollUpdate"
            @note-preview="handleNotePreview"
            @note-preview-stop="handleNotePreviewStop"
          />
          <div v-else class="no-track-message">
            No track selected
          </div>
        </div>

        <MixerPanel
          v-if="showMixer"
          :tracks="state.tracks"
          :master-volume="masterVolume"
          @update:track-volume="updateVolume"
          @update:track-pan="updatePan"
          @update:master-volume="setMasterVolume"
        />
      </div>
    </div>
  </div>
</template>

<style scoped>
.daw-view {
  display: flex;
  flex-direction: column;
  height: 100%;
  background: #1e1e1e;
}

.daw-main {
  flex: 1;
  display: flex;
  overflow: hidden;
}

.daw-content {
  flex: 1;
  display: flex;
  flex-direction: column;
  overflow: hidden;
}

.piano-roll-wrapper {
  flex: 1;
  min-height: 0;
  padding: 8px;
}

.no-track-message {
  display: flex;
  align-items: center;
  justify-content: center;
  height: 100%;
  color: #666666;
  font-size: 14px;
}
</style>
