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
                    // Skip newlines (treat them as whitespace for now)
                    if matches!(kind, TokenKind::Newline) {
                        continue;
                    }
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
        let eof_span = Span::new(
            self.source_id,
            self.inner.span().end,
            self.inner.span().end,
        );
        tokens.push(Token::eof(eof_span));
        tokens
    }
}

impl<'src> Iterator for Lexer<'src> {
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
}
