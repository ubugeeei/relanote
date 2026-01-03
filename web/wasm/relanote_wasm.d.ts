/* tslint:disable */
/* eslint-disable */

/**
 * Analyze source code and return diagnostics
 */
export function analyze(source: string): any;

/**
 * Evaluate source code and return the result
 */
export function evaluate(source: string): any;

/**
 * Format source code
 */
export function format_code(source: string): any;

/**
 * Get audio playback data including synth information
 */
export function get_audio_data(source: string): any;

/**
 * Get staff notation data for rendering
 */
export function get_staff_data(source: string): any;

/**
 * Get syntax highlighting tokens
 */
export function get_tokens(source: string): any;

export function init(): void;

/**
 * Render source to MIDI data
 */
export function render_midi(source: string): any;

export type InitInput = RequestInfo | URL | Response | BufferSource | WebAssembly.Module;

export interface InitOutput {
  readonly memory: WebAssembly.Memory;
  readonly init: () => void;
  readonly analyze: (a: number, b: number) => any;
  readonly format_code: (a: number, b: number) => any;
  readonly evaluate: (a: number, b: number) => any;
  readonly render_midi: (a: number, b: number) => any;
  readonly get_staff_data: (a: number, b: number) => any;
  readonly get_tokens: (a: number, b: number) => any;
  readonly get_audio_data: (a: number, b: number) => any;
  readonly __wbindgen_malloc: (a: number, b: number) => number;
  readonly __wbindgen_realloc: (a: number, b: number, c: number, d: number) => number;
  readonly __wbindgen_free: (a: number, b: number, c: number) => void;
  readonly __wbindgen_externrefs: WebAssembly.Table;
  readonly __wbindgen_start: () => void;
}

export type SyncInitInput = BufferSource | WebAssembly.Module;

/**
* Instantiates the given `module`, which can either be bytes or
* a precompiled `WebAssembly.Module`.
*
* @param {{ module: SyncInitInput }} module - Passing `SyncInitInput` directly is deprecated.
*
* @returns {InitOutput}
*/
export function initSync(module: { module: SyncInitInput } | SyncInitInput): InitOutput;

/**
* If `module_or_path` is {RequestInfo} or {URL}, makes a request and
* for everything else, calls `WebAssembly.instantiate` directly.
*
* @param {{ module_or_path: InitInput | Promise<InitInput> }} module_or_path - Passing `InitInput` directly is deprecated.
*
* @returns {Promise<InitOutput>}
*/
export default function __wbg_init (module_or_path?: { module_or_path: InitInput | Promise<InitInput> } | InitInput | Promise<InitInput>): Promise<InitOutput>;
