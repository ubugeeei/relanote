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
    pub start_hz: f64,     // Starting frequency in Hz
    pub end_hz: f64,       // Ending frequency in Hz
    pub time_seconds: f64, // Duration of the pitch sweep
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

    let pitch_envelope = synth
        .pitch_envelope
        .map(|(start, end, time)| PitchEnvelopeData {
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
    pub pitch: i32,    // MIDI note (0-127)
    pub start: f64,    // Start time in beats
    pub duration: f64, // Duration in beats
    pub velocity: u8,  // 0-127
}

/// Generate Relanote code from piano roll notes
#[wasm_bindgen]
pub fn notes_to_code(
    notes_json: &str,
    synth_name: Option<String>,
    key_pitch: Option<i32>,
) -> String {
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
    let mut time_groups: std::collections::BTreeMap<i64, Vec<&PianoRollNote>> =
        std::collections::BTreeMap::new();
    for note in &notes {
        // Round to 1/16 beat precision
        let start_key = (note.start * 16.0).round() as i64;
        time_groups.entry(start_key).or_default().push(note);
    }

    // Find the total duration
    let total_beats = notes
        .iter()
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
        let mut time_points: Vec<f64> = time_groups
            .keys()
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
                        if note.duration >= 1.0
                            && (note.duration - note.duration.round()).abs() < 0.001
                        {
                            bar_slots.push(format!(
                                "{}:{}",
                                interval,
                                note.duration.round() as i32
                            ));
                        } else {
                            bar_slots.push(interval);
                        }
                        current_time = time + note.duration;
                    } else {
                        // Chord
                        let intervals: Vec<String> = notes_at_time
                            .iter()
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

// =============================================================================
// LSP-like functionality for Monaco editor integration
// =============================================================================

/// Completion item for the editor
#[derive(Serialize, Deserialize, Clone)]
pub struct CompletionItem {
    pub label: String,
    pub kind: String, // "keyword" | "function" | "constant" | "property" | "class" | "enum_member" | "snippet"
    pub detail: String,
    pub insert_text: Option<String>,
}

/// Get all completion items
#[wasm_bindgen]
pub fn get_completions() -> JsValue {
    let mut completions = Vec::new();

    // Keywords
    let keywords = [
        ("scale", "Define a scale"),
        ("chord", "Define a chord"),
        ("let", "Define a binding"),
        ("in", "Local binding scope"),
        ("section", "Define a section"),
        ("layer", "Combine multiple parts"),
        ("part", "Define a part"),
        ("if", "Conditional expression"),
        ("then", "Then branch"),
        ("else", "Else branch"),
        ("match", "Pattern matching"),
        ("with", "Match patterns"),
        ("set", "Set global property"),
        ("import", "Import module"),
        ("export", "Export binding"),
        ("from", "Import source"),
        ("as", "Alias"),
        ("true", "Boolean true"),
        ("false", "Boolean false"),
    ];
    for (label, detail) in keywords {
        completions.push(CompletionItem {
            label: label.to_string(),
            kind: "keyword".to_string(),
            detail: detail.to_string(),
            insert_text: None,
        });
    }

    // Set statements
    let set_items = [
        ("set tempo = ", "Set tempo (BPM)", "set tempo = ${1:120}"),
        ("set key = ", "Set key (e.g., C4, D#3)", "set key = ${1:C4}"),
    ];
    for (label, detail, insert) in set_items {
        completions.push(CompletionItem {
            label: label.to_string(),
            kind: "snippet".to_string(),
            detail: detail.to_string(),
            insert_text: Some(insert.to_string()),
        });
    }

    // Built-in functions
    let functions = [
        ("reverse", "Reverse a block"),
        ("transpose", "Transpose by an interval"),
        ("repeat", "Repeat n times"),
        ("volume", "Set volume (0.0-1.0)"),
        ("reverb", "Apply reverb (0.0-1.0)"),
        ("hall_reverb", "Hall reverb preset"),
        ("room_reverb", "Room reverb preset"),
        ("plate_reverb", "Plate reverb preset"),
        ("dry", "No reverb"),
        ("voice", "Set instrument voice"),
        ("swing", "Apply swing feel"),
        ("double_time", "Double tempo"),
        ("half_time", "Half tempo"),
        ("metronome", "Generate metronome"),
        ("cutoff", "Filter cutoff frequency"),
        ("pan", "Stereo pan (-1.0 to 1.0)"),
        ("delay", "Apply delay effect"),
        ("stretch", "Time stretch"),
        ("compress", "Time compress"),
        ("quantize", "Quantize to note value"),
        ("invert", "Invert intervals"),
        ("retrograde", "Retrograde melody"),
        ("shuffle", "Shuffle notes"),
    ];
    for (label, detail) in functions {
        completions.push(CompletionItem {
            label: label.to_string(),
            kind: "function".to_string(),
            detail: detail.to_string(),
            insert_text: None,
        });
    }

    // Voice/Instruments
    let voices = [
        // 8-bit / Chiptune
        ("NES", "NES pulse wave"),
        ("GameBoy", "GameBoy sound"),
        ("Chiptune", "Classic chiptune"),
        ("Chip8bit", "8-bit chip sound"),
        ("C64", "Commodore 64 SID"),
        ("Retro", "Retro game sound"),
        ("Arcade", "Arcade game sound"),
        // Drums
        ("Kick8bit", "8-bit kick drum"),
        ("Snare8bit", "8-bit snare drum"),
        ("HiHat8bit", "8-bit hi-hat"),
        ("Clap8bit", "8-bit clap"),
        ("Kick", "Kick drum"),
        ("Snare", "Snare drum"),
        ("HiHat", "Hi-hat"),
        ("Clap", "Clap sound"),
        ("Tom", "Tom drum"),
        // Bass
        ("FatBass", "Fat bass synth"),
        ("SubBass", "Sub bass"),
        ("AcidBass", "Acid bass (303-style)"),
        ("SynthBass", "Synth bass"),
        ("PluckBass", "Plucked bass"),
        ("Bass", "Basic bass"),
        // Synths
        ("Sine", "Pure sine wave"),
        ("Square", "Square wave"),
        ("Sawtooth", "Sawtooth wave"),
        ("Triangle", "Triangle wave"),
        ("SawLead", "Saw wave lead"),
        ("SquareLead", "Square wave lead"),
        ("SineLead", "Sine wave lead"),
        ("SuperSaw", "Super saw"),
        ("Synth", "Basic synth"),
        ("SynthLead", "Lead synth"),
        ("SynthPad", "Pad synth"),
        ("Pad", "Pad synth"),
        ("DarkPad", "Dark pad"),
        ("FMSynth", "FM synthesis"),
        ("AnalogSynth", "Analog-style synth"),
        // Keyboard
        ("Piano", "Acoustic piano"),
        ("ElectricPiano", "Electric piano"),
        ("EPiano", "Electric piano"),
        ("Rhodes", "Rhodes piano"),
        ("Organ", "Organ"),
        ("Harpsichord", "Harpsichord"),
        // Strings/Brass
        ("String", "String ensemble"),
        ("Brass", "Brass section"),
        // Pluck
        ("Guitar", "Acoustic guitar"),
        ("ElectricGuitar", "Electric guitar"),
        ("Pluck", "Plucked string"),
        ("Bell", "Bell sound"),
        ("Marimba", "Marimba"),
        ("Vibraphone", "Vibraphone"),
        // Special
        ("Noise", "Noise generator"),
        ("WhiteNoise", "White noise"),
    ];
    for (label, detail) in voices {
        completions.push(CompletionItem {
            label: label.to_string(),
            kind: "enum_member".to_string(),
            detail: format!("Voice: {}", detail),
            insert_text: None,
        });
    }

    // Intervals
    let intervals = [
        ("R", "Root / Unison (0 semitones)"),
        ("P1", "Perfect Unison (0 semitones)"),
        ("m2", "Minor Second (1 semitone)"),
        ("M2", "Major Second (2 semitones)"),
        ("m3", "Minor Third (3 semitones)"),
        ("M3", "Major Third (4 semitones)"),
        ("P4", "Perfect Fourth (5 semitones)"),
        ("A4", "Augmented Fourth (6 semitones)"),
        ("d5", "Diminished Fifth (6 semitones)"),
        ("P5", "Perfect Fifth (7 semitones)"),
        ("m6", "Minor Sixth (8 semitones)"),
        ("M6", "Major Sixth (9 semitones)"),
        ("m7", "Minor Seventh (10 semitones)"),
        ("M7", "Major Seventh (11 semitones)"),
        ("P8", "Perfect Octave (12 semitones)"),
        ("m9", "Minor Ninth (13 semitones)"),
        ("M9", "Major Ninth (14 semitones)"),
        ("m10", "Minor Tenth (15 semitones)"),
        ("M10", "Major Tenth (16 semitones)"),
        ("P11", "Perfect Eleventh (17 semitones)"),
        ("P12", "Perfect Twelfth (19 semitones)"),
        ("M13", "Major Thirteenth (21 semitones)"),
        ("M14", "Major Fourteenth (23 semitones)"),
        ("P15", "Perfect Fifteenth (24 semitones)"),
    ];
    for (label, detail) in intervals {
        completions.push(CompletionItem {
            label: label.to_string(),
            kind: "constant".to_string(),
            detail: detail.to_string(),
            insert_text: None,
        });
    }

    // Scales
    let scales = [
        ("Major", "Major scale { R, M2, M3, P4, P5, M6, M7 }"),
        ("Minor", "Natural minor { R, M2, m3, P4, P5, m6, m7 }"),
        (
            "HarmonicMinor",
            "Harmonic minor { R, M2, m3, P4, P5, m6, M7 }",
        ),
        (
            "MelodicMinor",
            "Melodic minor { R, M2, m3, P4, P5, M6, M7 }",
        ),
        ("Dorian", "Dorian mode { R, M2, m3, P4, P5, M6, m7 }"),
        ("Phrygian", "Phrygian mode { R, m2, m3, P4, P5, m6, m7 }"),
        ("Lydian", "Lydian mode { R, M2, M3, A4, P5, M6, M7 }"),
        (
            "Mixolydian",
            "Mixolydian mode { R, M2, M3, P4, P5, M6, m7 }",
        ),
        ("Locrian", "Locrian mode { R, m2, m3, P4, d5, m6, m7 }"),
        ("MajorPentatonic", "Major pentatonic { R, M2, M3, P5, M6 }"),
        ("MinorPentatonic", "Minor pentatonic { R, m3, P4, P5, m7 }"),
        ("Blues", "Blues scale { R, m3, P4, d5, P5, m7 }"),
        ("WholeTone", "Whole tone { R, M2, M3, A4, A5, A6 }"),
        ("Chromatic", "Chromatic scale (all 12 tones)"),
    ];
    for (label, detail) in scales {
        completions.push(CompletionItem {
            label: label.to_string(),
            kind: "class".to_string(),
            detail: format!("Scale: {}", detail),
            insert_text: None,
        });
    }

    // Chords
    let chords = [
        ("MajorTriad", "Major triad { R, M3, P5 }"),
        ("MinorTriad", "Minor triad { R, m3, P5 }"),
        ("Diminished", "Diminished { R, m3, d5 }"),
        ("Augmented", "Augmented { R, M3, A5 }"),
        ("Major7", "Major 7th { R, M3, P5, M7 }"),
        ("Minor7", "Minor 7th { R, m3, P5, m7 }"),
        ("Dominant7", "Dominant 7th { R, M3, P5, m7 }"),
        ("MinorMajor7", "Minor-major 7th { R, m3, P5, M7 }"),
        ("HalfDiminished7", "Half-diminished { R, m3, d5, m7 }"),
        ("Diminished7", "Diminished 7th { R, m3, d5, d7 }"),
        ("Sus2", "Suspended 2nd { R, M2, P5 }"),
        ("Sus4", "Suspended 4th { R, P4, P5 }"),
        ("Add9", "Add 9 { R, M3, P5, M9 }"),
        ("Add11", "Add 11 { R, M3, P5, P11 }"),
        ("Power", "Power chord { R, P5 }"),
    ];
    for (label, detail) in chords {
        completions.push(CompletionItem {
            label: label.to_string(),
            kind: "class".to_string(),
            detail: format!("Chord: {}", detail),
            insert_text: None,
        });
    }

    // Dynamics
    let dynamics = [
        ("ppp", "Pianississimo (very very soft)"),
        ("pp", "Pianissimo (very soft)"),
        ("p", "Piano (soft)"),
        ("mp", "Mezzo-piano (moderately soft)"),
        ("mf", "Mezzo-forte (moderately loud)"),
        ("f", "Forte (loud)"),
        ("ff", "Fortissimo (very loud)"),
        ("fff", "Fortississimo (very very loud)"),
        ("sfz", "Sforzando (sudden accent)"),
        ("fp", "Forte-piano (loud then soft)"),
    ];
    for (label, detail) in dynamics {
        completions.push(CompletionItem {
            label: label.to_string(),
            kind: "property".to_string(),
            detail: format!("Dynamic: {}", detail),
            insert_text: None,
        });
    }

    // Articulations
    let articulations = [
        ("staccato", "Short, detached notes"),
        ("legato", "Smooth, connected notes"),
        ("accent", "Emphasized notes"),
        ("tenuto", "Held full duration"),
        ("portamento", "Sliding between notes"),
    ];
    for (label, detail) in articulations {
        completions.push(CompletionItem {
            label: label.to_string(),
            kind: "property".to_string(),
            detail: format!("Articulation: {}", detail),
            insert_text: None,
        });
    }

    serde_wasm_bindgen::to_value(&completions).unwrap()
}

/// Hover information result
#[derive(Serialize, Deserialize)]
pub struct HoverResult {
    pub found: bool,
    pub content: Option<String>,
    pub start: usize,
    pub end: usize,
}

/// Get hover information at a position
#[wasm_bindgen]
pub fn get_hover(source: &str, offset: usize) -> JsValue {
    use relanote_lexer::{Lexer, TokenKind};

    let src = Source::from_string("editor", source.to_string());
    let lexer = Lexer::new(&src);
    let tokens: Vec<_> = lexer.collect();

    for token in &tokens {
        if token.span.start <= offset && offset <= token.span.end {
            let hover_content = match &token.kind {
                TokenKind::Ident(name) => get_builtin_hover(name),
                TokenKind::Interval(interval) => {
                    let semitones = interval_to_semitones(interval);
                    let name = interval_data_to_name(interval);
                    Some(format!("**Interval**: {} ({} semitones)", name, semitones))
                }
                TokenKind::AbsolutePitch(pitch) => {
                    let midi = pitch.to_midi_note();
                    let acc_str = match pitch.accidental {
                        1 => "#",
                        -1 => "b",
                        _ => "",
                    };
                    Some(format!("**Absolute Pitch**: {}{}{} (MIDI {})",
                        pitch.note, acc_str, pitch.octave, midi))
                }
                TokenKind::Root => Some("**Root** (R): The root/unison of the current scale (0 semitones)".to_string()),
                TokenKind::Let => Some("**let**: Define a variable binding\n\n```rela\nlet name = value\nlet name = value in expr\n```".to_string()),
                TokenKind::Set => Some("**set**: Set a global property\n\n```rela\nset tempo = 120\nset key = C4\n```".to_string()),
                TokenKind::Scale => Some("**scale**: Define a named scale\n\n```rela\nscale Major = { R, M2, M3, P4, P5, M6, M7 }\n```".to_string()),
                TokenKind::Chord => Some("**chord**: Define a named chord\n\n```rela\nchord Maj = { R, M3, P5 }\n```".to_string()),
                TokenKind::Layer => Some("**layer**: Combine multiple parts (polyphony)\n\n```rela\nlayer [\n  melody,\n  bass\n]\n```".to_string()),
                TokenKind::Section => Some("**section**: Define a song section".to_string()),
                TokenKind::Part => Some("**part**: Define an instrument part".to_string()),
                TokenKind::PipeOp => Some("**|>**: Pipe operator - applies a function to the left operand".to_string()),
                TokenKind::Pipe => Some("**|**: Bar/block delimiter".to_string()),
                _ => None,
            };

            if let Some(content) = hover_content {
                let result = HoverResult {
                    found: true,
                    content: Some(content),
                    start: token.span.start,
                    end: token.span.end,
                };
                return serde_wasm_bindgen::to_value(&result).unwrap();
            }
        }
    }

    let result = HoverResult {
        found: false,
        content: None,
        start: 0,
        end: 0,
    };
    serde_wasm_bindgen::to_value(&result).unwrap()
}

/// Get hover documentation for builtin identifiers
fn get_builtin_hover(name: &str) -> Option<String> {
    match name {
        // Functions
        "transpose" => Some("**transpose**: Transpose notes by an interval\n\n```rela\nblock |> transpose P8  ; up one octave\nblock |> transpose (R - P8)  ; down one octave\n```".to_string()),
        "reverse" => Some("**reverse**: Reverse the order of notes in a block".to_string()),
        "repeat" => Some("**repeat**: Repeat a block N times\n\n```rela\nblock |> repeat 4\n```".to_string()),
        "volume" => Some("**volume**: Set the volume level (0.0-1.0)\n\n```rela\nblock |> volume 0.8\n```".to_string()),
        "reverb" => Some("**reverb**: Apply reverb effect (0.0-1.0)\n\n```rela\nblock |> reverb 0.3\n```".to_string()),
        "voice" => Some("**voice**: Set the instrument/synth voice\n\n```rela\nblock |> voice NES\nblock |> voice Piano\n```".to_string()),
        "in" => Some("**in**: Apply a scale to a block\n\n```rela\nblock |> in Major\nblock |> in MinorPentatonic\n```".to_string()),
        "pan" => Some("**pan**: Set stereo pan (-1.0 left to 1.0 right)\n\n```rela\nblock |> pan -0.5  ; left\nblock |> pan 0.5   ; right\n```".to_string()),
        "delay" => Some("**delay**: Apply delay effect (0.0-1.0)".to_string()),
        "swing" => Some("**swing**: Apply swing feel (0.5 straight to 0.67 triplet)".to_string()),
        "double_time" => Some("**double_time**: Double the tempo".to_string()),
        "half_time" => Some("**half_time**: Halve the tempo".to_string()),
        "metronome" => Some("**metronome**: Generate a metronome click track".to_string()),
        // Voices
        "NES" => Some("**NES**: NES-style 8-bit pulse wave synthesizer".to_string()),
        "GameBoy" => Some("**GameBoy**: GameBoy-style 8-bit sound".to_string()),
        "Chiptune" => Some("**Chiptune**: Classic 8-bit chiptune sound".to_string()),
        "Chip8bit" => Some("**Chip8bit**: Generic 8-bit chip sound".to_string()),
        "Kick8bit" => Some("**Kick8bit**: 8-bit style kick drum".to_string()),
        "Snare8bit" => Some("**Snare8bit**: 8-bit style snare drum".to_string()),
        "HiHat8bit" => Some("**HiHat8bit**: 8-bit style hi-hat".to_string()),
        "FatBass" => Some("**FatBass**: Fat/thick bass synthesizer".to_string()),
        "Piano" => Some("**Piano**: Acoustic piano sound".to_string()),
        "Sine" => Some("**Sine**: Pure sine wave oscillator".to_string()),
        "Square" => Some("**Square**: Square wave oscillator".to_string()),
        "Sawtooth" => Some("**Sawtooth**: Sawtooth wave oscillator".to_string()),
        "Triangle" => Some("**Triangle**: Triangle wave oscillator".to_string()),
        // Scales
        "Major" => Some("**Major Scale**: { R, M2, M3, P4, P5, M6, M7 }\n\nThe major scale (Ionian mode).".to_string()),
        "Minor" => Some("**Minor Scale**: { R, M2, m3, P4, P5, m6, m7 }\n\nThe natural minor scale (Aeolian mode).".to_string()),
        "Dorian" => Some("**Dorian Mode**: { R, M2, m3, P4, P5, M6, m7 }\n\nMinor scale with raised 6th.".to_string()),
        "Phrygian" => Some("**Phrygian Mode**: { R, m2, m3, P4, P5, m6, m7 }\n\nMinor scale with lowered 2nd.".to_string()),
        "Lydian" => Some("**Lydian Mode**: { R, M2, M3, A4, P5, M6, M7 }\n\nMajor scale with raised 4th.".to_string()),
        "Mixolydian" => Some("**Mixolydian Mode**: { R, M2, M3, P4, P5, M6, m7 }\n\nMajor scale with lowered 7th.".to_string()),
        "Blues" => Some("**Blues Scale**: { R, m3, P4, d5, P5, m7 }\n\nMinor pentatonic with added blue note.".to_string()),
        "MajorPentatonic" => Some("**Major Pentatonic**: { R, M2, M3, P5, M6 }\n\n5-note major scale.".to_string()),
        "MinorPentatonic" => Some("**Minor Pentatonic**: { R, m3, P4, P5, m7 }\n\n5-note minor scale.".to_string()),
        _ => None,
    }
}

/// Convert IntervalData to semitones
fn interval_to_semitones(interval: &relanote_lexer::token::IntervalData) -> i32 {
    use relanote_lexer::token::{Accidental, IntervalQuality};

    let base = match (interval.quality, interval.degree) {
        (IntervalQuality::Perfect, 1) => 0,
        (IntervalQuality::Minor, 2) => 1,
        (IntervalQuality::Major, 2) => 2,
        (IntervalQuality::Minor, 3) => 3,
        (IntervalQuality::Major, 3) => 4,
        (IntervalQuality::Perfect, 4) => 5,
        (IntervalQuality::Augmented, 4) => 6,
        (IntervalQuality::Diminished, 5) => 6,
        (IntervalQuality::Perfect, 5) => 7,
        (IntervalQuality::Minor, 6) => 8,
        (IntervalQuality::Major, 6) => 9,
        (IntervalQuality::Minor, 7) => 10,
        (IntervalQuality::Major, 7) => 11,
        (IntervalQuality::Perfect, 8) => 12,
        (IntervalQuality::Minor, 9) => 13,
        (IntervalQuality::Major, 9) => 14,
        (IntervalQuality::Minor, 10) => 15,
        (IntervalQuality::Major, 10) => 16,
        (IntervalQuality::Perfect, 11) => 17,
        (IntervalQuality::Perfect, 12) => 19,
        (IntervalQuality::Major, 13) => 21,
        (IntervalQuality::Major, 14) => 23,
        (IntervalQuality::Perfect, 15) => 24,
        _ => 0,
    };

    let acc_offset: i32 = interval
        .accidentals
        .iter()
        .map(|a| match a {
            Accidental::Sharp => 1,
            Accidental::Flat => -1,
        })
        .sum();

    base + acc_offset
}

/// Get interval name from IntervalData
fn interval_data_to_name(interval: &relanote_lexer::token::IntervalData) -> String {
    use relanote_lexer::token::IntervalQuality;

    let quality = match interval.quality {
        IntervalQuality::Perfect => "Perfect",
        IntervalQuality::Major => "Major",
        IntervalQuality::Minor => "Minor",
        IntervalQuality::Augmented => "Augmented",
        IntervalQuality::Diminished => "Diminished",
    };

    let degree_name = match interval.degree {
        1 => "Unison",
        2 => "Second",
        3 => "Third",
        4 => "Fourth",
        5 => "Fifth",
        6 => "Sixth",
        7 => "Seventh",
        8 => "Octave",
        9 => "Ninth",
        10 => "Tenth",
        11 => "Eleventh",
        12 => "Twelfth",
        13 => "Thirteenth",
        14 => "Fourteenth",
        15 => "Fifteenth",
        _ => "Interval",
    };

    format!("{} {}", quality, degree_name)
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
