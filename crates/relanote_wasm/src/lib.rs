//! WebAssembly bindings for relanote

use serde::{Deserialize, Serialize};
use wasm_bindgen::prelude::*;

use relanote_core::Source;
use relanote_eval::{AbsolutePitchValue, Evaluator, SongValue, Value};
use relanote_format::{format, FormatConfig};
use relanote_parser::parse_source;
use relanote_render::{MidiConfig, MidiRenderer};
use relanote_types::TypeChecker;

/// Get the MIDI note number for the key from the evaluator
fn get_key_from_evaluator(evaluator: &Evaluator) -> Option<u8> {
    evaluator.get_binding("key").and_then(|v| {
        if let Value::AbsolutePitch(AbsolutePitchValue { midi_note }) = v {
            Some(midi_note)
        } else {
            None
        }
    })
}

#[wasm_bindgen(start)]
pub fn init() {
    console_error_panic_hook::set_once();
}

/// Diagnostic information for the editor
#[derive(Clone, Serialize, Deserialize)]
pub struct WasmDiagnostic {
    pub message: String,
    pub start: usize,
    pub end: usize,
    pub severity: String, // "error" | "warning" | "info"
}

/// Analysis result containing diagnostics and type info
#[derive(Serialize, Deserialize)]
pub struct AnalysisResult {
    pub diagnostics: Vec<WasmDiagnostic>,
    pub success: bool,
}

/// Format result
#[derive(Serialize, Deserialize)]
pub struct FormatResult {
    pub formatted: String,
    pub success: bool,
    pub error: Option<String>,
}

/// Evaluation result
#[derive(Serialize, Deserialize)]
pub struct EvalResult {
    pub success: bool,
    pub value: Option<String>,
    pub error: Option<String>,
}

/// MIDI render result
#[derive(Serialize, Deserialize)]
pub struct RenderResult {
    pub success: bool,
    pub midi_data: Option<Vec<u8>>,
    pub error: Option<String>,
}

/// Note event for staff notation
#[derive(Serialize, Deserialize, Clone)]
pub struct NoteEvent {
    pub pitch: i32,    // MIDI pitch (60 = C4)
    pub start: f64,    // Start time in beats
    pub duration: f64, // Duration in beats
    pub velocity: u8,  // Velocity (0-127)
}

/// Synth oscillator data for WebAudio
#[derive(Serialize, Deserialize, Clone)]
pub struct OscillatorData {
    pub waveform: String, // "sine" | "square" | "sawtooth" | "triangle" | "noise" | "pulse"
    pub pulse_duty: f64,  // Duty cycle for pulse wave (0.0-1.0)
    pub mix: f64,         // Volume mix (0.0-1.0)
    pub octave_offset: i8, // Octave offset (-2 to +2)
    pub detune_cents: f64, // Detune in cents
}

/// ADSR envelope data for WebAudio
#[derive(Serialize, Deserialize, Clone)]
pub struct ADSRData {
    pub attack: f64,  // Attack time in seconds
    pub decay: f64,   // Decay time in seconds
    pub sustain: f64, // Sustain level (0.0-1.0)
    pub release: f64, // Release time in seconds
}

/// Filter data for WebAudio
#[derive(Serialize, Deserialize, Clone)]
pub struct FilterData {
    pub filter_type: String, // "lowpass" | "highpass" | "bandpass"
    pub cutoff: f64,         // Cutoff frequency in Hz
    pub resonance: f64,      // Q/resonance (0.0-1.0)
}

/// Pitch envelope data for WebAudio (used for drum sounds like kicks)
#[derive(Serialize, Deserialize, Clone)]
pub struct PitchEnvelopeData {
    pub start_hz: f64,      // Starting frequency in Hz
    pub end_hz: f64,        // Ending frequency in Hz
    pub time_seconds: f64,  // Duration of the pitch sweep
}

/// Complete synth data for WebAudio playback
#[derive(Serialize, Deserialize, Clone)]
pub struct SynthData {
    pub name: String,
    pub oscillators: Vec<OscillatorData>,
    pub envelope: ADSRData,
    pub filter: Option<FilterData>,
    pub detune_cents: f64,
    pub pitch_envelope: Option<PitchEnvelopeData>,
}

/// Audio note event with synth information
#[derive(Serialize, Deserialize, Clone)]
pub struct AudioNoteEvent {
    pub pitch: i32,
    pub start: f64,
    pub duration: f64,
    pub velocity: u8,
    pub synth: Option<SynthData>,
}

/// Audio playback data with synth information
#[derive(Serialize, Deserialize)]
pub struct AudioPlaybackData {
    pub notes: Vec<AudioNoteEvent>,
    pub tempo: u32,
    pub total_beats: f64,
}

/// Staff render data
#[derive(Serialize, Deserialize)]
pub struct StaffData {
    pub notes: Vec<NoteEvent>,
    pub tempo: u32,
    pub time_signature_num: u8,
    pub time_signature_den: u8,
    pub total_beats: f64,
}

/// Analyze source code and return diagnostics
#[wasm_bindgen]
pub fn analyze(source: &str) -> JsValue {
    let src = Source::from_string("editor", source.to_string());
    let (program, parse_diagnostics) = parse_source(&src);

    let mut diagnostics: Vec<WasmDiagnostic> = parse_diagnostics
        .iter()
        .map(|d| WasmDiagnostic {
            message: d.message.clone(),
            start: d.span.start,
            end: d.span.end,
            severity: "error".to_string(),
        })
        .collect();

    // Type check if parsing succeeded
    if !parse_diagnostics.has_errors() {
        let mut checker = TypeChecker::new();
        let type_diagnostics = checker.check_program(&program);

        for diag in type_diagnostics.iter() {
            diagnostics.push(WasmDiagnostic {
                message: diag.message.clone(),
                start: diag.span.start,
                end: diag.span.end,
                severity: "error".to_string(),
            });
        }
    }

    let result = AnalysisResult {
        diagnostics: diagnostics.clone(),
        success: diagnostics.is_empty(),
    };

    serde_wasm_bindgen::to_value(&result).unwrap()
}

/// Format source code
#[wasm_bindgen]
pub fn format_code(source: &str) -> JsValue {
    let src = Source::from_string("editor", source.to_string());
    let (program, diagnostics) = parse_source(&src);

    if diagnostics.has_errors() {
        let result = FormatResult {
            formatted: source.to_string(),
            success: false,
            error: Some("Cannot format: parse errors".to_string()),
        };
        return serde_wasm_bindgen::to_value(&result).unwrap();
    }

    let config = FormatConfig::default();
    let formatted = format(&program, &config);

    let result = FormatResult {
        formatted,
        success: true,
        error: None,
    };
    serde_wasm_bindgen::to_value(&result).unwrap()
}

/// Evaluate source code and return the result
#[wasm_bindgen]
pub fn evaluate(source: &str) -> JsValue {
    let src = Source::from_string("editor", source.to_string());
    let (program, diagnostics) = parse_source(&src);

    if diagnostics.has_errors() {
        let result = EvalResult {
            success: false,
            value: None,
            error: Some("Parse errors".to_string()),
        };
        return serde_wasm_bindgen::to_value(&result).unwrap();
    }

    let mut evaluator = Evaluator::new();
    match evaluator.eval_program(&program) {
        Ok(value) => {
            let result = EvalResult {
                success: true,
                value: Some(format!("{:?}", value)),
                error: None,
            };
            serde_wasm_bindgen::to_value(&result).unwrap()
        }
        Err(e) => {
            let result = EvalResult {
                success: false,
                value: None,
                error: Some(e.to_string()),
            };
            serde_wasm_bindgen::to_value(&result).unwrap()
        }
    }
}

/// Render source to MIDI data
#[wasm_bindgen]
pub fn render_midi(source: &str) -> JsValue {
    let src = Source::from_string("editor", source.to_string());
    let (program, diagnostics) = parse_source(&src);

    if diagnostics.has_errors() {
        let result = RenderResult {
            success: false,
            midi_data: None,
            error: Some("Parse errors".to_string()),
        };
        return serde_wasm_bindgen::to_value(&result).unwrap();
    }

    let mut evaluator = Evaluator::new();
    match evaluator.eval_program(&program) {
        Ok(value) => {
            // Create MidiConfig with key from environment if available
            let mut config = MidiConfig::default();
            if let Some(key_note) = get_key_from_evaluator(&evaluator) {
                config.base_note = key_note;
            }
            let renderer = MidiRenderer::new(config);

            // Extract SongValue from the result
            if let Value::Song(song) = value {
                let midi_data = renderer.render(&song);
                let result = RenderResult {
                    success: true,
                    midi_data: Some(midi_data),
                    error: None,
                };
                serde_wasm_bindgen::to_value(&result).unwrap()
            } else {
                // Try to create a song from a block
                let song = create_song_from_value(&value);
                let midi_data = renderer.render(&song);
                let result = RenderResult {
                    success: true,
                    midi_data: Some(midi_data),
                    error: None,
                };
                serde_wasm_bindgen::to_value(&result).unwrap()
            }
        }
        Err(e) => {
            let result = RenderResult {
                success: false,
                midi_data: None,
                error: Some(e.to_string()),
            };
            serde_wasm_bindgen::to_value(&result).unwrap()
        }
    }
}

fn create_song_from_value(value: &Value) -> SongValue {
    use relanote_eval::{PartValue, SectionValue};

    match value {
        Value::Block(block) => SongValue {
            sections: vec![SectionValue {
                name: "Main".to_string(),
                parts: vec![PartValue {
                    instrument: "Piano".to_string(),
                    blocks: vec![block.clone()],
                    envelope: None,
                    reverb_level: None,
                    volume_level: None,
                    synth: None,
                }],
            }],
        },
        Value::Song(song) => song.clone(),
        _ => SongValue { sections: vec![] },
    }
}

/// Get staff notation data for rendering
#[wasm_bindgen]
pub fn get_staff_data(source: &str) -> JsValue {
    let src = Source::from_string("editor", source.to_string());
    let (program, diagnostics) = parse_source(&src);

    if diagnostics.has_errors() {
        // Return empty staff data
        let data = StaffData {
            notes: vec![],
            tempo: 120,
            time_signature_num: 4,
            time_signature_den: 4,
            total_beats: 0.0,
        };
        return serde_wasm_bindgen::to_value(&data).unwrap();
    }

    let mut evaluator = Evaluator::new();
    match evaluator.eval_program(&program) {
        Ok(value) => {
            // Get key from environment (default to C4 = 60 if not specified)
            let base_note = get_key_from_evaluator(&evaluator)
                .map(|n| n as i32)
                .unwrap_or(60);

            // Extract note events from the evaluated value
            let notes = extract_notes_from_value(&value, base_note);
            let total_beats = notes
                .iter()
                .map(|n| n.start + n.duration)
                .fold(0.0, f64::max);

            // Try to get tempo from environment
            let tempo = evaluator
                .get_binding("tempo")
                .and_then(|v| {
                    if let Value::Int(t) = v {
                        Some(t as u32)
                    } else {
                        None
                    }
                })
                .unwrap_or(120);

            let data = StaffData {
                notes,
                tempo,
                time_signature_num: 4,
                time_signature_den: 4,
                total_beats,
            };
            serde_wasm_bindgen::to_value(&data).unwrap()
        }
        Err(_) => {
            let data = StaffData {
                notes: vec![],
                tempo: 120,
                time_signature_num: 4,
                time_signature_den: 4,
                total_beats: 0.0,
            };
            serde_wasm_bindgen::to_value(&data).unwrap()
        }
    }
}

fn extract_notes_from_block(
    block: &relanote_eval::BlockValue,
    velocity: u8,
    start_beat: f64,
    base_note: i32, // MIDI note number for root (60 = C4)
) -> (Vec<NoteEvent>, f64) {
    use relanote_eval::SlotValue;

    let mut notes = Vec::new();
    let mut current_beat = start_beat;

    // Default slot duration (relative rhythm: equal share of block duration)
    let slot_count = block.slots.len();
    let default_beat_duration = if slot_count > 0 {
        block.beats / slot_count as f64
    } else {
        0.0
    };

    for slot in &block.slots {
        // Use explicit duration if set, otherwise use default (relative rhythm)
        let beat_duration = slot.duration_beats().unwrap_or(default_beat_duration);

        match slot {
            SlotValue::Note { interval, .. } => {
                notes.push(NoteEvent {
                    pitch: base_note + interval.semitones().round() as i32,
                    start: current_beat,
                    duration: beat_duration,
                    velocity,
                });
            }
            SlotValue::Chord { intervals, .. } => {
                for interval in intervals {
                    notes.push(NoteEvent {
                        pitch: base_note + interval.semitones().round() as i32,
                        start: current_beat,
                        duration: beat_duration,
                        velocity,
                    });
                }
            }
            SlotValue::Rest { .. } => {}
            SlotValue::Tuplet {
                slots: tuplet_slots,
                target_beats,
            } => {
                // Tuplet: notes are equally divided within target_beats
                let tuplet_slot_count = tuplet_slots.len();
                let tuplet_slot_duration = if tuplet_slot_count > 0 {
                    (*target_beats as f64) / tuplet_slot_count as f64
                } else {
                    0.0
                };
                let mut tuplet_beat = current_beat;
                for slot in tuplet_slots {
                    match slot {
                        SlotValue::Note { interval, .. } => {
                            notes.push(NoteEvent {
                                pitch: base_note + interval.semitones().round() as i32,
                                start: tuplet_beat,
                                duration: tuplet_slot_duration,
                                velocity,
                            });
                        }
                        SlotValue::Chord { intervals, .. } => {
                            for interval in intervals {
                                notes.push(NoteEvent {
                                    pitch: base_note + interval.semitones().round() as i32,
                                    start: tuplet_beat,
                                    duration: tuplet_slot_duration,
                                    velocity,
                                });
                            }
                        }
                        _ => {}
                    }
                    tuplet_beat += tuplet_slot_duration;
                }
            }
        }
        current_beat += beat_duration;
    }

    (notes, current_beat)
}

fn extract_notes_from_value(value: &relanote_eval::Value, base_note: i32) -> Vec<NoteEvent> {
    use relanote_eval::Value;

    let mut notes = Vec::new();

    match value {
        Value::Block(block) => {
            let (block_notes, _) = extract_notes_from_block(block, 100, 0.0, base_note);
            notes.extend(block_notes);
        }
        Value::Song(song) => {
            // Extract notes from all parts in the song
            for section in &song.sections {
                for part in &section.parts {
                    // Skip metronome parts - don't show in notation
                    if part.instrument.to_lowercase().contains("metronome") {
                        continue;
                    }

                    // Calculate velocity from volume_level (default 1.0 = velocity 100)
                    let velocity = part
                        .volume_level
                        .map(|v| ((v * 100.0).round() as u8).clamp(1, 127))
                        .unwrap_or(100);

                    let mut current_beat = 0.0;
                    for block in &part.blocks {
                        let (block_notes, end_beat) =
                            extract_notes_from_block(block, velocity, current_beat, base_note);
                        notes.extend(block_notes);
                        current_beat = end_beat;
                    }
                }
            }
        }
        _ => {}
    }

    notes
}

/// Get syntax highlighting tokens
#[wasm_bindgen]
pub fn get_tokens(source: &str) -> JsValue {
    use relanote_lexer::{Lexer, TokenKind};

    let src = Source::from_string("editor", source.to_string());
    let lexer = Lexer::new(&src);
    let tokens: Vec<_> = lexer.collect();

    #[derive(Serialize)]
    struct TokenInfo {
        start: usize,
        end: usize,
        kind: String,
    }

    let token_infos: Vec<TokenInfo> = tokens
        .iter()
        .map(|t| {
            let kind = match &t.kind {
                TokenKind::Let
                | TokenKind::Set
                | TokenKind::In
                | TokenKind::If
                | TokenKind::Then
                | TokenKind::Else
                | TokenKind::Match
                | TokenKind::With
                | TokenKind::Scale
                | TokenKind::Chord
                | TokenKind::Section
                | TokenKind::Layer
                | TokenKind::Part
                | TokenKind::Env
                | TokenKind::Import
                | TokenKind::Export
                | TokenKind::From
                | TokenKind::As
                | TokenKind::True
                | TokenKind::False
                | TokenKind::Render
                | TokenKind::Context
                | TokenKind::Key => "keyword",
                TokenKind::Integer(_) | TokenKind::Float(_) => "number",
                TokenKind::String(_) => "string",
                TokenKind::Ident(_) => "identifier",
                TokenKind::Interval(_) => "interval",
                TokenKind::AbsolutePitch(_) => "pitch",
                TokenKind::Root => "root",
                TokenKind::Pipe
                | TokenKind::PipeOp
                | TokenKind::Arrow
                | TokenKind::Lambda
                | TokenKind::Eq
                | TokenKind::Colon
                | TokenKind::Comma
                | TokenKind::Dot
                | TokenKind::Minus
                | TokenKind::Plus => "operator",
                TokenKind::Staccato | TokenKind::Accent | TokenKind::Portamento => "articulation",
                TokenKind::LBrace
                | TokenKind::RBrace
                | TokenKind::LBracket
                | TokenKind::RBracket
                | TokenKind::LParen
                | TokenKind::RParen
                | TokenKind::LAngle
                | TokenKind::RAngle => "bracket",
                TokenKind::Bars | TokenKind::Beats => "duration",
                _ => "default",
            };
            TokenInfo {
                start: t.span.start,
                end: t.span.end,
                kind: kind.to_string(),
            }
        })
        .collect();

    serde_wasm_bindgen::to_value(&token_infos).unwrap()
}

/// Convert SynthValue to SynthData for WebAudio
fn synth_value_to_data(synth: &relanote_eval::value::SynthValue) -> SynthData {
    use relanote_eval::value::{FilterType, Waveform};

    let oscillators = synth
        .oscillators
        .iter()
        .map(|osc| {
            let (waveform, pulse_duty) = match &osc.waveform {
                Waveform::Sine => ("sine".to_string(), 0.0),
                Waveform::Square => ("square".to_string(), 0.5),
                Waveform::Saw => ("sawtooth".to_string(), 0.0),
                Waveform::Triangle => ("triangle".to_string(), 0.0),
                Waveform::Noise => ("noise".to_string(), 0.0),
                Waveform::Pulse(duty) => ("pulse".to_string(), *duty),
            };
            OscillatorData {
                waveform,
                pulse_duty,
                mix: osc.mix,
                octave_offset: osc.octave_offset,
                detune_cents: osc.detune_cents,
            }
        })
        .collect();

    let envelope = ADSRData {
        attack: synth.envelope.attack,
        decay: synth.envelope.decay,
        sustain: synth.envelope.sustain,
        release: synth.envelope.release,
    };

    let filter = synth.filter.as_ref().map(|f| {
        let filter_type = match f.filter_type {
            FilterType::LowPass => "lowpass".to_string(),
            FilterType::HighPass => "highpass".to_string(),
            FilterType::BandPass => "bandpass".to_string(),
        };
        FilterData {
            filter_type,
            cutoff: f.cutoff,
            resonance: f.resonance,
        }
    });

    let pitch_envelope = synth.pitch_envelope.map(|(start, end, time)| PitchEnvelopeData {
        start_hz: start,
        end_hz: end,
        time_seconds: time,
    });

    SynthData {
        name: synth.name.clone(),
        oscillators,
        envelope,
        filter,
        detune_cents: synth.detune_cents,
        pitch_envelope,
    }
}

/// Extract audio notes with synth data from a part
fn extract_audio_notes_from_part(
    part: &relanote_eval::PartValue,
    start_beat: f64,
    base_note: i32, // MIDI note number for root (60 = C4)
) -> (Vec<AudioNoteEvent>, f64) {
    use relanote_eval::SlotValue;

    let mut notes = Vec::new();
    let mut current_beat = start_beat;

    // Get synth data if available
    let synth_data = part.synth.as_ref().map(synth_value_to_data);

    // Calculate velocity from volume_level
    let velocity = part
        .volume_level
        .map(|v| ((v * 100.0).round() as u8).clamp(1, 127))
        .unwrap_or(100);

    for block in &part.blocks {
        let slot_count = block.slots.len();
        let default_beat_duration = if slot_count > 0 {
            block.beats / slot_count as f64
        } else {
            0.0
        };

        for slot in &block.slots {
            let beat_duration = slot.duration_beats().unwrap_or(default_beat_duration);

            match slot {
                SlotValue::Note { interval, .. } => {
                    notes.push(AudioNoteEvent {
                        pitch: base_note + interval.semitones().round() as i32,
                        start: current_beat,
                        duration: beat_duration,
                        velocity,
                        synth: synth_data.clone(),
                    });
                }
                SlotValue::Chord { intervals, .. } => {
                    for interval in intervals {
                        notes.push(AudioNoteEvent {
                            pitch: base_note + interval.semitones().round() as i32,
                            start: current_beat,
                            duration: beat_duration,
                            velocity,
                            synth: synth_data.clone(),
                        });
                    }
                }
                SlotValue::Rest { .. } => {}
                SlotValue::Tuplet {
                    slots: tuplet_slots,
                    target_beats,
                } => {
                    let tuplet_slot_count = tuplet_slots.len();
                    let tuplet_slot_duration = if tuplet_slot_count > 0 {
                        (*target_beats as f64) / tuplet_slot_count as f64
                    } else {
                        0.0
                    };
                    let mut tuplet_beat = current_beat;
                    for inner_slot in tuplet_slots {
                        match inner_slot {
                            SlotValue::Note { interval, .. } => {
                                notes.push(AudioNoteEvent {
                                    pitch: base_note + interval.semitones().round() as i32,
                                    start: tuplet_beat,
                                    duration: tuplet_slot_duration,
                                    velocity,
                                    synth: synth_data.clone(),
                                });
                            }
                            SlotValue::Chord { intervals, .. } => {
                                for interval in intervals {
                                    notes.push(AudioNoteEvent {
                                        pitch: base_note + interval.semitones().round() as i32,
                                        start: tuplet_beat,
                                        duration: tuplet_slot_duration,
                                        velocity,
                                        synth: synth_data.clone(),
                                    });
                                }
                            }
                            _ => {}
                        }
                        tuplet_beat += tuplet_slot_duration;
                    }
                }
            }
            current_beat += beat_duration;
        }
    }

    (notes, current_beat)
}

/// Note data from piano roll for code generation
#[derive(Serialize, Deserialize, Clone)]
pub struct PianoRollNote {
    pub pitch: i32,      // MIDI note (0-127)
    pub start: f64,      // Start time in beats
    pub duration: f64,   // Duration in beats
    pub velocity: u8,    // 0-127
}

/// Generate Relanote code from piano roll notes
#[wasm_bindgen]
pub fn notes_to_code(notes_json: &str, synth_name: Option<String>, key_pitch: Option<i32>) -> String {
    let notes: Vec<PianoRollNote> = match serde_json::from_str(notes_json) {
        Ok(n) => n,
        Err(_) => return "".to_string(),
    };

    if notes.is_empty() {
        return "| - |".to_string();
    }

    // Default key is C4 (MIDI 60)
    let base_pitch = key_pitch.unwrap_or(60);

    // Group notes by start time
    let mut time_groups: std::collections::BTreeMap<i64, Vec<&PianoRollNote>> = std::collections::BTreeMap::new();
    for note in &notes {
        // Round to 1/16 beat precision
        let start_key = (note.start * 16.0).round() as i64;
        time_groups.entry(start_key).or_default().push(note);
    }

    // Find the total duration
    let total_beats = notes.iter()
        .map(|n| n.start + n.duration)
        .fold(0.0_f64, f64::max);

    // Calculate number of bars (4 beats per bar)
    let num_bars = ((total_beats / 4.0).ceil() as i32).max(1);

    let mut result = String::new();

    // Generate bars
    for bar in 0..num_bars {
        let bar_start = bar as f64 * 4.0;
        let bar_end = bar_start + 4.0;

        result.push_str("| ");

        // Collect notes in this bar
        let mut bar_slots: Vec<String> = Vec::new();
        let mut current_time = bar_start;

        // Find all unique time points in this bar
        let mut time_points: Vec<f64> = time_groups.keys()
            .map(|k| *k as f64 / 16.0)
            .filter(|t| *t >= bar_start && *t < bar_end)
            .collect();
        time_points.sort_by(|a, b| a.partial_cmp(b).unwrap());
        time_points.dedup_by(|a, b| (*a - *b).abs() < 0.001);

        if time_points.is_empty() {
            // Empty bar - add rests
            bar_slots.push("-".to_string());
        } else {
            for &time in &time_points {
                // Add rest if there's a gap
                if time > current_time + 0.001 {
                    let gap = time - current_time;
                    if gap >= 1.0 {
                        bar_slots.push(format!("-:{}", gap));
                    } else {
                        bar_slots.push("-".to_string());
                    }
                }

                let key = (time * 16.0).round() as i64;
                if let Some(notes_at_time) = time_groups.get(&key) {
                    if notes_at_time.len() == 1 {
                        // Single note
                        let note = notes_at_time[0];
                        let interval = pitch_to_interval(note.pitch, base_pitch);
                        if note.duration >= 1.0 && (note.duration - note.duration.round()).abs() < 0.001 {
                            bar_slots.push(format!("{}:{}", interval, note.duration.round() as i32));
                        } else {
                            bar_slots.push(interval);
                        }
                        current_time = time + note.duration;
                    } else {
                        // Chord
                        let intervals: Vec<String> = notes_at_time.iter()
                            .map(|n| pitch_to_interval(n.pitch, base_pitch))
                            .collect();
                        let duration = notes_at_time[0].duration;
                        let chord_str = format!("[{}]", intervals.join(" "));
                        if duration >= 1.0 && (duration - duration.round()).abs() < 0.001 {
                            bar_slots.push(format!("{}:{}", chord_str, duration.round() as i32));
                        } else {
                            bar_slots.push(chord_str);
                        }
                        current_time = time + duration;
                    }
                }
            }
        }

        result.push_str(&bar_slots.join(" "));
        result.push_str(" |");

        if bar < num_bars - 1 {
            result.push_str(" ++ ");
        }
    }

    // Add synth voice if specified
    if let Some(synth) = synth_name {
        if !synth.is_empty() && synth != "Default" {
            result = format!("{} |> voice {}", result, synth);
        }
    }

    result
}

/// Convert MIDI pitch to interval notation
fn pitch_to_interval(midi_pitch: i32, base_pitch: i32) -> String {
    let semitones = midi_pitch - base_pitch;

    // Common intervals
    match semitones {
        0 => "R".to_string(),
        1 => "m2".to_string(),
        2 => "M2".to_string(),
        3 => "m3".to_string(),
        4 => "M3".to_string(),
        5 => "P4".to_string(),
        6 => "d5".to_string(),
        7 => "P5".to_string(),
        8 => "m6".to_string(),
        9 => "M6".to_string(),
        10 => "m7".to_string(),
        11 => "M7".to_string(),
        12 => "P8".to_string(),
        _ if semitones > 12 => {
            let octaves = semitones / 12;
            let remainder = semitones % 12;
            let base_interval = pitch_to_interval(base_pitch + remainder, base_pitch);
            format!("{}+{}", base_interval, octaves)
        }
        _ if semitones < 0 => {
            let octaves = (-semitones) / 12;
            let remainder = 12 - ((-semitones) % 12);
            if remainder == 12 {
                format!("R-{}", octaves)
            } else {
                let base_interval = pitch_to_interval(base_pitch + remainder, base_pitch);
                format!("{}-{}", base_interval, octaves + 1)
            }
        }
        _ => format!("{}st", semitones),
    }
}

/// Get audio playback data including synth information
#[wasm_bindgen]
pub fn get_audio_data(source: &str) -> JsValue {
    let src = Source::from_string("editor", source.to_string());
    let (program, diagnostics) = parse_source(&src);

    if diagnostics.has_errors() {
        let data = AudioPlaybackData {
            notes: vec![],
            tempo: 120,
            total_beats: 0.0,
        };
        return serde_wasm_bindgen::to_value(&data).unwrap();
    }

    let mut evaluator = Evaluator::new();
    match evaluator.eval_program(&program) {
        Ok(value) => {
            // Get key from environment (default to C4 = 60 if not specified)
            let base_note = get_key_from_evaluator(&evaluator)
                .map(|n| n as i32)
                .unwrap_or(60);

            let mut all_notes = Vec::new();

            match &value {
                Value::Block(block) => {
                    // Create a default part for a single block
                    let part = relanote_eval::PartValue {
                        instrument: "Default".to_string(),
                        blocks: vec![block.clone()],
                        envelope: None,
                        reverb_level: None,
                        volume_level: None,
                        synth: None,
                    };
                    let (notes, _) = extract_audio_notes_from_part(&part, 0.0, base_note);
                    all_notes.extend(notes);
                }
                Value::Song(song) => {
                    for section in &song.sections {
                        for part in &section.parts {
                            // Skip metronome parts
                            if part.instrument.to_lowercase().contains("metronome") {
                                continue;
                            }
                            let (notes, _) = extract_audio_notes_from_part(part, 0.0, base_note);
                            all_notes.extend(notes);
                        }
                    }
                }
                _ => {}
            }

            let total_beats = all_notes
                .iter()
                .map(|n| n.start + n.duration)
                .fold(0.0, f64::max);

            let tempo = evaluator
                .get_binding("tempo")
                .and_then(|v| {
                    if let Value::Int(t) = v {
                        Some(t as u32)
                    } else {
                        None
                    }
                })
                .unwrap_or(120);

            let data = AudioPlaybackData {
                notes: all_notes,
                tempo,
                total_beats,
            };
            serde_wasm_bindgen::to_value(&data).unwrap()
        }
        Err(_) => {
            let data = AudioPlaybackData {
                notes: vec![],
                tempo: 120,
                total_beats: 0.0,
            };
            serde_wasm_bindgen::to_value(&data).unwrap()
        }
    }
}
