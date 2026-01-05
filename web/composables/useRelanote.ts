import type {
  AnalysisResult,
  FormatResult,
  RenderResult,
  StaffData,
  AudioPlaybackData,
  PianoRollNote,
  CompletionItem,
  HoverResult,
} from "../types/relanote";

let wasmModule: typeof import("../wasm/pkg/relanote_wasm") | null = null;
let initPromise: Promise<void> | null = null;

async function initWasm() {
  if (wasmModule) return;
  if (initPromise) {
    await initPromise;
    return;
  }

  initPromise = (async () => {
    const wasm = await import("../wasm/pkg/relanote_wasm");
    await wasm.default();
    wasmModule = wasm;
  })();

  await initPromise;
}

export function useRelanote() {
  const isReady = ref(false);
  const error = ref<string | null>(null);

  const init = async () => {
    try {
      await initWasm();
      isReady.value = true;
    } catch (e) {
      error.value = e instanceof Error ? e.message : "Failed to load WASM";
      console.error("Failed to load WASM:", e);
    }
  };

  const analyze = (source: string): AnalysisResult | null => {
    if (!wasmModule) return null;
    return wasmModule.analyze(source) as AnalysisResult;
  };

  const format = (source: string): FormatResult | null => {
    if (!wasmModule) return null;
    return wasmModule.format_code(source) as FormatResult;
  };

  const renderMidi = (source: string): RenderResult | null => {
    if (!wasmModule) return null;
    return wasmModule.render_midi(source) as RenderResult;
  };

  const getStaffData = (source: string): StaffData | null => {
    if (!wasmModule) return null;
    return wasmModule.get_staff_data(source) as StaffData;
  };

  const getAudioData = (source: string): AudioPlaybackData | null => {
    if (!wasmModule) return null;
    return wasmModule.get_audio_data(source) as AudioPlaybackData;
  };

  const getTokens = (
    source: string
  ): Array<{ start: number; end: number; kind: string }> | null => {
    if (!wasmModule) return null;
    return wasmModule.get_tokens(source) as Array<{
      start: number;
      end: number;
      kind: string;
    }>;
  };

  const notesToCode = (
    notes: PianoRollNote[],
    synthName?: string,
    keyPitch?: number
  ): string | null => {
    if (!wasmModule) return null;
    // Convert notes to JSON for WASM
    const notesForWasm = notes.map((n) => ({
      pitch: n.pitch,
      start: n.start,
      duration: n.duration,
      velocity: n.velocity,
    }));
    const notesJson = JSON.stringify(notesForWasm);
    return wasmModule.notes_to_code(notesJson, synthName, keyPitch);
  };

  const getCompletions = (): CompletionItem[] | null => {
    if (!wasmModule) return null;
    return wasmModule.get_completions() as CompletionItem[];
  };

  const getHover = (source: string, offset: number): HoverResult | null => {
    if (!wasmModule) return null;
    return wasmModule.get_hover(source, offset) as HoverResult;
  };

  return {
    isReady,
    error,
    init,
    analyze,
    format,
    renderMidi,
    getStaffData,
    getAudioData,
    getTokens,
    notesToCode,
    getCompletions,
    getHover,
  };
}
