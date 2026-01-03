use logos::Logos;
use relanote_core::Span;

/// Interval quality prefix
#[derive(Clone, Copy, Debug, PartialEq, Eq, Hash)]
pub enum IntervalQuality {
    /// Major (M)
    Major,
    /// Minor (m)
    Minor,
    /// Perfect (P)
    Perfect,
    /// Diminished (d)
    Diminished,
    /// Augmented (A)
    Augmented,
}

/// Accidental modifier
#[derive(Clone, Copy, Debug, PartialEq, Eq, Hash)]
pub enum Accidental {
    Sharp, // +
    Flat,  // -
}

/// Parsed interval data from token
#[derive(Clone, Debug, PartialEq, Eq, Hash)]
pub struct IntervalData {
    pub quality: IntervalQuality,
    pub degree: u8,
    pub accidentals: Vec<Accidental>,
}

/// Absolute pitch data (e.g., C4, D#3, Bb5)
#[derive(Clone, Debug, PartialEq, Eq, Hash)]
pub struct AbsolutePitchData {
    /// Note name (C, D, E, F, G, A, B)
    pub note: char,
    /// Accidental: sharp (#) = +1, flat (b) = -1, natural = 0
    pub accidental: i8,
    /// Octave number (4 = middle C octave)
    pub octave: u8,
}

impl AbsolutePitchData {
    /// Convert to MIDI note number (C4 = 60)
    pub fn to_midi_note(&self) -> u8 {
        let base = match self.note {
            'C' => 0,
            'D' => 2,
            'E' => 4,
            'F' => 5,
            'G' => 7,
            'A' => 9,
            'B' => 11,
            _ => 0,
        };
        let midi = 12 * (self.octave as i16 + 1) + base as i16 + self.accidental as i16;
        midi.clamp(0, 127) as u8
    }
}

// Note: Dynamic markings are defined in relanote-ast to avoid conflicts with identifiers

fn parse_absolute_pitch(s: &str) -> Option<AbsolutePitchData> {
    let mut chars = s.chars().peekable();

    // Parse note name (C, D, E, F, G, A, B)
    let note = chars.next()?;
    if !matches!(note, 'C' | 'D' | 'E' | 'F' | 'G' | 'A' | 'B') {
        return None;
    }

    // Parse optional accidental (# or b)
    let accidental = match chars.peek() {
        Some('#') => {
            chars.next();
            1
        }
        Some('b') => {
            chars.next();
            -1
        }
        _ => 0,
    };

    // Parse octave number
    let octave_str: String = chars.collect();
    let octave: u8 = octave_str.parse().ok()?;

    Some(AbsolutePitchData {
        note,
        accidental,
        octave,
    })
}

fn parse_interval(s: &str) -> Option<IntervalData> {
    let mut chars = s.chars().peekable();

    let quality = match chars.next()? {
        'M' => IntervalQuality::Major,
        'm' => IntervalQuality::Minor,
        'P' => IntervalQuality::Perfect,
        'd' => IntervalQuality::Diminished,
        'A' => IntervalQuality::Augmented,
        _ => return None,
    };

    // Parse degree (1-13)
    let mut degree_str = String::new();
    while let Some(&c) = chars.peek() {
        if c.is_ascii_digit() {
            degree_str.push(chars.next().unwrap());
        } else {
            break;
        }
    }
    let degree: u8 = degree_str.parse().ok()?;

    // Parse accidentals
    let mut accidentals = Vec::new();
    for c in chars {
        match c {
            '+' => accidentals.push(Accidental::Sharp),
            '-' => accidentals.push(Accidental::Flat),
            _ => return None,
        }
    }

    Some(IntervalData {
        quality,
        degree,
        accidentals,
    })
}

/// Token kind produced by the lexer
#[derive(Logos, Clone, Debug, PartialEq)]
#[logos(skip r"[ \t\r]+")]
pub enum TokenKind {
    // ===== Keywords =====
    #[token("let")]
    Let,

    #[token("set")]
    Set,

    #[token("in")]
    In,

    #[token("if")]
    If,

    #[token("then")]
    Then,

    #[token("else")]
    Else,

    #[token("match")]
    Match,

    #[token("with")]
    With,

    #[token("scale")]
    Scale,

    #[token("chord")]
    Chord,

    #[token("section")]
    Section,

    #[token("layer")]
    Layer,

    #[token("part")]
    Part,

    #[token("synth")]
    Synth,

    #[token("osc")]
    Osc,

    #[token("filter")]
    Filter,

    #[token("env")]
    Env,

    #[token("import")]
    Import,

    #[token("export")]
    Export,

    #[token("from")]
    From,

    #[token("as")]
    As,

    #[token("mod")]
    Mod,

    #[token("use")]
    Use,

    #[token("true")]
    True,

    #[token("false")]
    False,

    #[token("render")]
    Render,

    #[token("Context")]
    Context,

    #[token("Key")]
    Key,

    // ===== Music Primitives =====
    /// Root/Rest marker
    #[token("R", priority = 3)]
    Root,

    /// Interval (M3, P5+, m7-, etc.)
    #[regex(r"[MPmAd][1-9][0-9]*[+-]*", priority = 3, callback = |lex| parse_interval(lex.slice()))]
    Interval(IntervalData),

    /// Absolute pitch (C4, D#3, Bb5, etc.)
    /// Note: 'A' without accidental (A4, A5) is reserved for Augmented intervals
    /// So we match: C/D/E/F/G/B with optional accidental, or A with required accidental
    #[regex(r"([CDEFGB][#b]?|A[#b])[0-9]", priority = 4, callback = |lex| parse_absolute_pitch(lex.slice()))]
    AbsolutePitch(AbsolutePitchData),

    // Note: Dynamic markings (pp, mf, ff, etc.) are handled at the parser level
    // to avoid conflicts with identifiers like 'f', 'p', 'm'
    /// Duration unit (e.g., 4bars, 2beats)
    #[regex(r"[0-9]+bars?")]
    Bars,

    #[regex(r"[0-9]+beats?")]
    Beats,

    // ===== Articulations =====
    /// Staccato
    #[token("*")]
    Staccato,

    /// Accent
    #[token("^")]
    Accent,

    /// Portamento/Slur
    #[token("~")]
    Portamento,

    // ===== Delimiters =====
    #[token("|")]
    Pipe,

    #[token("{")]
    LBrace,

    #[token("}")]
    RBrace,

    #[token("[")]
    LBracket,

    #[token("]")]
    RBracket,

    #[token("(")]
    LParen,

    #[token(")")]
    RParen,

    #[token("<")]
    LAngle,

    #[token(">")]
    RAngle,

    // ===== Operators =====
    #[token("|>", priority = 3)]
    PipeOp,

    #[token(">>", priority = 3)]
    Compose,

    #[token("->")]
    Arrow,

    #[token("\\")]
    Lambda,

    #[token("=")]
    Eq,

    #[token("::")]
    ColonColon,

    #[token(":")]
    Colon,

    #[token(",")]
    Comma,

    #[token(".")]
    Dot,

    #[token("-")]
    Minus,

    #[token("++")]
    PlusPlus,

    #[token("+")]
    Plus,

    // ===== Literals =====
    /// Integer literal
    #[regex(r"[0-9]+", |lex| lex.slice().parse::<i64>().ok())]
    Integer(i64),

    /// Float literal
    #[regex(r"[0-9]+\.[0-9]+", |lex| lex.slice().parse::<f64>().ok())]
    Float(f64),

    /// String literal
    #[regex(r#""[^"]*""#, |lex| {
        let s = lex.slice();
        Some(s[1..s.len()-1].to_string())
    })]
    String(String),

    // ===== Identifiers =====
    #[regex(r"[a-zA-Z_][a-zA-Z0-9_]*", |lex| lex.slice().to_string())]
    Ident(String),

    // ===== Comments =====
    /// Line comment (; ...)
    #[regex(r";[^\n]*", |lex| lex.slice().to_string())]
    LineComment(String),

    // ===== Newline (significant for some constructs) =====
    #[token("\n")]
    Newline,

    // ===== End of file =====
    Eof,
}

impl TokenKind {
    pub fn is_keyword(&self) -> bool {
        matches!(
            self,
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
                | TokenKind::Synth
                | TokenKind::Osc
                | TokenKind::Filter
                | TokenKind::Env
                | TokenKind::Import
                | TokenKind::Export
                | TokenKind::From
                | TokenKind::As
                | TokenKind::Mod
                | TokenKind::Use
                | TokenKind::True
                | TokenKind::False
        )
    }

    pub fn is_operator(&self) -> bool {
        matches!(
            self,
            TokenKind::PipeOp
                | TokenKind::Arrow
                | TokenKind::Lambda
                | TokenKind::Eq
                | TokenKind::ColonColon
                | TokenKind::Colon
                | TokenKind::Comma
                | TokenKind::Dot
                | TokenKind::Minus
                | TokenKind::Plus
        )
    }

    pub fn is_articulation(&self) -> bool {
        matches!(
            self,
            TokenKind::Staccato | TokenKind::Accent | TokenKind::Portamento
        )
    }
}

/// A token with its span
#[derive(Clone, Debug, PartialEq)]
pub struct Token {
    pub kind: TokenKind,
    pub span: Span,
}

impl Token {
    pub fn new(kind: TokenKind, span: Span) -> Self {
        Self { kind, span }
    }

    pub fn eof(span: Span) -> Self {
        Self {
            kind: TokenKind::Eof,
            span,
        }
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_augmented_interval_vs_absolute_pitch() {
        // A4 should be Augmented 4th interval, NOT absolute pitch A octave 4
        let mut lexer = TokenKind::lexer("A4");
        let token = lexer.next().unwrap().unwrap();
        assert!(
            matches!(
                token,
                TokenKind::Interval(IntervalData {
                    quality: IntervalQuality::Augmented,
                    degree: 4,
                    ..
                })
            ),
            "A4 should be parsed as Augmented 4th interval, got {:?}",
            token
        );

        // A5 should be Augmented 5th interval
        let mut lexer = TokenKind::lexer("A5");
        let token = lexer.next().unwrap().unwrap();
        assert!(
            matches!(
                token,
                TokenKind::Interval(IntervalData {
                    quality: IntervalQuality::Augmented,
                    degree: 5,
                    ..
                })
            ),
            "A5 should be parsed as Augmented 5th interval, got {:?}",
            token
        );

        // A#4 should be absolute pitch (A sharp, octave 4)
        let mut lexer = TokenKind::lexer("A#4");
        let token = lexer.next().unwrap().unwrap();
        assert!(
            matches!(
                token,
                TokenKind::AbsolutePitch(AbsolutePitchData {
                    note: 'A',
                    accidental: 1,
                    octave: 4
                })
            ),
            "A#4 should be parsed as absolute pitch, got {:?}",
            token
        );

        // Ab4 should be absolute pitch (A flat, octave 4)
        let mut lexer = TokenKind::lexer("Ab4");
        let token = lexer.next().unwrap().unwrap();
        assert!(
            matches!(
                token,
                TokenKind::AbsolutePitch(AbsolutePitchData {
                    note: 'A',
                    accidental: -1,
                    octave: 4
                })
            ),
            "Ab4 should be parsed as absolute pitch, got {:?}",
            token
        );

        // C4 should be absolute pitch (C, octave 4)
        let mut lexer = TokenKind::lexer("C4");
        let token = lexer.next().unwrap().unwrap();
        assert!(
            matches!(
                token,
                TokenKind::AbsolutePitch(AbsolutePitchData {
                    note: 'C',
                    accidental: 0,
                    octave: 4
                })
            ),
            "C4 should be parsed as absolute pitch, got {:?}",
            token
        );
    }

    #[test]
    fn test_parse_interval() {
        assert_eq!(
            parse_interval("M3"),
            Some(IntervalData {
                quality: IntervalQuality::Major,
                degree: 3,
                accidentals: vec![],
            })
        );

        assert_eq!(
            parse_interval("P5+"),
            Some(IntervalData {
                quality: IntervalQuality::Perfect,
                degree: 5,
                accidentals: vec![Accidental::Sharp],
            })
        );

        assert_eq!(
            parse_interval("m7-"),
            Some(IntervalData {
                quality: IntervalQuality::Minor,
                degree: 7,
                accidentals: vec![Accidental::Flat],
            })
        );

        assert_eq!(
            parse_interval("A4++"),
            Some(IntervalData {
                quality: IntervalQuality::Augmented,
                degree: 4,
                accidentals: vec![Accidental::Sharp, Accidental::Sharp],
            })
        );
    }

    #[test]
    fn test_lex_basic() {
        let mut lexer = TokenKind::lexer("let x = M3");
        assert_eq!(lexer.next(), Some(Ok(TokenKind::Let)));
        assert_eq!(lexer.next(), Some(Ok(TokenKind::Ident("x".to_string()))));
        assert_eq!(lexer.next(), Some(Ok(TokenKind::Eq)));
        assert!(matches!(lexer.next(), Some(Ok(TokenKind::Interval(_)))));
    }

    #[test]
    fn test_lex_block() {
        let mut lexer = TokenKind::lexer("| R M3 P5 |");
        assert_eq!(lexer.next(), Some(Ok(TokenKind::Pipe)));
        assert_eq!(lexer.next(), Some(Ok(TokenKind::Root)));
        assert!(matches!(lexer.next(), Some(Ok(TokenKind::Interval(_)))));
        assert!(matches!(lexer.next(), Some(Ok(TokenKind::Interval(_)))));
        assert_eq!(lexer.next(), Some(Ok(TokenKind::Pipe)));
    }

    #[test]
    fn test_lex_lambda() {
        let mut lexer = TokenKind::lexer("\\x -> x |> reverse");
        assert_eq!(lexer.next(), Some(Ok(TokenKind::Lambda)));
        assert_eq!(lexer.next(), Some(Ok(TokenKind::Ident("x".to_string()))));
        assert_eq!(lexer.next(), Some(Ok(TokenKind::Arrow)));
        assert_eq!(lexer.next(), Some(Ok(TokenKind::Ident("x".to_string()))));
        assert_eq!(lexer.next(), Some(Ok(TokenKind::PipeOp)));
        assert_eq!(
            lexer.next(),
            Some(Ok(TokenKind::Ident("reverse".to_string())))
        );
    }

    #[test]
    fn test_lex_dynamics_as_idents() {
        // Dynamics are now tokenized as identifiers to avoid conflicts
        let mut lexer = TokenKind::lexer("pp mf ff");
        assert_eq!(lexer.next(), Some(Ok(TokenKind::Ident("pp".to_string()))));
        assert_eq!(lexer.next(), Some(Ok(TokenKind::Ident("mf".to_string()))));
        assert_eq!(lexer.next(), Some(Ok(TokenKind::Ident("ff".to_string()))));
    }

    #[test]
    fn test_lex_string() {
        let mut lexer = TokenKind::lexer(r#""Piano" "Hello World""#);
        assert_eq!(
            lexer.next(),
            Some(Ok(TokenKind::String("Piano".to_string())))
        );
        assert_eq!(
            lexer.next(),
            Some(Ok(TokenKind::String("Hello World".to_string())))
        );
    }

    #[test]
    fn test_lex_comment() {
        let mut lexer = TokenKind::lexer("let x = 1 ; this is a comment\nlet y = 2");
        assert_eq!(lexer.next(), Some(Ok(TokenKind::Let)));
        assert_eq!(lexer.next(), Some(Ok(TokenKind::Ident("x".to_string()))));
        assert_eq!(lexer.next(), Some(Ok(TokenKind::Eq)));
        assert_eq!(lexer.next(), Some(Ok(TokenKind::Integer(1))));
        assert_eq!(
            lexer.next(),
            Some(Ok(TokenKind::LineComment(
                "; this is a comment".to_string()
            )))
        );
        assert_eq!(lexer.next(), Some(Ok(TokenKind::Newline)));
        assert_eq!(lexer.next(), Some(Ok(TokenKind::Let)));
    }
}
