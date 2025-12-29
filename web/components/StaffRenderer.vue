<script setup lang="ts">
import type { StaffData, NoteEvent } from "../types/relanote";

const props = defineProps<{
  staffData: StaffData | null;
  currentBeat: number;
}>();

const canvasRef = ref<HTMLCanvasElement | null>(null);

// Staff configuration
const STAFF_CONFIG = {
  lineSpacing: 10, // pixels between staff lines
  noteRadius: 6,
  stemHeight: 35,
  paddingLeft: 60,
  paddingTop: 40,
  paddingRight: 20,
  beatsPerMeasure: 4,
  pixelsPerBeat: 40,
  staffLines: 5,
};

// MIDI pitch to staff position (middle C = 60 = middle line of treble clef)
const pitchToY = (pitch: number, baseY: number) => {
  // C4 (60) is on the first ledger line below treble clef
  // Each semitone moves half a step, but we use diatonic steps for staff position
  const pitchClasses = [0, 0, 1, 1, 2, 3, 3, 4, 4, 5, 5, 6]; // C, C#, D, D#, E, F, F#, G, G#, A, A#, B
  const octave = Math.floor(pitch / 12) - 5; // Octave relative to middle C
  const pitchClass = pitch % 12;
  const diatonicStep = pitchClasses[pitchClass];

  // Staff position: 0 = middle line (B4 for treble clef)
  // Each step is half the line spacing
  const stepsFromB4 = (octave * 7 + diatonicStep) - 6; // B4 is step 6 in octave 4
  return baseY - stepsFromB4 * (STAFF_CONFIG.lineSpacing / 2);
};

const draw = () => {
  const canvas = canvasRef.value;
  if (!canvas || !props.staffData) return;

  const ctx = canvas.getContext("2d");
  if (!ctx) return;

  const { notes, tempo, time_signature_num, total_beats } = props.staffData;

  // Calculate canvas width based on total beats
  const minWidth = 800;
  const calculatedWidth =
    STAFF_CONFIG.paddingLeft +
    Math.max(total_beats, 4) * STAFF_CONFIG.pixelsPerBeat +
    STAFF_CONFIG.paddingRight;
  canvas.width = Math.max(minWidth, calculatedWidth);
  canvas.height = 200;

  // Clear canvas
  ctx.fillStyle = "#1e1e1e";
  ctx.fillRect(0, 0, canvas.width, canvas.height);

  const staffY = STAFF_CONFIG.paddingTop + 2 * STAFF_CONFIG.lineSpacing;

  // Draw staff lines
  ctx.strokeStyle = "#666666";
  ctx.lineWidth = 1;
  for (let i = 0; i < STAFF_CONFIG.staffLines; i++) {
    const y = staffY + i * STAFF_CONFIG.lineSpacing;
    ctx.beginPath();
    ctx.moveTo(STAFF_CONFIG.paddingLeft - 20, y);
    ctx.lineTo(canvas.width - STAFF_CONFIG.paddingRight, y);
    ctx.stroke();
  }

  // Draw treble clef (simplified)
  ctx.font = "48px serif";
  ctx.fillStyle = "#cccccc";
  ctx.fillText("𝄞", STAFF_CONFIG.paddingLeft - 45, staffY + 30);

  // Draw time signature
  ctx.font = "bold 20px serif";
  ctx.fillStyle = "#cccccc";
  ctx.fillText(
    time_signature_num.toString(),
    STAFF_CONFIG.paddingLeft - 15,
    staffY + 12
  );
  ctx.fillText("4", STAFF_CONFIG.paddingLeft - 15, staffY + 32);

  // Draw measure lines
  ctx.strokeStyle = "#555555";
  const measures = Math.ceil(total_beats / STAFF_CONFIG.beatsPerMeasure);
  for (let i = 0; i <= measures; i++) {
    const x =
      STAFF_CONFIG.paddingLeft + i * STAFF_CONFIG.beatsPerMeasure * STAFF_CONFIG.pixelsPerBeat;
    ctx.beginPath();
    ctx.moveTo(x, staffY);
    ctx.lineTo(x, staffY + (STAFF_CONFIG.staffLines - 1) * STAFF_CONFIG.lineSpacing);
    ctx.stroke();
  }

  // Draw playhead
  if (props.currentBeat >= 0) {
    const playheadX = STAFF_CONFIG.paddingLeft + props.currentBeat * STAFF_CONFIG.pixelsPerBeat;
    ctx.strokeStyle = "#0e639c";
    ctx.lineWidth = 2;
    ctx.beginPath();
    ctx.moveTo(playheadX, staffY - 10);
    ctx.lineTo(playheadX, staffY + (STAFF_CONFIG.staffLines - 1) * STAFF_CONFIG.lineSpacing + 10);
    ctx.stroke();
    ctx.lineWidth = 1;
  }

  // Draw notes
  notes.forEach((note: NoteEvent) => {
    const x = STAFF_CONFIG.paddingLeft + note.start * STAFF_CONFIG.pixelsPerBeat;
    const y = pitchToY(note.pitch, staffY + 2 * STAFF_CONFIG.lineSpacing);

    // Note head
    ctx.fillStyle = note.start <= props.currentBeat && props.currentBeat < note.start + note.duration
      ? "#4ec9b0"
      : "#cccccc";
    ctx.beginPath();
    ctx.ellipse(x, y, STAFF_CONFIG.noteRadius + 1, STAFF_CONFIG.noteRadius, -0.3, 0, Math.PI * 2);
    ctx.fill();

    // Stem
    ctx.strokeStyle = ctx.fillStyle;
    ctx.lineWidth = 1.5;
    const stemUp = y > staffY + 2 * STAFF_CONFIG.lineSpacing;
    ctx.beginPath();
    if (stemUp) {
      ctx.moveTo(x + STAFF_CONFIG.noteRadius, y);
      ctx.lineTo(x + STAFF_CONFIG.noteRadius, y - STAFF_CONFIG.stemHeight);
    } else {
      ctx.moveTo(x - STAFF_CONFIG.noteRadius, y);
      ctx.lineTo(x - STAFF_CONFIG.noteRadius, y + STAFF_CONFIG.stemHeight);
    }
    ctx.stroke();

    // Ledger lines if needed
    ctx.strokeStyle = "#666666";
    ctx.lineWidth = 1;
    const middleCY = staffY + (STAFF_CONFIG.staffLines + 1) * STAFF_CONFIG.lineSpacing;
    if (y >= middleCY) {
      // Below staff - draw ledger lines
      for (let ly = staffY + (STAFF_CONFIG.staffLines - 1) * STAFF_CONFIG.lineSpacing + STAFF_CONFIG.lineSpacing;
           ly <= y;
           ly += STAFF_CONFIG.lineSpacing) {
        ctx.beginPath();
        ctx.moveTo(x - 12, ly);
        ctx.lineTo(x + 12, ly);
        ctx.stroke();
      }
    } else if (y <= staffY - STAFF_CONFIG.lineSpacing) {
      // Above staff
      for (let ly = staffY - STAFF_CONFIG.lineSpacing; ly >= y; ly -= STAFF_CONFIG.lineSpacing) {
        ctx.beginPath();
        ctx.moveTo(x - 12, ly);
        ctx.lineTo(x + 12, ly);
        ctx.stroke();
      }
    }
  });
};

watch(() => [props.staffData, props.currentBeat], draw, { deep: true });

onMounted(() => {
  draw();
});
</script>

<template>
  <div class="staff-container">
    <div class="staff-header">
      <span class="staff-title">Staff Notation</span>
      <span v-if="staffData" class="staff-info">
        {{ staffData.tempo }} BPM | {{ staffData.time_signature_num }}/{{ staffData.time_signature_den }}
      </span>
    </div>
    <div class="staff-scroll">
      <canvas ref="canvasRef" class="staff-canvas" />
    </div>
    <div v-if="!staffData || staffData.notes.length === 0" class="staff-empty">
      No notes to display
    </div>
  </div>
</template>

<style scoped>
.staff-container {
  display: flex;
  flex-direction: column;
  height: 100%;
  background: #1e1e1e;
  border-radius: 8px;
  overflow: hidden;
}

.staff-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 8px 12px;
  background: #252526;
  border-bottom: 1px solid #3c3c3c;
}

.staff-title {
  color: #cccccc;
  font-size: 13px;
}

.staff-info {
  color: #858585;
  font-size: 12px;
}

.staff-scroll {
  flex: 1;
  overflow-x: auto;
  overflow-y: hidden;
}

.staff-canvas {
  display: block;
}

.staff-empty {
  position: absolute;
  top: 50%;
  left: 50%;
  transform: translate(-50%, -50%);
  color: #666666;
  font-size: 14px;
}
</style>
