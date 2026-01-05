import type { DawState, TrackInfo, PianoRollNote, ViewMode } from "../../types/relanote";

const TRACK_COLORS = [
  "#d97706", // amber
  "#0891b2", // cyan
  "#7c3aed", // violet
  "#db2777", // pink
  "#059669", // emerald
  "#ea580c", // orange
  "#4f46e5", // indigo
  "#be123c", // rose
];

const generateId = (): string => {
  return `${Date.now()}-${Math.random().toString(36).substring(2, 9)}`;
};

const createDefaultTrack = (index: number): TrackInfo => ({
  id: generateId(),
  name: `Track ${index + 1}`,
  synth: "Lead",
  notes: [],
  muted: false,
  solo: false,
  volume: 0.8,
  pan: 0,
  color: TRACK_COLORS[index % TRACK_COLORS.length],
});

export function useDawState() {
  // View mode
  const viewMode = ref<ViewMode>("pianoroll");

  // DAW state
  const state = reactive<DawState>({
    tracks: [createDefaultTrack(0)],
    selectedTrackId: null,
    tempo: 120,
    timeSignatureNum: 4,
    timeSignatureDen: 4,
    gridSnap: 0.25, // 1/4 beat = 16th note
    zoom: { x: 1, y: 1 },
    scroll: { x: 0, y: 0 },
    tool: "select",
    loop: { enabled: false, start: 0, end: 16 },
    playheadPosition: 0,
  });

  // Playback state
  const isPlaying = ref(false);
  const isPaused = ref(false);

  // Selected track
  const selectedTrack = computed(() => {
    if (!state.selectedTrackId) {
      return state.tracks[0] || null;
    }
    return state.tracks.find((t) => t.id === state.selectedTrackId) || null;
  });

  // Total beats (max end time of all notes)
  const totalBeats = computed(() => {
    let max = 16; // minimum 4 bars
    for (const track of state.tracks) {
      for (const note of track.notes) {
        const end = note.start + note.duration;
        if (end > max) max = end;
      }
    }
    // Round up to next bar
    return Math.ceil(max / 4) * 4;
  });

  // Track management
  const addTrack = () => {
    const newTrack = createDefaultTrack(state.tracks.length);
    state.tracks.push(newTrack);
    state.selectedTrackId = newTrack.id;
  };

  const deleteTrack = (trackId: string) => {
    const index = state.tracks.findIndex((t) => t.id === trackId);
    if (index === -1) return;

    state.tracks.splice(index, 1);

    // Select another track if needed
    if (state.selectedTrackId === trackId) {
      state.selectedTrackId = state.tracks[Math.max(0, index - 1)]?.id || null;
    }

    // Ensure at least one track exists
    if (state.tracks.length === 0) {
      addTrack();
    }
  };

  const selectTrack = (trackId: string) => {
    state.selectedTrackId = trackId;
  };

  const updateTrack = (trackId: string, updates: Partial<TrackInfo>) => {
    const track = state.tracks.find((t) => t.id === trackId);
    if (track) {
      Object.assign(track, updates);
    }
  };

  const toggleMute = (trackId: string) => {
    const track = state.tracks.find((t) => t.id === trackId);
    if (track) {
      track.muted = !track.muted;
    }
  };

  const toggleSolo = (trackId: string) => {
    const track = state.tracks.find((t) => t.id === trackId);
    if (track) {
      track.solo = !track.solo;
    }
  };

  const updateSynth = (trackId: string, synth: string) => {
    const track = state.tracks.find((t) => t.id === trackId);
    if (track) {
      track.synth = synth;
    }
  };

  const updateVolume = (trackId: string, volume: number) => {
    const track = state.tracks.find((t) => t.id === trackId);
    if (track) {
      track.volume = Math.max(0, Math.min(2, volume));
    }
  };

  const updatePan = (trackId: string, pan: number) => {
    const track = state.tracks.find((t) => t.id === trackId);
    if (track) {
      track.pan = Math.max(-1, Math.min(1, pan));
    }
  };

  // Master volume
  const masterVolume = ref(1);

  const setMasterVolume = (volume: number) => {
    masterVolume.value = Math.max(0, Math.min(2, volume));
  };

  // Note management for selected track
  const updateNotes = (notes: PianoRollNote[]) => {
    if (selectedTrack.value) {
      selectedTrack.value.notes = notes;
    }
  };

  // Tool management
  const setTool = (tool: "select" | "draw" | "erase") => {
    state.tool = tool;
  };

  // Grid snap options
  const gridSnapOptions = [
    { label: "1 Bar", value: 4 },
    { label: "1/2", value: 2 },
    { label: "1/4", value: 1 },
    { label: "1/8", value: 0.5 },
    { label: "1/16", value: 0.25 },
    { label: "1/32", value: 0.125 },
  ];

  const setGridSnap = (snap: number) => {
    state.gridSnap = snap;
  };

  // Zoom
  const zoomIn = () => {
    state.zoom.x = Math.min(4, state.zoom.x * 1.2);
    state.zoom.y = Math.min(4, state.zoom.y * 1.2);
  };

  const zoomOut = () => {
    state.zoom.x = Math.max(0.25, state.zoom.x / 1.2);
    state.zoom.y = Math.max(0.25, state.zoom.y / 1.2);
  };

  // Playback
  const play = () => {
    isPlaying.value = true;
    isPaused.value = false;
  };

  const pause = () => {
    isPlaying.value = false;
    isPaused.value = true;
  };

  const stop = () => {
    isPlaying.value = false;
    isPaused.value = false;
    state.playheadPosition = 0;
  };

  const setPlayheadPosition = (position: number) => {
    state.playheadPosition = position;
  };

  // Tempo
  const setTempo = (tempo: number) => {
    state.tempo = Math.max(20, tempo);
  };

  // Loop
  const toggleLoop = () => {
    state.loop.enabled = !state.loop.enabled;
  };

  const setLoopRange = (start: number, end: number) => {
    state.loop.start = start;
    state.loop.end = end;
  };

  // View mode
  const toggleViewMode = () => {
    viewMode.value = viewMode.value === "pianoroll" ? "code" : "pianoroll";
  };

  // Initialize - select first track
  if (state.tracks.length > 0 && !state.selectedTrackId) {
    state.selectedTrackId = state.tracks[0].id;
  }

  return {
    // State
    state,
    viewMode,
    isPlaying,
    isPaused,
    selectedTrack,
    totalBeats,
    masterVolume,

    // Track management
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

    // Note management
    updateNotes,

    // Tool
    setTool,

    // Grid
    gridSnapOptions,
    setGridSnap,

    // Zoom
    zoomIn,
    zoomOut,

    // Playback
    play,
    pause,
    stop,
    setPlayheadPosition,

    // Tempo
    setTempo,

    // Loop
    toggleLoop,
    setLoopRange,

    // View
    toggleViewMode,
  };
}
