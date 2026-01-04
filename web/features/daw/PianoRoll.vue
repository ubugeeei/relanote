<script setup lang="ts">
import type { PianoRollNote } from "../../types/relanote";

const props = defineProps<{
  notes: PianoRollNote[];
  gridSnap: number;
  zoom: { x: number; y: number };
  scroll: { x: number; y: number };
  tool: "select" | "draw" | "erase";
  playheadPosition: number;
  totalBeats: number;
  isPlaying: boolean;
}>();

const emit = defineEmits<{
  "update:notes": [notes: PianoRollNote[]];
  "update:scroll": [scroll: { x: number; y: number }];
  notePreview: [pitch: number];
  notePreviewStop: [];
}>();

// Constants
const NOTE_HEIGHT = 16;
const BEAT_WIDTH = 60;
const KEY_WIDTH = 48;
const MIN_PITCH = 24; // C1
const MAX_PITCH = 108; // C8

// Refs
const containerRef = ref<HTMLElement | null>(null);
const canvasRef = ref<HTMLCanvasElement | null>(null);
const keysCanvasRef = ref<HTMLCanvasElement | null>(null);
const ctx = ref<CanvasRenderingContext2D | null>(null);
const keysCtx = ref<CanvasRenderingContext2D | null>(null);

// Interaction state
const isDragging = ref(false);
const isResizing = ref(false);
const isPanning = ref(false);
const dragStart = ref({ x: 0, y: 0 });
const dragNote = ref<PianoRollNote | null>(null);
const resizeEdge = ref<"left" | "right" | null>(null);
const selectionBox = ref<{ x1: number; y1: number; x2: number; y2: number } | null>(null);
const hoveredNote = ref<PianoRollNote | null>(null);
const ghostNote = ref<{ pitch: number; start: number; duration: number } | null>(null);

// Dimensions
const canvasWidth = ref(800);
const canvasHeight = ref(400);

// Colors
const colors = {
  bg: "#1e1e1e",
  gridLine: "#2d2d2d",
  beatLine: "#3c3c3c",
  barLine: "#4c4c4c",
  whiteKey: "#2a2a2a",
  blackKey: "#1a1a1a",
  keyLabel: "#666666",
  note: "#d97706",
  noteSelected: "#f59e0b",
  noteHover: "#fbbf24",
  noteBorder: "#92400e",
  playhead: "#ef4444",
  ghost: "rgba(217, 119, 6, 0.4)",
  selection: "rgba(59, 130, 246, 0.3)",
};

// Note names
const noteNames = ["C", "C#", "D", "D#", "E", "F", "F#", "G", "G#", "A", "A#", "B"];

const isBlackKey = (pitch: number): boolean => {
  const note = pitch % 12;
  return [1, 3, 6, 8, 10].includes(note);
};

const pitchToNoteName = (pitch: number): string => {
  const note = pitch % 12;
  const octave = Math.floor(pitch / 12) - 1;
  return `${noteNames[note]}${octave}`;
};

const effectiveZoom = computed(() => ({
  x: props.zoom.x * (BEAT_WIDTH / 60),
  y: props.zoom.y * (NOTE_HEIGHT / 16),
}));

const visibleBeats = computed(() => Math.ceil(canvasWidth.value / (BEAT_WIDTH * effectiveZoom.value.x)) + 2);

// Canvas position to beat/pitch
const positionToBeat = (x: number): number => {
  return (x + props.scroll.x) / (BEAT_WIDTH * effectiveZoom.value.x);
};

const positionToPitch = (y: number): number => {
  return MAX_PITCH - Math.floor((y + props.scroll.y) / (NOTE_HEIGHT * effectiveZoom.value.y));
};

// Beat/pitch to canvas position
const beatToPosition = (beat: number): number => {
  return beat * BEAT_WIDTH * effectiveZoom.value.x - props.scroll.x;
};

const pitchToPosition = (pitch: number): number => {
  return (MAX_PITCH - pitch) * NOTE_HEIGHT * effectiveZoom.value.y - props.scroll.y;
};

// Snap to grid
const snapToGrid = (beat: number): number => {
  return Math.round(beat / props.gridSnap) * props.gridSnap;
};

// Generate unique ID
const generateId = (): string => {
  return `note-${Date.now()}-${Math.random().toString(36).substring(2, 9)}`;
};

// Draw piano keys
const drawKeys = () => {
  if (!keysCtx.value || !keysCanvasRef.value) return;

  const c = keysCtx.value;
  const height = keysCanvasRef.value.height;

  c.clearRect(0, 0, KEY_WIDTH, height);

  for (let pitch = MAX_PITCH; pitch >= MIN_PITCH; pitch--) {
    const y = pitchToPosition(pitch);
    const h = NOTE_HEIGHT * effectiveZoom.value.y;

    if (y + h < 0 || y > height) continue;

    const black = isBlackKey(pitch);
    c.fillStyle = black ? colors.blackKey : colors.whiteKey;
    c.fillRect(0, y, KEY_WIDTH, h);

    // Border
    c.strokeStyle = colors.gridLine;
    c.strokeRect(0, y, KEY_WIDTH, h);

    // Label for C notes
    if (pitch % 12 === 0) {
      c.fillStyle = colors.keyLabel;
      c.font = "10px monospace";
      c.textAlign = "right";
      c.textBaseline = "middle";
      c.fillText(pitchToNoteName(pitch), KEY_WIDTH - 4, y + h / 2);
    }
  }
};

// Draw main grid and notes
const draw = () => {
  if (!ctx.value || !canvasRef.value) return;

  const c = ctx.value;
  const width = canvasRef.value.width;
  const height = canvasRef.value.height;

  // Clear
  c.fillStyle = colors.bg;
  c.fillRect(0, 0, width, height);

  // Draw grid rows (pitch lanes)
  for (let pitch = MAX_PITCH; pitch >= MIN_PITCH; pitch--) {
    const y = pitchToPosition(pitch);
    const h = NOTE_HEIGHT * effectiveZoom.value.y;

    if (y + h < 0 || y > height) continue;

    // Alternating row colors
    c.fillStyle = isBlackKey(pitch) ? colors.blackKey : colors.whiteKey;
    c.fillRect(0, y, width, h);

    // Horizontal grid line
    c.strokeStyle = colors.gridLine;
    c.beginPath();
    c.moveTo(0, y);
    c.lineTo(width, y);
    c.stroke();
  }

  // Draw vertical grid lines (beats)
  const startBeat = Math.floor(props.scroll.x / (BEAT_WIDTH * effectiveZoom.value.x));
  for (let beat = startBeat; beat <= startBeat + visibleBeats.value; beat++) {
    const x = beatToPosition(beat);
    if (x < 0 || x > width) continue;

    // Bar line (every 4 beats)
    if (beat % 4 === 0) {
      c.strokeStyle = colors.barLine;
      c.lineWidth = 2;
    } else if (beat % 1 === 0) {
      c.strokeStyle = colors.beatLine;
      c.lineWidth = 1;
    } else {
      c.strokeStyle = colors.gridLine;
      c.lineWidth = 1;
    }

    c.beginPath();
    c.moveTo(x, 0);
    c.lineTo(x, height);
    c.stroke();
    c.lineWidth = 1;
  }

  // Draw sub-beat grid lines based on snap
  if (props.gridSnap < 1) {
    c.strokeStyle = colors.gridLine;
    c.lineWidth = 0.5;
    for (let beat = startBeat; beat <= startBeat + visibleBeats.value; beat++) {
      for (let sub = props.gridSnap; sub < 1; sub += props.gridSnap) {
        const x = beatToPosition(beat + sub);
        if (x < 0 || x > width) continue;
        c.beginPath();
        c.moveTo(x, 0);
        c.lineTo(x, height);
        c.stroke();
      }
    }
    c.lineWidth = 1;
  }

  // Draw ghost note (during draw mode)
  if (ghostNote.value && props.tool === "draw") {
    const x = beatToPosition(ghostNote.value.start);
    const y = pitchToPosition(ghostNote.value.pitch);
    const w = ghostNote.value.duration * BEAT_WIDTH * effectiveZoom.value.x;
    const h = NOTE_HEIGHT * effectiveZoom.value.y;

    c.fillStyle = colors.ghost;
    c.fillRect(x, y, w, h);
  }

  // Draw notes
  for (const note of props.notes) {
    const x = beatToPosition(note.start);
    const y = pitchToPosition(note.pitch);
    const w = note.duration * BEAT_WIDTH * effectiveZoom.value.x;
    const h = NOTE_HEIGHT * effectiveZoom.value.y;

    // Skip if not visible
    if (x + w < 0 || x > width || y + h < 0 || y > height) continue;

    // Note fill
    if (note.selected) {
      c.fillStyle = colors.noteSelected;
    } else if (hoveredNote.value?.id === note.id) {
      c.fillStyle = colors.noteHover;
    } else {
      c.fillStyle = colors.note;
    }

    c.fillRect(x + 1, y + 1, w - 2, h - 2);

    // Note border
    c.strokeStyle = colors.noteBorder;
    c.strokeRect(x + 1, y + 1, w - 2, h - 2);

    // Velocity indicator (darker at bottom)
    const velocityRatio = note.velocity / 127;
    c.fillStyle = `rgba(0, 0, 0, ${0.3 - velocityRatio * 0.2})`;
    c.fillRect(x + 1, y + h - 4, w - 2, 3);
  }

  // Draw selection box
  if (selectionBox.value) {
    const { x1, y1, x2, y2 } = selectionBox.value;
    const rx = Math.min(x1, x2);
    const ry = Math.min(y1, y2);
    const rw = Math.abs(x2 - x1);
    const rh = Math.abs(y2 - y1);

    c.fillStyle = colors.selection;
    c.fillRect(rx, ry, rw, rh);
    c.strokeStyle = "#3b82f6";
    c.strokeRect(rx, ry, rw, rh);
  }

  // Draw playhead
  const playheadX = beatToPosition(props.playheadPosition);
  if (playheadX >= 0 && playheadX <= width) {
    c.strokeStyle = colors.playhead;
    c.lineWidth = 2;
    c.beginPath();
    c.moveTo(playheadX, 0);
    c.lineTo(playheadX, height);
    c.stroke();
    c.lineWidth = 1;

    // Playhead top indicator
    c.fillStyle = colors.playhead;
    c.beginPath();
    c.moveTo(playheadX - 6, 0);
    c.lineTo(playheadX + 6, 0);
    c.lineTo(playheadX, 10);
    c.closePath();
    c.fill();
  }
};

// Find note at position
const findNoteAtPosition = (x: number, y: number): PianoRollNote | null => {
  const beat = positionToBeat(x);
  const pitch = positionToPitch(y);

  for (const note of props.notes) {
    if (
      beat >= note.start &&
      beat <= note.start + note.duration &&
      pitch === note.pitch
    ) {
      return note;
    }
  }
  return null;
};

// Check if position is on resize edge
const getResizeEdge = (x: number, note: PianoRollNote): "left" | "right" | null => {
  const noteX = beatToPosition(note.start);
  const noteEndX = beatToPosition(note.start + note.duration);
  const edgeThreshold = 8;

  if (Math.abs(x - noteX) < edgeThreshold) return "left";
  if (Math.abs(x - noteEndX) < edgeThreshold) return "right";
  return null;
};

// Mouse handlers
const onMouseDown = (e: MouseEvent) => {
  if (!canvasRef.value || props.isPlaying) return;

  const rect = canvasRef.value.getBoundingClientRect();
  const x = e.clientX - rect.left;
  const y = e.clientY - rect.top;

  // Middle mouse button for panning
  if (e.button === 1) {
    isPanning.value = true;
    dragStart.value = { x: e.clientX, y: e.clientY };
    return;
  }

  const beat = positionToBeat(x);
  const pitch = positionToPitch(y);

  if (pitch < MIN_PITCH || pitch > MAX_PITCH) return;

  const clickedNote = findNoteAtPosition(x, y);

  if (props.tool === "select") {
    if (clickedNote) {
      const edge = getResizeEdge(x, clickedNote);
      if (edge) {
        // Start resizing
        isResizing.value = true;
        resizeEdge.value = edge;
        dragNote.value = clickedNote;
        dragStart.value = { x: beat, y: pitch };
      } else {
        // Start dragging
        if (!clickedNote.selected && !e.shiftKey) {
          // Deselect all other notes
          const updated = props.notes.map((n) => ({ ...n, selected: n.id === clickedNote.id }));
          emit("update:notes", updated);
        } else if (e.shiftKey) {
          // Toggle selection
          const updated = props.notes.map((n) =>
            n.id === clickedNote.id ? { ...n, selected: !n.selected } : n
          );
          emit("update:notes", updated);
        }
        isDragging.value = true;
        dragNote.value = clickedNote;
        dragStart.value = { x: beat, y: pitch };
      }
    } else {
      // Start selection box
      if (!e.shiftKey) {
        // Deselect all
        const updated = props.notes.map((n) => ({ ...n, selected: false }));
        emit("update:notes", updated);
      }
      selectionBox.value = { x1: x, y1: y, x2: x, y2: y };
      isDragging.value = true;
    }
  } else if (props.tool === "draw") {
    if (!clickedNote) {
      // Create new note
      const snappedBeat = snapToGrid(beat);
      const newNote: PianoRollNote = {
        id: generateId(),
        pitch,
        start: snappedBeat,
        duration: props.gridSnap,
        velocity: 100,
        selected: true,
      };
      emit("update:notes", [...props.notes.map((n) => ({ ...n, selected: false })), newNote]);
      emit("notePreview", pitch);
      isDragging.value = true;
      dragNote.value = newNote;
      dragStart.value = { x: snappedBeat, y: pitch };
    }
  } else if (props.tool === "erase") {
    if (clickedNote) {
      const updated = props.notes.filter((n) => n.id !== clickedNote.id);
      emit("update:notes", updated);
    }
  }
};

const onMouseMove = (e: MouseEvent) => {
  if (!canvasRef.value) return;

  const rect = canvasRef.value.getBoundingClientRect();
  const x = e.clientX - rect.left;
  const y = e.clientY - rect.top;

  // Panning
  if (isPanning.value) {
    const dx = e.clientX - dragStart.value.x;
    const dy = e.clientY - dragStart.value.y;
    emit("update:scroll", {
      x: Math.max(0, props.scroll.x - dx),
      y: Math.max(0, props.scroll.y - dy),
    });
    dragStart.value = { x: e.clientX, y: e.clientY };
    return;
  }

  const beat = positionToBeat(x);
  const pitch = positionToPitch(y);

  // Update cursor
  const noteUnderCursor = findNoteAtPosition(x, y);
  if (props.tool === "select" && noteUnderCursor) {
    const edge = getResizeEdge(x, noteUnderCursor);
    canvasRef.value.style.cursor = edge ? "ew-resize" : "move";
  } else if (props.tool === "draw") {
    canvasRef.value.style.cursor = "crosshair";
  } else if (props.tool === "erase") {
    canvasRef.value.style.cursor = "pointer";
  } else {
    canvasRef.value.style.cursor = "default";
  }

  // Update hovered note
  hoveredNote.value = noteUnderCursor;

  // Ghost note for draw mode
  if (props.tool === "draw" && !isDragging.value && pitch >= MIN_PITCH && pitch <= MAX_PITCH) {
    ghostNote.value = {
      pitch,
      start: snapToGrid(beat),
      duration: props.gridSnap,
    };
  } else if (props.tool !== "draw") {
    ghostNote.value = null;
  }

  if (!isDragging.value && !isResizing.value) {
    draw();
    return;
  }

  if (isResizing.value && dragNote.value) {
    // Resizing note
    const snappedBeat = snapToGrid(beat);
    const updated = props.notes.map((n) => {
      if (n.id === dragNote.value!.id) {
        if (resizeEdge.value === "left") {
          const newStart = Math.min(snappedBeat, n.start + n.duration - props.gridSnap);
          const newDuration = n.start + n.duration - newStart;
          return { ...n, start: newStart, duration: Math.max(props.gridSnap, newDuration) };
        } else {
          const newDuration = snappedBeat - n.start;
          return { ...n, duration: Math.max(props.gridSnap, newDuration) };
        }
      }
      return n;
    });
    emit("update:notes", updated);
  } else if (isDragging.value && dragNote.value && props.tool === "select") {
    // Dragging note(s)
    const deltaBeat = snapToGrid(beat) - snapToGrid(dragStart.value.x);
    const deltaPitch = pitch - dragStart.value.y;

    if (deltaBeat !== 0 || deltaPitch !== 0) {
      const updated = props.notes.map((n) => {
        if (n.selected) {
          return {
            ...n,
            start: Math.max(0, n.start + deltaBeat),
            pitch: Math.max(MIN_PITCH, Math.min(MAX_PITCH, n.pitch + deltaPitch)),
          };
        }
        return n;
      });
      emit("update:notes", updated);
      dragStart.value = { x: snapToGrid(beat), y: pitch };
    }
  } else if (isDragging.value && dragNote.value && props.tool === "draw") {
    // Extending new note duration
    const snappedBeat = snapToGrid(beat);
    const updated = props.notes.map((n) => {
      if (n.id === dragNote.value!.id) {
        const newDuration = Math.max(props.gridSnap, snappedBeat - n.start + props.gridSnap);
        return { ...n, duration: newDuration };
      }
      return n;
    });
    emit("update:notes", updated);
  } else if (selectionBox.value) {
    // Selection box
    selectionBox.value.x2 = x;
    selectionBox.value.y2 = y;

    // Select notes within box
    const { x1, y1, x2, y2 } = selectionBox.value;
    const minX = Math.min(x1, x2);
    const maxX = Math.max(x1, x2);
    const minY = Math.min(y1, y2);
    const maxY = Math.max(y1, y2);

    const minBeat = positionToBeat(minX);
    const maxBeat = positionToBeat(maxX);
    const maxPitch = positionToPitch(minY);
    const minPitch = positionToPitch(maxY);

    const updated = props.notes.map((n) => {
      const noteEndBeat = n.start + n.duration;
      const inBox =
        n.start <= maxBeat &&
        noteEndBeat >= minBeat &&
        n.pitch >= minPitch &&
        n.pitch <= maxPitch;
      return { ...n, selected: inBox };
    });
    emit("update:notes", updated);
  }

  draw();
};

const onMouseUp = () => {
  if (isDragging.value && props.tool === "draw" && dragNote.value) {
    emit("notePreviewStop");
  }
  isDragging.value = false;
  isResizing.value = false;
  isPanning.value = false;
  dragNote.value = null;
  resizeEdge.value = null;
  selectionBox.value = null;
  ghostNote.value = null;
  draw();
};

const onMouseLeave = () => {
  hoveredNote.value = null;
  ghostNote.value = null;
  draw();
};

// Wheel handler for scroll/zoom
const onWheel = (e: WheelEvent) => {
  e.preventDefault();

  if (e.ctrlKey || e.metaKey) {
    // Zoom - not implemented yet
    return;
  }

  const dx = e.shiftKey ? e.deltaY : e.deltaX;
  const dy = e.shiftKey ? 0 : e.deltaY;

  emit("update:scroll", {
    x: Math.max(0, props.scroll.x + dx),
    y: Math.max(0, props.scroll.y + dy),
  });
};

// Key handlers
const onKeyDown = (e: KeyboardEvent) => {
  if (e.key === "Delete" || e.key === "Backspace") {
    // Delete selected notes
    const updated = props.notes.filter((n) => !n.selected);
    emit("update:notes", updated);
  } else if (e.key === "a" && (e.ctrlKey || e.metaKey)) {
    // Select all
    e.preventDefault();
    const updated = props.notes.map((n) => ({ ...n, selected: true }));
    emit("update:notes", updated);
  } else if (e.key === "Escape") {
    // Deselect all
    const updated = props.notes.map((n) => ({ ...n, selected: false }));
    emit("update:notes", updated);
  }
};

// Keyboard click on piano keys
const onKeyClick = (e: MouseEvent) => {
  if (!keysCanvasRef.value) return;

  const rect = keysCanvasRef.value.getBoundingClientRect();
  const y = e.clientY - rect.top;
  const pitch = positionToPitch(y);

  if (pitch >= MIN_PITCH && pitch <= MAX_PITCH) {
    emit("notePreview", pitch);
    // Auto stop after 500ms
    setTimeout(() => emit("notePreviewStop"), 500);
  }
};

// Resize observer
const resizeObserver = ref<ResizeObserver | null>(null);

const updateCanvasSize = () => {
  if (!containerRef.value || !canvasRef.value || !keysCanvasRef.value) return;

  const rect = containerRef.value.getBoundingClientRect();
  canvasWidth.value = rect.width - KEY_WIDTH;
  canvasHeight.value = rect.height;

  canvasRef.value.width = canvasWidth.value;
  canvasRef.value.height = canvasHeight.value;
  keysCanvasRef.value.width = KEY_WIDTH;
  keysCanvasRef.value.height = canvasHeight.value;

  draw();
  drawKeys();
};

// Setup
onMounted(() => {
  if (canvasRef.value) {
    ctx.value = canvasRef.value.getContext("2d");
  }
  if (keysCanvasRef.value) {
    keysCtx.value = keysCanvasRef.value.getContext("2d");
  }

  updateCanvasSize();

  resizeObserver.value = new ResizeObserver(updateCanvasSize);
  if (containerRef.value) {
    resizeObserver.value.observe(containerRef.value);
  }

  // Initial scroll to middle range
  emit("update:scroll", { x: 0, y: (MAX_PITCH - 60) * NOTE_HEIGHT * effectiveZoom.value.y });
});

onUnmounted(() => {
  resizeObserver.value?.disconnect();
});

// Reactive drawing
watch(
  [() => props.notes, () => props.scroll, () => props.playheadPosition, () => props.zoom],
  () => {
    draw();
    drawKeys();
  },
  { deep: true }
);
</script>

<template>
  <div
    ref="containerRef"
    class="piano-roll-container"
    tabindex="0"
    @keydown="onKeyDown"
  >
    <canvas
      ref="keysCanvasRef"
      class="piano-keys"
      @click="onKeyClick"
    />
    <canvas
      ref="canvasRef"
      class="piano-roll-canvas"
      @mousedown="onMouseDown"
      @mousemove="onMouseMove"
      @mouseup="onMouseUp"
      @mouseleave="onMouseLeave"
      @wheel="onWheel"
    />
  </div>
</template>

<style scoped>
.piano-roll-container {
  display: flex;
  width: 100%;
  height: 100%;
  background: #1e1e1e;
  border-radius: 4px;
  overflow: hidden;
  outline: none;
}

.piano-keys {
  flex-shrink: 0;
  cursor: pointer;
}

.piano-roll-canvas {
  flex: 1;
}
</style>
