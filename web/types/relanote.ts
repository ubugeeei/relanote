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

export interface PitchEnvelopeData {
  start_hz: number;
  end_hz: number;
  time_seconds: number;
}

export interface SynthData {
  name: string;
  oscillators: OscillatorData[];
  envelope: ADSRData;
  filter?: FilterData;
  detune_cents: number;
  pitch_envelope?: PitchEnvelopeData;
}

export interface AudioNoteEvent extends NoteEvent {
  synth?: SynthData;
}

export interface AudioPlaybackData {
  notes: AudioNoteEvent[];
  tempo: number;
  total_beats: number;
}

// DAW Types
export interface PianoRollNote {
  id: string;
  pitch: number; // MIDI note (0-127)
  start: number; // beats
  duration: number; // beats
  velocity: number; // 0-127
  selected: boolean;
}

export interface TrackInfo {
  id: string;
  name: string;
  synth: string;
  notes: PianoRollNote[];
  muted: boolean;
  solo: boolean;
  volume: number; // 0-1
  pan: number; // -1 to 1
  color: string;
}

export interface DawState {
  tracks: TrackInfo[];
  selectedTrackId: string | null;
  tempo: number;
  timeSignatureNum: number;
  timeSignatureDen: number;
  gridSnap: number; // 1, 0.5, 0.25, 0.125, 0.0625
  zoom: { x: number; y: number };
  scroll: { x: number; y: number };
  tool: "select" | "draw" | "erase";
  loop: { enabled: boolean; start: number; end: number };
  playheadPosition: number;
}

export type ViewMode = "pianoroll" | "code";
