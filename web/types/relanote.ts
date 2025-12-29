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
