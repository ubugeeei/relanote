use logos::Logos;
use relanote_core::{Source, SourceId, Span};
use thiserror::Error;

use crate::token::{Token, TokenKind};

#[derive(Debug, Error)]
pub enum LexerError {
    #[error("unexpected character at {0}:{1}")]
    UnexpectedCharacter(usize, usize),

    #[error("unterminated string literal")]
    UnterminatedString,

    #[error("invalid interval format")]
    InvalidInterval,
}

/// Lexer for relanote source code
pub struct Lexer<'src> {
    source_id: SourceId,
    inner: logos::Lexer<'src, TokenKind>,
    peeked: Option<Token>,
}

impl<'src> Lexer<'src> {
    /// Create a new lexer from source content
    pub fn new(source: &'src Source) -> Self {
        Self {
            source_id: source.id,
            inner: TokenKind::lexer(&source.content),
            peeked: None,
        }
    }

    /// Create a new lexer from a string (for testing)
    pub fn from_str(source_id: SourceId, content: &'src str) -> Self {
        Self {
            source_id,
            inner: TokenKind::lexer(content),
            peeked: None,
        }
    }

    /// Get the current span
    fn current_span(&self) -> Span {
        let range = self.inner.span();
        Span::new(self.source_id, range.start, range.end)
    }

    /// Peek at the next token without consuming it
    pub fn peek(&mut self) -> Option<&Token> {
        if self.peeked.is_none() {
            self.peeked = self.next_token();
        }
        self.peeked.as_ref()
    }

    /// Get the next token
    pub fn next_token(&mut self) -> Option<Token> {
        if let Some(token) = self.peeked.take() {
            return Some(token);
        }

        loop {
            match self.inner.next() {
                Some(Ok(kind)) => {
                    // Keep all tokens including comments - formatter needs them
                    return Some(Token::new(kind, self.current_span()));
                }
                Some(Err(())) => {
                    // Lexer error - create an error token and continue
                    // For now, we skip invalid characters
                    continue;
                }
                None => {
                    // End of input
                    return None;
                }
            }
        }
    }

    /// Tokenize the entire source and return all tokens
    pub fn tokenize(mut self) -> Vec<Token> {
        let mut tokens = Vec::new();
        while let Some(token) = self.next_token() {
            tokens.push(token);
        }
        // Add EOF token
        let eof_span = Span::new(self.source_id, self.inner.span().end, self.inner.span().end);
        tokens.push(Token::eof(eof_span));
        tokens
    }
}

impl Iterator for Lexer<'_> {
    type Item = Token;

    fn next(&mut self) -> Option<Self::Item> {
        self.next_token()
    }
}

#[cfg(test)]
mod tests {
    use relanote_core::Source;

    use super::*;

    fn lex(input: &str) -> Vec<TokenKind> {
        let source = Source::from_string("test", input.to_string());
        Lexer::new(&source)
            .tokenize()
            .into_iter()
            .map(|t| t.kind)
            .collect()
    }

    #[test]
    fn test_lex_scale_definition() {
        let tokens = lex("scale Major = { R, M2, M3, P4, P5, M6, M7 }");
        assert_eq!(tokens[0], TokenKind::Scale);
        assert_eq!(tokens[1], TokenKind::Ident("Major".to_string()));
        assert_eq!(tokens[2], TokenKind::Eq);
        assert_eq!(tokens[3], TokenKind::LBrace);
        assert_eq!(tokens[4], TokenKind::Root);
    }

    #[test]
    fn test_lex_block_with_articulations() {
        let tokens = lex("| R* M3^ P5~ |");
        assert_eq!(tokens[0], TokenKind::Pipe);
        assert_eq!(tokens[1], TokenKind::Root);
        assert_eq!(tokens[2], TokenKind::Staccato);
        // Interval comes next
        assert!(matches!(tokens[3], TokenKind::Interval(_)));
        assert_eq!(tokens[4], TokenKind::Accent);
    }

    #[test]
    fn test_lex_function_application() {
        let tokens = lex("melody_motif |> repeat(2)");
        assert_eq!(tokens[0], TokenKind::Ident("melody_motif".to_string()));
        assert_eq!(tokens[1], TokenKind::PipeOp);
        assert_eq!(tokens[2], TokenKind::Ident("repeat".to_string()));
        assert_eq!(tokens[3], TokenKind::LParen);
        assert_eq!(tokens[4], TokenKind::Integer(2));
        assert_eq!(tokens[5], TokenKind::RParen);
    }

    #[test]
    fn test_lex_section() {
        let tokens = lex(r#"section "Intro" { layer [ ] }"#);
        assert_eq!(tokens[0], TokenKind::Section);
        assert_eq!(tokens[1], TokenKind::String("Intro".to_string()));
        assert_eq!(tokens[2], TokenKind::LBrace);
        assert_eq!(tokens[3], TokenKind::Layer);
    }

    #[test]
    fn test_lex_with_keyword() {
        let tokens = lex("Major with { P4+ }");
        assert_eq!(tokens[0], TokenKind::Ident("Major".to_string()));
        assert_eq!(tokens[1], TokenKind::With);
        assert_eq!(tokens[2], TokenKind::LBrace);
    }

    #[test]
    fn test_lex_env() {
        let tokens = lex("env(pp, mf, 4bars)");
        assert_eq!(tokens[0], TokenKind::Env);
        assert_eq!(tokens[1], TokenKind::LParen);
        // pp and mf are now tokenized as identifiers (dynamics handled at parser level)
        assert_eq!(tokens[2], TokenKind::Ident("pp".to_string()));
    }

    #[test]
    fn test_lex_let_lambda() {
        let tokens = lex(r"let f = \x -> x");
        assert_eq!(tokens[0], TokenKind::Let);
        assert_eq!(tokens[1], TokenKind::Ident("f".to_string()));
        assert_eq!(tokens[2], TokenKind::Eq);
        assert_eq!(tokens[3], TokenKind::Lambda);
        assert_eq!(tokens[4], TokenKind::Ident("x".to_string()));
        assert_eq!(tokens[5], TokenKind::Arrow);
        assert_eq!(tokens[6], TokenKind::Ident("x".to_string()));
        assert_eq!(tokens[7], TokenKind::Eof);
    }

    #[test]
    fn test_lex_pipe_operator() {
        let tokens = lex("x |> reverse");
        assert_eq!(tokens[0], TokenKind::Ident("x".to_string()));
        assert_eq!(tokens[1], TokenKind::PipeOp);
        assert_eq!(tokens[2], TokenKind::Ident("reverse".to_string()));
        assert_eq!(tokens[3], TokenKind::Eof);
    }

    #[test]
    fn test_lex_let_in() {
        let tokens = lex("let x = 42 in x");
        println!("Tokens: {:?}", tokens);
        assert_eq!(tokens[0], TokenKind::Let);
        assert_eq!(tokens[1], TokenKind::Ident("x".to_string()));
        assert_eq!(tokens[2], TokenKind::Eq);
        assert_eq!(tokens[3], TokenKind::Integer(42));
        assert_eq!(tokens[4], TokenKind::In);
        assert_eq!(tokens[5], TokenKind::Ident("x".to_string()));
        assert_eq!(tokens[6], TokenKind::Eof);
    }

    // ===== Newline Tests =====

    #[test]
    fn test_lex_newline_preserved() {
        let tokens = lex("let x = 42\nx");
        assert_eq!(tokens[0], TokenKind::Let);
        assert_eq!(tokens[1], TokenKind::Ident("x".to_string()));
        assert_eq!(tokens[2], TokenKind::Eq);
        assert_eq!(tokens[3], TokenKind::Integer(42));
        assert_eq!(tokens[4], TokenKind::Newline);
        assert_eq!(tokens[5], TokenKind::Ident("x".to_string()));
    }

    #[test]
    fn test_lex_multiple_newlines() {
        let tokens = lex("a\n\nb");
        assert_eq!(tokens[0], TokenKind::Ident("a".to_string()));
        assert_eq!(tokens[1], TokenKind::Newline);
        assert_eq!(tokens[2], TokenKind::Newline);
        assert_eq!(tokens[3], TokenKind::Ident("b".to_string()));
    }

    #[test]
    fn test_lex_comment_preserved() {
        let tokens = lex("a ; this is a comment\nb");
        assert_eq!(tokens[0], TokenKind::Ident("a".to_string()));
        // Comment is preserved for formatter
        assert!(matches!(tokens[1], TokenKind::LineComment(_)));
        assert_eq!(tokens[2], TokenKind::Newline);
        assert_eq!(tokens[3], TokenKind::Ident("b".to_string()));
    }

    // ===== Interval Tests =====

    #[test]
    fn test_lex_intervals() {
        let tokens = lex("R M2 m3 P4 A5 d7");
        assert_eq!(tokens[0], TokenKind::Root);
        assert!(matches!(tokens[1], TokenKind::Interval(_)));
        assert!(matches!(tokens[2], TokenKind::Interval(_)));
        assert!(matches!(tokens[3], TokenKind::Interval(_)));
        assert!(matches!(tokens[4], TokenKind::Interval(_)));
        assert!(matches!(tokens[5], TokenKind::Interval(_)));
    }

    #[test]
    fn test_lex_interval_with_modifiers() {
        let tokens = lex("P5+ M3- P8++");
        assert!(matches!(tokens[0], TokenKind::Interval(_)));
        assert!(matches!(tokens[1], TokenKind::Interval(_)));
        assert!(matches!(tokens[2], TokenKind::Interval(_)));
    }

    // ===== Absolute Pitch Tests =====

    #[test]
    fn test_lex_absolute_pitches() {
        let tokens = lex("C4 D4 Bb3 F#5");
        assert!(matches!(tokens[0], TokenKind::AbsolutePitch(_)));
        assert!(matches!(tokens[1], TokenKind::AbsolutePitch(_)));
        assert!(matches!(tokens[2], TokenKind::AbsolutePitch(_)));
        assert!(matches!(tokens[3], TokenKind::AbsolutePitch(_)));
    }

    // ===== Operator Tests =====

    #[test]
    fn test_lex_concat_operator() {
        let tokens = lex("a ++ b");
        assert_eq!(tokens[0], TokenKind::Ident("a".to_string()));
        assert_eq!(tokens[1], TokenKind::PlusPlus);
        assert_eq!(tokens[2], TokenKind::Ident("b".to_string()));
    }

    #[test]
    fn test_lex_comparison_operators() {
        // Basic comparison operators are lexed as angle brackets
        let tokens = lex("a < b > c");
        assert_eq!(tokens[1], TokenKind::LAngle);
        assert_eq!(tokens[3], TokenKind::RAngle);
    }

    #[test]
    fn test_lex_logical_keywords() {
        // and, or, not are lexed as identifiers (handled at parser level)
        // "a and b or not c" -> [a, and, b, or, not, c]
        let tokens = lex("a and b or not c");
        assert_eq!(tokens[0], TokenKind::Ident("a".to_string()));
        assert_eq!(tokens[1], TokenKind::Ident("and".to_string()));
        assert_eq!(tokens[2], TokenKind::Ident("b".to_string()));
        assert_eq!(tokens[3], TokenKind::Ident("or".to_string()));
        assert_eq!(tokens[4], TokenKind::Ident("not".to_string()));
        assert_eq!(tokens[5], TokenKind::Ident("c".to_string()));
    }

    // ===== Block Syntax Tests =====

    #[test]
    fn test_lex_scale_degree() {
        let tokens = lex("| <1> <3> <5> |");
        assert_eq!(tokens[0], TokenKind::Pipe);
        assert_eq!(tokens[1], TokenKind::LAngle);
        assert_eq!(tokens[2], TokenKind::Integer(1));
        assert_eq!(tokens[3], TokenKind::RAngle);
    }

    #[test]
    fn test_lex_rest() {
        let tokens = lex("| R - M3 |");
        assert_eq!(tokens[0], TokenKind::Pipe);
        assert_eq!(tokens[1], TokenKind::Root);
        assert_eq!(tokens[2], TokenKind::Minus);
    }

    #[test]
    fn test_lex_duration() {
        let tokens = lex("| R:2 M3:4 |");
        assert_eq!(tokens[0], TokenKind::Pipe);
        assert_eq!(tokens[1], TokenKind::Root);
        assert_eq!(tokens[2], TokenKind::Colon);
        assert_eq!(tokens[3], TokenKind::Integer(2));
    }

    // ===== Keyword Tests =====

    #[test]
    fn test_lex_control_flow_keywords() {
        let tokens = lex("if true then a else b");
        assert_eq!(tokens[0], TokenKind::If);
        assert_eq!(tokens[1], TokenKind::True);
        assert_eq!(tokens[2], TokenKind::Then);
        assert_eq!(tokens[4], TokenKind::Else);
    }

    #[test]
    fn test_lex_match_expression() {
        let tokens = lex("match x with | a -> b");
        assert_eq!(tokens[0], TokenKind::Match);
        assert_eq!(tokens[2], TokenKind::With);
        assert_eq!(tokens[3], TokenKind::Pipe);
        assert_eq!(tokens[5], TokenKind::Arrow);
    }

    #[test]
    fn test_lex_synth_definition() {
        let tokens = lex("synth Lead = { osc: Saw }");
        assert_eq!(tokens[0], TokenKind::Synth);
        assert_eq!(tokens[1], TokenKind::Ident("Lead".to_string()));
    }

    // ===== Number Tests =====

    #[test]
    fn test_lex_integers() {
        let tokens = lex("0 42 123");
        assert_eq!(tokens[0], TokenKind::Integer(0));
        assert_eq!(tokens[1], TokenKind::Integer(42));
        assert_eq!(tokens[2], TokenKind::Integer(123));
    }

    #[test]
    fn test_lex_floats() {
        let tokens = lex("0.0 3.14 0.5");
        assert_eq!(tokens[0], TokenKind::Float(0.0));
        assert_eq!(tokens[1], TokenKind::Float(3.14));
        assert_eq!(tokens[2], TokenKind::Float(0.5));
    }

    // ===== String Tests =====

    #[test]
    fn test_lex_strings() {
        let tokens = lex(r#""hello" "world""#);
        assert_eq!(tokens[0], TokenKind::String("hello".to_string()));
        assert_eq!(tokens[1], TokenKind::String("world".to_string()));
    }

    // ===== Bracket Tests =====

    #[test]
    fn test_lex_brackets() {
        let tokens = lex("( ) [ ] { }");
        assert_eq!(tokens[0], TokenKind::LParen);
        assert_eq!(tokens[1], TokenKind::RParen);
        assert_eq!(tokens[2], TokenKind::LBracket);
        assert_eq!(tokens[3], TokenKind::RBracket);
        assert_eq!(tokens[4], TokenKind::LBrace);
        assert_eq!(tokens[5], TokenKind::RBrace);
    }

    // ===== Set Binding Tests =====

    #[test]
    fn test_lex_set_binding() {
        // Note: Key token requires capital K
        let tokens = lex("set Key = C4");
        assert_eq!(tokens[0], TokenKind::Set);
        assert_eq!(tokens[1], TokenKind::Key);
        assert_eq!(tokens[2], TokenKind::Eq);
    }

    #[test]
    fn test_lex_set_tempo() {
        let tokens = lex("set tempo = 120");
        assert_eq!(tokens[0], TokenKind::Set);
        assert_eq!(tokens[1], TokenKind::Ident("tempo".to_string()));
    }
}
