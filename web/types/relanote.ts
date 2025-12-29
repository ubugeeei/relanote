export interface WasmDiagnostic {
  message: string;
  start: number;
  end: number;
  severity: "error" | "warning" | "info";
}

export interface AnalysisResult {
  diagnostics: WasmDiagnostic[];
  success: boolean;
}

export interface FormatResult {
  formatted: string;
  success: boolean;
  error: string | null;
}

export interface RenderResult {
  success: boolean;
  midi_data: number[] | null;
  error: string | null;
}

export interface NoteEvent {
  pitch: number;
  start: number;
  duration: number;
  velocity: number;
}

export interface StaffData {
  notes: NoteEvent[];
  tempo: number;
  time_signature_num: number;
  time_signature_den: number;
  total_beats: number;
}

// Synth types for WebAudio playback
export interface OscillatorData {
  waveform: "sine" | "square" | "sawtooth" | "triangle" | "noise" | "pulse";
  pulse_duty: number;
  mix: number;
  octave_offset: number;
  detune_cents: number;
}

export interface ADSRData {
  attack: number;
  decay: number;
  sustain: number;
  release: number;
}

export interface FilterData {
  filter_type: "lowpass" | "highpass" | "bandpass";
  cutoff: number;
  resonance: number;
}

export interface SynthData {
  name: string;
  oscillators: OscillatorData[];
  envelope: ADSRData;
  filter?: FilterData;
  detune_cents: number;
}

export interface AudioNoteEvent extends NoteEvent {
  synth?: SynthData;
}

export interface AudioPlaybackData {
  notes: AudioNoteEvent[];
  tempo: number;
  total_beats: number;
}
