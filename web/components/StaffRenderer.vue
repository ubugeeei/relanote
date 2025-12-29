<script setup lang="ts">
import type { StaffData, NoteEvent } from "../types/relanote";

const props = defineProps<{
  staffData: StaffData | null;
  currentBeat: number;
}>();

const canvasRef = ref<HTMLCanvasElement | null>(null);

// Staff configuration
const STAFF_CONFIG = {
  lineSpacing: 12, // pixels between staff lines (increased for readability)
  noteRadius: 7,
  stemHeight: 40,
  paddingLeft: 80,
  paddingTop: 50,
  paddingRight: 30,
  beatsPerMeasure: 4,
  pixelsPerBeat: 50, // increased for better spacing
  staffLines: 5,
};

// Get note type based on duration
const getNoteType = (duration: number): "whole" | "half" | "quarter" | "eighth" | "sixteenth" | "thirtysecond" => {
  if (duration >= 4) return "whole";
  if (duration >= 2) return "half";
  if (duration >= 1) return "quarter";
  if (duration >= 0.5) return "eighth";
  if (duration >= 0.25) return "sixteenth";
  return "thirtysecond";
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
  const minWidth = 900;
  const calculatedWidth =
    STAFF_CONFIG.paddingLeft +
    Math.max(total_beats, 4) * STAFF_CONFIG.pixelsPerBeat +
    STAFF_CONFIG.paddingRight;
  canvas.width = Math.max(minWidth, calculatedWidth);
  canvas.height = 240; // Increased for duration text

  // Clear canvas
  ctx.fillStyle = "#1a1a1a";
  ctx.fillRect(0, 0, canvas.width, canvas.height);

  const staffY = STAFF_CONFIG.paddingTop + 2 * STAFF_CONFIG.lineSpacing;

  // Draw staff lines (brighter for readability)
  ctx.strokeStyle = "#888888";
  ctx.lineWidth = 1;
  for (let i = 0; i < STAFF_CONFIG.staffLines; i++) {
    const y = staffY + i * STAFF_CONFIG.lineSpacing;
    ctx.beginPath();
    ctx.moveTo(STAFF_CONFIG.paddingLeft - 30, y);
    ctx.lineTo(canvas.width - STAFF_CONFIG.paddingRight, y);
    ctx.stroke();
  }

  // Draw treble clef (simplified)
  ctx.font = "56px serif";
  ctx.fillStyle = "#dddddd";
  ctx.fillText("𝄞", STAFF_CONFIG.paddingLeft - 60, staffY + 35);

  // Draw time signature
  ctx.font = "bold 22px serif";
  ctx.fillStyle = "#dddddd";
  ctx.fillText(
    time_signature_num.toString(),
    STAFF_CONFIG.paddingLeft - 20,
    staffY + 14
  );
  ctx.fillText("4", STAFF_CONFIG.paddingLeft - 20, staffY + 36);

  // Draw measure lines (more visible)
  ctx.strokeStyle = "#777777";
  ctx.lineWidth = 1.5;
  const measures = Math.ceil(total_beats / STAFF_CONFIG.beatsPerMeasure);
  for (let i = 0; i <= measures; i++) {
    const x =
      STAFF_CONFIG.paddingLeft + i * STAFF_CONFIG.beatsPerMeasure * STAFF_CONFIG.pixelsPerBeat;
    ctx.beginPath();
    ctx.moveTo(x, staffY);
    ctx.lineTo(x, staffY + (STAFF_CONFIG.staffLines - 1) * STAFF_CONFIG.lineSpacing);
    ctx.stroke();
  }
  ctx.lineWidth = 1;

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
    const noteType = getNoteType(note.duration);
    const isPlaying = note.start <= props.currentBeat && props.currentBeat < note.start + note.duration;
    const noteColor = isPlaying ? "#4ec9b0" : "#dddddd";

    // Ledger lines if needed (draw first, behind notes)
    ctx.strokeStyle = "#888888";
    ctx.lineWidth = 1;
    const middleCY = staffY + (STAFF_CONFIG.staffLines + 1) * STAFF_CONFIG.lineSpacing;
    if (y >= middleCY) {
      // Below staff - draw ledger lines
      for (let ly = staffY + (STAFF_CONFIG.staffLines - 1) * STAFF_CONFIG.lineSpacing + STAFF_CONFIG.lineSpacing;
           ly <= y;
           ly += STAFF_CONFIG.lineSpacing) {
        ctx.beginPath();
        ctx.moveTo(x - 14, ly);
        ctx.lineTo(x + 14, ly);
        ctx.stroke();
      }
    } else if (y <= staffY - STAFF_CONFIG.lineSpacing) {
      // Above staff
      for (let ly = staffY - STAFF_CONFIG.lineSpacing; ly >= y; ly -= STAFF_CONFIG.lineSpacing) {
        ctx.beginPath();
        ctx.moveTo(x - 14, ly);
        ctx.lineTo(x + 14, ly);
        ctx.stroke();
      }
    }

    // Note head
    const r = STAFF_CONFIG.noteRadius;
    const isFilled = noteType !== "whole" && noteType !== "half";

    ctx.beginPath();
    ctx.ellipse(x, y, r + 1, r, -0.3, 0, Math.PI * 2);

    if (isFilled) {
      ctx.fillStyle = noteColor;
      ctx.fill();
    } else {
      // Hollow note (whole or half)
      ctx.strokeStyle = noteColor;
      ctx.lineWidth = 2;
      ctx.stroke();
    }

    // Stem (not for whole notes)
    if (noteType !== "whole") {
      ctx.strokeStyle = noteColor;
      ctx.lineWidth = 1.5;
      const stemUp = y > staffY + 2 * STAFF_CONFIG.lineSpacing;
      const stemX = stemUp ? x + r : x - r;
      const stemEndY = stemUp ? y - STAFF_CONFIG.stemHeight : y + STAFF_CONFIG.stemHeight;

      ctx.beginPath();
      ctx.moveTo(stemX, y);
      ctx.lineTo(stemX, stemEndY);
      ctx.stroke();

      // Flags for eighth notes and shorter
      const flagCount =
        noteType === "eighth" ? 1 :
        noteType === "sixteenth" ? 2 :
        noteType === "thirtysecond" ? 3 : 0;

      if (flagCount > 0) {
        ctx.lineWidth = 2;
        for (let f = 0; f < flagCount; f++) {
          const flagY = stemUp
            ? stemEndY + f * 8
            : stemEndY - f * 8;
          const flagDir = stemUp ? 1 : -1;

          ctx.beginPath();
          ctx.moveTo(stemX, flagY);
          // Curved flag
          ctx.quadraticCurveTo(
            stemX + 12 * (stemUp ? 1 : -1),
            flagY + 6 * flagDir,
            stemX + 10 * (stemUp ? 1 : -1),
            flagY + 14 * flagDir
          );
          ctx.stroke();
        }
      }
    }

    // Draw duration text below/above the note (small, subtle)
    ctx.font = "9px monospace";
    ctx.fillStyle = "#666666";
    const durationText = note.duration >= 1
      ? note.duration.toString()
      : note.duration >= 0.5 ? "½"
      : note.duration >= 0.25 ? "¼"
      : note.duration >= 0.125 ? "⅛"
      : note.duration.toFixed(2);
    const textY = y > staffY + 2 * STAFF_CONFIG.lineSpacing
      ? y - STAFF_CONFIG.stemHeight - 8
      : y + STAFF_CONFIG.stemHeight + 14;
    ctx.fillText(durationText, x - 6, textY);
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
