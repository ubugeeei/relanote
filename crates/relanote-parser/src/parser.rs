//! Main parser for relanote

use relanote_ast::*;
use relanote_core::{intern, Diagnostic, Diagnostics, Source, SourceId, Span, Spanned};
use relanote_lexer::{Lexer, Token, TokenKind};

use crate::error::{ParseError, ParseResult};

/// Main parser for relanote language
pub struct Parser {
    #[allow(dead_code)]
    source_id: SourceId,
    tokens: Vec<Token>,
    pos: usize,
    diagnostics: Diagnostics,
}

impl Parser {
    /// Create a new parser from a source
    pub fn new(source: &Source) -> Self {
        let lexer = Lexer::new(source);
        let tokens = lexer.tokenize();

        Self {
            source_id: source.id,
            tokens,
            pos: 0,
            diagnostics: Diagnostics::new(),
        }
    }

    /// Parse a complete program
    pub fn parse_program(mut self) -> (Program, Diagnostics) {
        let mut items = Vec::new();

        while !self.is_at_end() {
            match self.parse_item() {
                Ok(item) => items.push(item),
                Err(err) => {
                    self.add_error(err);
                    self.synchronize();
                }
            }
        }

        (Program::new(items), self.diagnostics)
    }

    // ===== Token Navigation =====

    /// Check if we've reached the end of input
    pub fn is_at_end(&self) -> bool {
        self.peek().kind == TokenKind::Eof
    }

    /// Get the current token
    pub fn peek(&self) -> &Token {
        self.tokens.get(self.pos).unwrap_or_else(|| {
            self.tokens.last().expect("Token stream should have EOF")
        })
    }

    /// Get the next token without consuming
    pub fn peek_next(&self) -> &Token {
        self.tokens.get(self.pos + 1).unwrap_or_else(|| {
            self.tokens.last().expect("Token stream should have EOF")
        })
    }

    /// Get the current token's kind
    pub fn current(&self) -> &TokenKind {
        &self.peek().kind
    }

    /// Get the current span
    pub fn current_span(&self) -> Span {
        self.peek().span
    }

    /// Advance to the next token
    pub fn advance(&mut self) -> &Token {
        if !self.is_at_end() {
            self.pos += 1;
        }
        self.previous()
    }

    /// Get the previous token
    pub fn previous(&self) -> &Token {
        &self.tokens[self.pos.saturating_sub(1)]
    }

    /// Check if current token matches the given kind
    pub fn check(&self, kind: &TokenKind) -> bool {
        std::mem::discriminant(self.current()) == std::mem::discriminant(kind)
    }

    /// Check if current token is an identifier with the given name
    pub fn check_ident(&self, name: &str) -> bool {
        matches!(self.current(), TokenKind::Ident(n) if n == name)
    }

    /// Consume the current token if it matches
    pub fn match_token(&mut self, kind: &TokenKind) -> bool {
        if self.check(kind) {
            self.advance();
            true
        } else {
            false
        }
    }

    /// Consume the current token if it's an identifier with the given name
    pub fn match_ident(&mut self, name: &str) -> bool {
        if self.check_ident(name) {
            self.advance();
            true
        } else {
            false
        }
    }

    /// Expect a specific token, or return an error
    pub fn expect(&mut self, kind: &TokenKind, expected: &str) -> ParseResult<&Token> {
        if self.check(kind) {
            Ok(self.advance())
        } else {
            Err(ParseError::unexpected_token(
                expected,
                self.current().clone(),
                self.current_span(),
            ))
        }
    }

    /// Create a span from start to current position
    pub fn span_from(&self, start: Span) -> Span {
        start.merge(self.previous().span)
    }

    // ===== Error Handling =====

    /// Add an error to diagnostics
    pub fn add_error(&mut self, error: ParseError) {
        self.diagnostics.add(Diagnostic::error(
            error.to_string(),
            error.span(),
        ));
    }

    /// Synchronize after an error
    fn synchronize(&mut self) {
        self.advance();

        while !self.is_at_end() {
            match self.current() {
                TokenKind::Let
                | TokenKind::Scale
                | TokenKind::Chord
                | TokenKind::Section
                | TokenKind::Import
                | TokenKind::Export => return,
                _ => {
                    self.advance();
                }
            }
        }
    }

    // ===== Parsing Helpers =====

    /// Parse a comma-separated list
    pub fn parse_list<T, F>(&mut self, end: &TokenKind, mut parser: F) -> ParseResult<Vec<T>>
    where
        F: FnMut(&mut Self) -> ParseResult<T>,
    {
        let mut items = Vec::new();

        if !self.check(end) {
            items.push(parser(self)?);

            while self.match_token(&TokenKind::Comma) {
                if self.check(end) {
                    break;
                }
                items.push(parser(self)?);
            }
        }

        Ok(items)
    }

    /// Parse an identifier
    pub fn parse_ident(&mut self) -> ParseResult<Ident> {
        match self.current().clone() {
            TokenKind::Ident(name) => {
                self.advance();
                Ok(Ident::new(intern(&name)))
            }
            _ => Err(ParseError::unexpected_token(
                "identifier",
                self.current().clone(),
                self.current_span(),
            )),
        }
    }
}

/// Parse a string into a program
pub fn parse(source: &str) -> (Program, Diagnostics) {
    let source = Source::from_string("input", source.to_string());
    let parser = Parser::new(&source);
    parser.parse_program()
}

/// Parse a single expression
pub fn parse_expr(source: &str) -> ParseResult<Spanned<Expr>> {
    let source = Source::from_string("input", source.to_string());
    let mut parser = Parser::new(&source);
    parser.parse_expression()
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_parse_let_binding() {
        let (program, diagnostics) = parse("let x = 42");
        assert!(!diagnostics.has_errors(), "Should parse without errors");
        assert_eq!(program.items.len(), 1);
    }

    #[test]
    fn test_parse_scale_def() {
        let (program, diagnostics) = parse("scale Major = { R, M2, M3, P4, P5, M6, M7 }");
        assert!(!diagnostics.has_errors(), "Should parse without errors: {:?}", diagnostics);
        assert_eq!(program.items.len(), 1);
    }

    #[test]
    fn test_parse_block() {
        let (program, diagnostics) = parse("let motif = | R M3 P5 |");
        assert!(!diagnostics.has_errors(), "Should parse without errors: {:?}", diagnostics);
        assert_eq!(program.items.len(), 1);
    }

    #[test]
    fn test_parse_lambda() {
        let (_program, diagnostics) = parse("let f = \\x -> x");
        assert!(!diagnostics.has_errors(), "Should parse without errors: {:?}", diagnostics);
    }

    #[test]
    fn test_parse_pipe() {
        let (_program, diagnostics) = parse("let y = x |> reverse");
        assert!(!diagnostics.has_errors(), "Should parse without errors: {:?}", diagnostics);
    }

    #[test]
    fn test_parse_let_in() {
        let (program, diagnostics) = parse("let x = 42 in x");
        assert!(!diagnostics.has_errors(), "Should parse without errors: {:?}", diagnostics);
        assert_eq!(program.items.len(), 1);
    }
}
