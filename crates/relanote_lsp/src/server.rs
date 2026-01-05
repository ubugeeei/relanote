//! LSP server implementation

use std::collections::HashMap;
use std::sync::Arc;

use tokio::sync::RwLock;
use tower_lsp::jsonrpc::Result;
use tower_lsp::lsp_types::*;
use tower_lsp::{Client, LanguageServer};

use relanote_core::{Source, SourceDb};
use relanote_format::{format, FormatConfig};
use relanote_lexer::{Lexer, TokenKind};
use relanote_parser::parse_source;
use relanote_types::TypeChecker;

/// Get documentation for builtin functions
fn get_builtin_docs(name: &str) -> Option<(&'static str, &'static str)> {
    // Returns (signature, description)
    match name {
        "reverse" => Some((
            "reverse : Block -> Block",
            "Reverses the order of slots in a block.\n\n**Example:**\n```rela\n| R M3 P5 | |> reverse  -- becomes | P5 M3 R |\n```",
        )),
        "repeat" => Some((
            "repeat : (Int, Block) -> Block",
            "Repeats a block n times.\n\n**Example:**\n```rela\n| R M3 | |> repeat(4)  -- plays the phrase 4 times\n```",
        )),
        "transpose" => Some((
            "transpose : (Interval, Block) -> Block",
            "Transposes all notes in a block by the given interval.\n\n**Example:**\n```rela\n| R M3 P5 | |> transpose(P5)  -- transposes up a fifth\n```",
        )),
        "metronome" => Some((
            "metronome : (Int, Int) -> Part",
            "Generates a metronome click track.\n\nParameters:\n- `bars`: Number of bars\n- `beats_per_bar`: Beats per bar (time signature)\n\n**Example:**\n```rela\nlayer [\n  melody,\n  metronome(8, 4) |> volume(0.3)\n]\n```",
        )),
        "swing" => Some((
            "swing : (Float, Block) -> Block",
            "Applies swing feel to a block.\n\nThe ratio determines the swing amount (0.5 = straight, 0.67 = triplet swing).\n\n**Example:**\n```rela\n| R M3 P5 M3 | |> swing(0.6)\n```",
        )),
        "double_time" => Some((
            "double_time : Block -> Block",
            "Doubles the tempo of a block (halves durations).\n\n**Example:**\n```rela\nmelody |> double_time  -- plays twice as fast\n```",
        )),
        "reverb" => Some((
            "reverb : (Float, Block) -> Part",
            "Applies reverb with specified level (0.0-1.0).\n\n**Example:**\n```rela\nmelody |> reverb(0.5)  -- 50% reverb send\n```",
        )),
        "hall_reverb" => Some((
            "hall_reverb : Block -> Part",
            "Applies hall reverb preset (high reverb level).\n\n**Example:**\n```rela\nmelody |> hall_reverb\n```",
        )),
        "room_reverb" => Some((
            "room_reverb : Block -> Part",
            "Applies room reverb preset (medium reverb level).\n\n**Example:**\n```rela\nmelody |> room_reverb\n```",
        )),
        "plate_reverb" => Some((
            "plate_reverb : Block -> Part",
            "Applies plate reverb preset (bright, metallic reverb).\n\n**Example:**\n```rela\nmelody |> plate_reverb\n```",
        )),
        "dry" => Some((
            "dry : Block -> Part",
            "No reverb (dry signal only).\n\n**Example:**\n```rela\nmelody |> dry\n```",
        )),
        "volume" => Some((
            "volume : (Float, Block | Part) -> Part",
            "Sets volume level (0.0-1.0 or 0-100).\n\nCan be chained with other effects.\n\n**Example:**\n```rela\nmelody |> reverb(0.5) |> volume(0.8)\nmetronome(8, 4) |> volume(0.25)\n```",
        )),
        _ => None,
    }
}

/// Get documentation for keywords
fn get_keyword_docs(keyword: &str) -> Option<(&'static str, &'static str)> {
    match keyword {
        "let" => Some((
            "let <pattern> = <expr> in <body>",
            "Binds a value to a name.\n\n**Example:**\n```rela\nlet melody = | R M3 P5 | in melody |> transpose(P5)\n```",
        )),
        "layer" => Some((
            "layer [ <parts...> ]",
            "Combines multiple parts to play simultaneously.\n\n**Example:**\n```rela\nlayer [\n  melody |> room_reverb,\n  bass |> volume(0.8),\n  drums\n]\n```",
        )),
        "scale" => Some((
            "scale <name> { <intervals...> }",
            "Defines a scale with intervals from root.\n\n**Example:**\n```rela\nscale major { R M2 M3 P4 P5 M6 M7 }\nscale minor { R M2 m3 P4 P5 m6 m7 }\n```",
        )),
        "chord" => Some((
            "chord <name> { <intervals...> }",
            "Defines a chord with intervals from root.\n\n**Example:**\n```rela\nchord maj7 { R M3 P5 M7 }\nchord m7b5 { R m3 d5 m7 }\n```",
        )),
        "section" => Some((
            "section <name> { <content> }",
            "Defines a named section of music.\n\n**Example:**\n```rela\nsection \"Verse\" {\n  Part \"Piano\" { melody }\n}\n```",
        )),
        "Part" => Some((
            "Part <instrument> { <blocks...> }",
            "Defines a part with an instrument name.\n\n**Example:**\n```rela\nPart \"Piano\" { melody ++ bridge ++ melody }\n```",
        )),
        "if" => Some((
            "if <cond> then <expr> else <expr>",
            "Conditional expression.\n\n**Example:**\n```rela\nif n > 0 then melody else rest\n```",
        )),
        "match" => Some((
            "match <expr> with | <pattern> -> <expr> ...",
            "Pattern matching expression.\n\n**Example:**\n```rela\nmatch mode with\n  | \"major\" -> major_scale\n  | \"minor\" -> minor_scale\n```",
        )),
        _ => None,
    }
}

/// Calculate interval semitones
fn interval_semitones(quality: &str, degree: u8) -> f64 {
    let base = match degree {
        1 => 0.0,
        2 => 2.0,
        3 => 4.0,
        4 => 5.0,
        5 => 7.0,
        6 => 9.0,
        7 => 11.0,
        8 => 12.0,
        9 => 14.0,
        10 => 16.0,
        11 => 17.0,
        12 => 19.0,
        13 => 21.0,
        _ => (degree as f64 - 1.0) * 2.0,
    };

    match quality {
        "P" => base,       // Perfect
        "M" => base,       // Major
        "m" => base - 1.0, // Minor
        "A" => base + 1.0, // Augmented
        "d" => {
            if degree == 1 || degree == 4 || degree == 5 || degree == 8 {
                base - 1.0 // Diminished perfect
            } else {
                base - 2.0 // Diminished major
            }
        }
        _ => base,
    }
}

/// Document state
struct Document {
    content: String,
    version: i32,
}

/// The relanote language server
pub struct RelanoteLanguageServer {
    client: Client,
    documents: Arc<RwLock<HashMap<Url, Document>>>,
    #[allow(dead_code)]
    source_db: Arc<RwLock<SourceDb>>,
}

impl RelanoteLanguageServer {
    pub fn new(client: Client) -> Self {
        Self {
            client,
            documents: Arc::new(RwLock::new(HashMap::new())),
            source_db: Arc::new(RwLock::new(SourceDb::new())),
        }
    }

    async fn analyze_document(&self, uri: &Url) {
        let documents = self.documents.read().await;
        let doc = match documents.get(uri) {
            Some(d) => d,
            None => return,
        };

        // Parse the document
        let source = Source::from_string(uri.path().to_string(), doc.content.clone());
        let (program, parse_diagnostics) = parse_source(&source);

        // Type check
        let mut type_checker = TypeChecker::new();
        let type_diagnostics = type_checker.check_program(&program);

        // Convert to LSP diagnostics
        let mut lsp_diagnostics = Vec::new();

        for diag in parse_diagnostics.iter() {
            let start_loc = source.location(diag.span.start);
            let end_loc = source.location(diag.span.end);

            lsp_diagnostics.push(Diagnostic {
                range: Range {
                    start: Position {
                        line: (start_loc.line - 1) as u32,
                        character: (start_loc.column - 1) as u32,
                    },
                    end: Position {
                        line: (end_loc.line - 1) as u32,
                        character: (end_loc.column - 1) as u32,
                    },
                },
                severity: Some(DiagnosticSeverity::ERROR),
                message: diag.message.clone(),
                ..Default::default()
            });
        }

        for diag in type_diagnostics.iter() {
            let start_loc = source.location(diag.span.start);
            let end_loc = source.location(diag.span.end);

            lsp_diagnostics.push(Diagnostic {
                range: Range {
                    start: Position {
                        line: (start_loc.line - 1) as u32,
                        character: (start_loc.column - 1) as u32,
                    },
                    end: Position {
                        line: (end_loc.line - 1) as u32,
                        character: (end_loc.column - 1) as u32,
                    },
                },
                severity: Some(DiagnosticSeverity::ERROR),
                message: diag.message.clone(),
                ..Default::default()
            });
        }

        // Publish diagnostics
        self.client
            .publish_diagnostics(uri.clone(), lsp_diagnostics, Some(doc.version))
            .await;
    }
}

#[tower_lsp::async_trait]
impl LanguageServer for RelanoteLanguageServer {
    async fn initialize(&self, _: InitializeParams) -> Result<InitializeResult> {
        Ok(InitializeResult {
            capabilities: ServerCapabilities {
                text_document_sync: Some(TextDocumentSyncCapability::Kind(
                    TextDocumentSyncKind::FULL,
                )),
                completion_provider: Some(CompletionOptions {
                    trigger_characters: Some(vec![".".to_string(), "<".to_string()]),
                    ..Default::default()
                }),
                hover_provider: Some(HoverProviderCapability::Simple(true)),
                definition_provider: Some(OneOf::Left(true)),
                document_formatting_provider: Some(OneOf::Left(true)),
                ..Default::default()
            },
            ..Default::default()
        })
    }

    async fn initialized(&self, _: InitializedParams) {
        self.client
            .log_message(MessageType::INFO, "Relanote language server initialized")
            .await;
    }

    async fn shutdown(&self) -> Result<()> {
        Ok(())
    }

    async fn did_open(&self, params: DidOpenTextDocumentParams) {
        let uri = params.text_document.uri;
        let content = params.text_document.text;
        let version = params.text_document.version;

        {
            let mut documents = self.documents.write().await;
            documents.insert(uri.clone(), Document { content, version });
        }

        self.analyze_document(&uri).await;
    }

    async fn did_change(&self, params: DidChangeTextDocumentParams) {
        let uri = params.text_document.uri;
        let version = params.text_document.version;

        if let Some(change) = params.content_changes.into_iter().next() {
            {
                let mut documents = self.documents.write().await;
                if let Some(doc) = documents.get_mut(&uri) {
                    doc.content = change.text;
                    doc.version = version;
                }
            }

            self.analyze_document(&uri).await;
        }
    }

    async fn did_close(&self, params: DidCloseTextDocumentParams) {
        let uri = params.text_document.uri;
        let mut documents = self.documents.write().await;
        documents.remove(&uri);
    }

    async fn completion(&self, _params: CompletionParams) -> Result<Option<CompletionResponse>> {
        let mut completions = Vec::new();

        // Keywords
        let keywords = [
            ("scale", "Define a scale"),
            ("chord", "Define a chord"),
            ("let", "Define a binding"),
            ("in", "Local binding scope"),
            ("section", "Define a section"),
            ("layer", "Combine multiple parts"),
            ("Part", "Define a part"),
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
                kind: Some(CompletionItemKind::KEYWORD),
                detail: Some(detail.to_string()),
                ..Default::default()
            });
        }

        // Set statements
        let set_items = [
            ("set tempo = ", "Set tempo (BPM)"),
            ("set key = ", "Set key (e.g., C4, D#3)"),
        ];
        for (label, detail) in set_items {
            completions.push(CompletionItem {
                label: label.to_string(),
                kind: Some(CompletionItemKind::SNIPPET),
                detail: Some(detail.to_string()),
                insert_text: Some(label.to_string()),
                ..Default::default()
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
        ];
        for (label, detail) in functions {
            completions.push(CompletionItem {
                label: label.to_string(),
                kind: Some(CompletionItemKind::FUNCTION),
                detail: Some(detail.to_string()),
                ..Default::default()
            });
        }

        // Voice/Instruments
        let voices = [
            // 8-bit / Chiptune
            ("NES", "NES pulse wave"),
            ("GameBoy", "GameBoy sound"),
            ("Chiptune", "Classic chiptune"),
            ("Chip8bit", "8-bit chip sound"),
            // Drums
            ("Kick8bit", "8-bit kick drum"),
            ("Snare8bit", "8-bit snare drum"),
            ("HiHat8bit", "8-bit hi-hat"),
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
            // Synths
            ("SawLead", "Saw wave lead"),
            ("SquareLead", "Square wave lead"),
            ("SineLead", "Sine wave lead"),
            ("SuperSaw", "Super saw"),
            ("Pad", "Pad synth"),
            ("DarkPad", "Dark pad"),
            ("String", "String ensemble"),
            ("Brass", "Brass section"),
            ("Organ", "Organ"),
            // Piano
            ("Piano", "Acoustic piano"),
            ("EPiano", "Electric piano"),
            ("Rhodes", "Rhodes piano"),
            // Pluck
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
                kind: Some(CompletionItemKind::ENUM_MEMBER),
                detail: Some(format!("Voice: {}", detail)),
                ..Default::default()
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
            ("P11", "Perfect Eleventh (17 semitones)"),
            ("P12", "Perfect Twelfth (19 semitones)"),
            ("M13", "Major Thirteenth (21 semitones)"),
            ("M14", "Major Fourteenth (23 semitones)"),
            ("P15", "Perfect Fifteenth (24 semitones)"),
        ];
        for (label, detail) in intervals {
            completions.push(CompletionItem {
                label: label.to_string(),
                kind: Some(CompletionItemKind::CONSTANT),
                detail: Some(detail.to_string()),
                ..Default::default()
            });
        }

        // Scales (predefined)
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
            ("Chromatic", "Chromatic scale"),
        ];
        for (label, detail) in scales {
            completions.push(CompletionItem {
                label: label.to_string(),
                kind: Some(CompletionItemKind::CLASS),
                detail: Some(format!("Scale: {}", detail)),
                ..Default::default()
            });
        }

        // Chords (predefined)
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
                kind: Some(CompletionItemKind::CLASS),
                detail: Some(format!("Chord: {}", detail)),
                ..Default::default()
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
                kind: Some(CompletionItemKind::PROPERTY),
                detail: Some(format!("Dynamic: {}", detail)),
                ..Default::default()
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
                kind: Some(CompletionItemKind::PROPERTY),
                detail: Some(format!("Articulation: {}", detail)),
                ..Default::default()
            });
        }

        Ok(Some(CompletionResponse::Array(completions)))
    }

    async fn hover(&self, params: HoverParams) -> Result<Option<Hover>> {
        let uri = params.text_document_position_params.text_document.uri;
        let position = params.text_document_position_params.position;

        let documents = self.documents.read().await;
        if let Some(doc) = documents.get(&uri) {
            let source = Source::from_string(uri.path().to_string(), doc.content.clone());

            // Convert line/column to byte offset
            let offset = {
                let mut off = 0usize;
                for (i, line) in doc.content.lines().enumerate() {
                    if i == position.line as usize {
                        off += (position.character as usize).min(line.len());
                        break;
                    }
                    off += line.len() + 1; // +1 for newline
                }
                off
            };

            // Tokenize and find the token at offset
            let lexer = Lexer::new(&source);
            let tokens: Vec<_> = lexer.collect();

            for token in &tokens {
                if token.span.start <= offset && offset <= token.span.end {
                    // Found the token at cursor
                    let hover_content = match &token.kind {
                        // Identifiers - check for builtins or show type
                        TokenKind::Ident(name) => {
                            if let Some((sig, desc)) = get_builtin_docs(name) {
                                Some(format!("```rela\n{}\n```\n\n{}", sig, desc))
                            } else {
                                // Parse and type check to get variable type
                                let (program, _) = parse_source(&source);
                                let mut checker = TypeChecker::new();
                                checker.check_program(&program);
                                if let Some(ty) = checker.lookup_type(name) {
                                    Some(format!("```rela\n{}: {}\n```\n\nUser-defined binding", name, ty))
                                } else {
                                    Some(format!("```rela\n{}\n```\n\nIdentifier", name))
                                }
                            }
                        }

                        // Keywords
                        TokenKind::Let => get_keyword_docs("let").map(|(sig, desc)| {
                            format!("```rela\n{}\n```\n\n{}", sig, desc)
                        }),
                        TokenKind::Layer => get_keyword_docs("layer").map(|(sig, desc)| {
                            format!("```rela\n{}\n```\n\n{}", sig, desc)
                        }),
                        TokenKind::Scale => get_keyword_docs("scale").map(|(sig, desc)| {
                            format!("```rela\n{}\n```\n\n{}", sig, desc)
                        }),
                        TokenKind::Chord => get_keyword_docs("chord").map(|(sig, desc)| {
                            format!("```rela\n{}\n```\n\n{}", sig, desc)
                        }),
                        TokenKind::Section => get_keyword_docs("section").map(|(sig, desc)| {
                            format!("```rela\n{}\n```\n\n{}", sig, desc)
                        }),
                        TokenKind::Part => get_keyword_docs("Part").map(|(sig, desc)| {
                            format!("```rela\n{}\n```\n\n{}", sig, desc)
                        }),
                        TokenKind::If => get_keyword_docs("if").map(|(sig, desc)| {
                            format!("```rela\n{}\n```\n\n{}", sig, desc)
                        }),
                        TokenKind::Match => get_keyword_docs("match").map(|(sig, desc)| {
                            format!("```rela\n{}\n```\n\n{}", sig, desc)
                        }),

                        // Intervals
                        TokenKind::Interval(data) => {
                            let quality = match data.quality {
                                relanote_lexer::IntervalQuality::Perfect => "P",
                                relanote_lexer::IntervalQuality::Major => "M",
                                relanote_lexer::IntervalQuality::Minor => "m",
                                relanote_lexer::IntervalQuality::Augmented => "A",
                                relanote_lexer::IntervalQuality::Diminished => "d",
                            };
                            let quality_name = match data.quality {
                                relanote_lexer::IntervalQuality::Perfect => "Perfect",
                                relanote_lexer::IntervalQuality::Major => "Major",
                                relanote_lexer::IntervalQuality::Minor => "Minor",
                                relanote_lexer::IntervalQuality::Augmented => "Augmented",
                                relanote_lexer::IntervalQuality::Diminished => "Diminished",
                            };
                            let degree_name = match data.degree {
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
                                _ => "Interval",
                            };
                            let mut semitones = interval_semitones(quality, data.degree);
                            for acc in &data.accidentals {
                                match acc {
                                    relanote_lexer::Accidental::Sharp => semitones += 1.0,
                                    relanote_lexer::Accidental::Flat => semitones -= 1.0,
                                }
                            }
                            let cents = semitones * 100.0;
                            Some(format!(
                                "**{} {}**\n\n- Semitones: `{}`\n- Cents: `{}`",
                                quality_name, degree_name, semitones, cents
                            ))
                        }

                        // Root/Rest
                        TokenKind::Root => Some(
                            "**R** (Root)\n\nThe root of the current scale/chord, or a rest when used alone.\n\n- Semitones: `0`\n- Cents: `0`".to_string()
                        ),

                        // Articulations
                        TokenKind::Staccato => Some(
                            "**Staccato** (`*`)\n\nShortens the note to 50% of its duration.".to_string()
                        ),
                        TokenKind::Accent => Some(
                            "**Accent** (`^`)\n\nEmphasizes the note with increased velocity.".to_string()
                        ),
                        TokenKind::Portamento => Some(
                            "**Portamento/Slur** (`~`)\n\nSmooth transition between notes.".to_string()
                        ),

                        // Pipe operator
                        TokenKind::PipeOp => Some(
                            "**Pipe Operator** (`|>`)\n\nPasses the left value as the last argument to the right function.\n\n```rela\nmelody |> transpose(P5) |> reverse\n```".to_string()
                        ),

                        _ => None,
                    };

                    if let Some(content) = hover_content {
                        let start_loc = source.location(token.span.start);
                        let end_loc = source.location(token.span.end);
                        return Ok(Some(Hover {
                            contents: HoverContents::Markup(MarkupContent {
                                kind: MarkupKind::Markdown,
                                value: content,
                            }),
                            range: Some(Range {
                                start: Position {
                                    line: (start_loc.line - 1) as u32,
                                    character: (start_loc.column - 1) as u32,
                                },
                                end: Position {
                                    line: (end_loc.line - 1) as u32,
                                    character: (end_loc.column - 1) as u32,
                                },
                            }),
                        }));
                    }
                }
            }
        }

        Ok(None)
    }

    async fn formatting(&self, params: DocumentFormattingParams) -> Result<Option<Vec<TextEdit>>> {
        let uri = params.text_document.uri;

        let documents = self.documents.read().await;
        if let Some(doc) = documents.get(&uri) {
            let source = Source::from_string(uri.path().to_string(), doc.content.clone());
            let (program, diagnostics) = parse_source(&source);

            if !diagnostics.has_errors() {
                let config = FormatConfig::default();
                let formatted = format(&program, &config);

                let lines: Vec<&str> = doc.content.lines().collect();
                let last_line = lines.len().saturating_sub(1) as u32;
                let last_char = lines.last().map(|l| l.len()).unwrap_or(0) as u32;

                return Ok(Some(vec![TextEdit {
                    range: Range {
                        start: Position {
                            line: 0,
                            character: 0,
                        },
                        end: Position {
                            line: last_line,
                            character: last_char,
                        },
                    },
                    new_text: formatted,
                }]));
            }
        }

        Ok(None)
    }
}
