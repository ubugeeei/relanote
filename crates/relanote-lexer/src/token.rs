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

// Note: Dynamic markings are defined in relanote-ast to avoid conflicts with identifiers

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

    #[token("Part")]
    Part,

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

    #[token("->")]
    Arrow,

    #[token("\\")]
    Lambda,

    #[token("=")]
    Eq,

    #[token(":")]
    Colon,

    #[token(",")]
    Comma,

    #[token(".")]
    Dot,

    #[token("-")]
    Minus,

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
    /// Line comment (-- ...)
    #[regex(r"--[^\n]*", logos::skip)]
    LineComment,

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
        )
    }

    pub fn is_operator(&self) -> bool {
        matches!(
            self,
            TokenKind::PipeOp
                | TokenKind::Arrow
                | TokenKind::Lambda
                | TokenKind::Eq
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
        assert_eq!(
            lexer.next(),
            Some(Ok(TokenKind::Ident("x".to_string())))
        );
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
        assert_eq!(
            lexer.next(),
            Some(Ok(TokenKind::Ident("x".to_string())))
        );
        assert_eq!(lexer.next(), Some(Ok(TokenKind::Arrow)));
        assert_eq!(
            lexer.next(),
            Some(Ok(TokenKind::Ident("x".to_string())))
        );
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
        assert_eq!(
            lexer.next(),
            Some(Ok(TokenKind::Ident("pp".to_string())))
        );
        assert_eq!(
            lexer.next(),
            Some(Ok(TokenKind::Ident("mf".to_string())))
        );
        assert_eq!(
            lexer.next(),
            Some(Ok(TokenKind::Ident("ff".to_string())))
        );
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
        let mut lexer = TokenKind::lexer("let x = 1 -- this is a comment\nlet y = 2");
        assert_eq!(lexer.next(), Some(Ok(TokenKind::Let)));
        assert_eq!(
            lexer.next(),
            Some(Ok(TokenKind::Ident("x".to_string())))
        );
        assert_eq!(lexer.next(), Some(Ok(TokenKind::Eq)));
        assert_eq!(lexer.next(), Some(Ok(TokenKind::Integer(1))));
        assert_eq!(lexer.next(), Some(Ok(TokenKind::Newline)));
        assert_eq!(lexer.next(), Some(Ok(TokenKind::Let)));
    }
}
