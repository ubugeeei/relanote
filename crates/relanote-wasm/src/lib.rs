//! WebAssembly bindings for relanote

use serde::{Deserialize, Serialize};
use wasm_bindgen::prelude::*;

use relanote_core::Source;
use relanote_eval::{Evaluator, SongValue, Value};
use relanote_format::{format, FormatConfig};
use relanote_parser::parse_source;
use relanote_render::{MidiConfig, MidiRenderer};
use relanote_types::TypeChecker;

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
    pub pitch: i32,      // MIDI pitch (60 = C4)
    pub start: f64,      // Start time in beats
    pub duration: f64,   // Duration in beats
    pub velocity: u8,    // Velocity (0-127)
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
            // Extract SongValue from the result
            if let Value::Song(song) = value {
                let renderer = MidiRenderer::new(MidiConfig::default());
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
                let renderer = MidiRenderer::new(MidiConfig::default());
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
            // Extract note events from the evaluated value
            let notes = extract_notes_from_value(&value);
            let total_beats = notes.iter().map(|n| n.start + n.duration).fold(0.0, f64::max);

            let data = StaffData {
                notes,
                tempo: 120,
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

fn extract_notes_from_value(value: &relanote_eval::Value) -> Vec<NoteEvent> {
    use relanote_eval::{SlotValue, Value};

    let mut notes = Vec::new();
    let mut current_beat = 0.0;

    match value {
        Value::Block(block) => {
            let beat_duration = 1.0; // Each slot is one beat
            for slot in &block.slots {
                match slot {
                    SlotValue::Note { interval, .. } => {
                        notes.push(NoteEvent {
                            pitch: 60 + interval.semitones, // C4 as base
                            start: current_beat,
                            duration: beat_duration,
                            velocity: 100,
                        });
                    }
                    SlotValue::Chord { intervals, .. } => {
                        for interval in intervals {
                            notes.push(NoteEvent {
                                pitch: 60 + interval.semitones,
                                start: current_beat,
                                duration: beat_duration,
                                velocity: 100,
                            });
                        }
                    }
                    SlotValue::Rest => {}
                    SlotValue::Tuplet { slots, .. } => {
                        // Handle tuplet recursively
                        for slot in slots {
                            if let SlotValue::Note { interval, .. } = slot {
                                notes.push(NoteEvent {
                                    pitch: 60 + interval.semitones,
                                    start: current_beat,
                                    duration: beat_duration,
                                    velocity: 100,
                                });
                            }
                        }
                    }
                }
                current_beat += beat_duration;
            }
        }
        Value::Song(song) => {
            // Extract notes from all parts in the song
            for section in &song.sections {
                for part in &section.parts {
                    for block in &part.blocks {
                        let block_notes = extract_notes_from_value(&Value::Block(block.clone()));
                        notes.extend(block_notes);
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
                TokenKind::Let | TokenKind::In | TokenKind::If | TokenKind::Then
                | TokenKind::Else | TokenKind::Match | TokenKind::With | TokenKind::Scale
                | TokenKind::Chord | TokenKind::Section | TokenKind::Layer | TokenKind::Part
                | TokenKind::Env | TokenKind::Import | TokenKind::Export | TokenKind::From
                | TokenKind::As | TokenKind::True | TokenKind::False | TokenKind::Render
                | TokenKind::Context | TokenKind::Key => "keyword",
                TokenKind::Integer(_) | TokenKind::Float(_) => "number",
                TokenKind::String(_) => "string",
                TokenKind::Ident(_) => "identifier",
                TokenKind::Interval(_) => "interval",
                TokenKind::Root => "root",
                TokenKind::Pipe | TokenKind::PipeOp | TokenKind::Arrow | TokenKind::Lambda
                | TokenKind::Eq | TokenKind::Colon | TokenKind::Comma | TokenKind::Dot
                | TokenKind::Minus | TokenKind::Plus => "operator",
                TokenKind::Staccato | TokenKind::Accent | TokenKind::Portamento => "articulation",
                TokenKind::LBrace | TokenKind::RBrace | TokenKind::LBracket | TokenKind::RBracket
                | TokenKind::LParen | TokenKind::RParen | TokenKind::LAngle | TokenKind::RAngle => "bracket",
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
