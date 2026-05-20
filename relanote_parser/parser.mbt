///|
/// Hand-rolled recursive-descent parser for relanote.
///
/// This pass covers a foundational subset of the grammar:
///
/// - Top-level items: `let x = expr`, `set name = expr`,
///   `scale Name = { intervals }`, `chord Name = [ intervals ]`,
///   bare expression statements.
/// - Expressions: literals (`Integer`, `Float`, `String`, `Bool`),
///   identifiers, interval literals, absolute pitches, root marker,
///   parenthesised expressions, blocks (`| slots |` with optional
///   `:n` beats annotation), and pipe (`|>`) chains.
/// - Slots inside a block: scale-degree references (`<n>`), interval
///   notes, root notes, rests (`-`).
///
/// The rest of the grammar — binary arithmetic, comparison, logical
/// operators, function application, lambdas, `match`, `with`, the
/// sound-design declarations (`tuning`, `groove`, `effect`, `mix`),
/// chord-slot notation, articulations, durations, microtonal cents,
/// the `over` polyrhythm operator — is intentionally deferred. Each
/// unhandled case records a diagnostic and skips ahead so the
/// remaining input still parses.
///
/// Diagnostics accumulate on `self.diagnostics` rather than aborting,
/// mirroring the legacy implementation best-effort recovery.
pub struct Parser {
  source : @core.Source
  tokens : Array[@lexer.Token]
  mut cursor : Int
  diagnostics : @core.Diagnostics
}

///|
pub fn Parser::new(source : @core.Source) -> Parser {
  let tokens = @lexer.Lexer::new(source).tokenize()
  { source, tokens, cursor: 0, diagnostics: @core.Diagnostics::new() }
}

///|
pub fn Parser::source(self : Parser) -> @core.Source {
  self.source
}

///|
pub fn Parser::tokens(self : Parser) -> Array[@lexer.Token] {
  self.tokens
}

///|
pub fn Parser::diagnostics(self : Parser) -> @core.Diagnostics {
  self.diagnostics
}

// ----------------------------------------------------------------------
// Cursor helpers
// ----------------------------------------------------------------------

///|
fn Parser::peek(self : Parser) -> @lexer.Token {
  if self.cursor < self.tokens.length() {
    self.tokens[self.cursor]
  } else {
    @lexer.Token::eof(@core.Span::dummy())
  }
}

///|
fn Parser::peek_kind(self : Parser) -> @lexer.TokenKind {
  self.peek().kind()
}

///|
fn Parser::advance(self : Parser) -> @lexer.Token {
  let t = self.peek()
  self.cursor += 1
  t
}

///|
fn Parser::at_eof(self : Parser) -> Bool {
  match self.peek_kind() {
    @lexer.Eof => true
    _ => false
  }
}

///|
fn Parser::error(self : Parser, message : String) -> Unit {
  self.diagnostics.error(message, self.peek().span())
}

///|
/// Consume the next token if its kind matches. Returns whether a
/// token was consumed.
fn Parser::eat(self : Parser, kind : @lexer.TokenKind) -> Bool {
  if self.peek_kind() == kind {
    let _ = self.advance()
    true
  } else {
    false
  }
}

///|
fn Parser::skip_newlines(self : Parser) -> Unit {
  while self.peek_kind() == @lexer.Newline {
    let _ = self.advance()
  }
}

// ----------------------------------------------------------------------
// Entry points
// ----------------------------------------------------------------------

///|
/// Parse the captured source into a `Program` plus accumulated
/// diagnostics. Mirrors `relanote_parser::Parser::parse_program`.
pub fn Parser::parse_program(
  self : Parser,
) -> (@ast.Program, @core.Diagnostics) {
  let items : Array[@core.Spanned[@ast.Item]] = []
  self.skip_newlines()
  while !self.at_eof() {
    match self.parse_item() {
      Some(item) => items.push(item)
      None =>
        // Error already recorded; advance to recover unless we're
        // already at EOF.
        if !self.at_eof() {
          let _ = self.advance()
        }
    }
    self.skip_newlines()
  }
  (@ast.Program::new(items), self.diagnostics)
}

///|
pub fn parse_source(source : @core.Source) -> (@ast.Program, @core.Diagnostics) {
  Parser::new(source).parse_program()
}

///|
pub fn parse_string(
  name : String,
  content : String,
) -> (@ast.Program, @core.Diagnostics) {
  parse_source(@core.Source::from_string(name, content))
}

///|
pub fn parse(source : String) -> (@ast.Program, @core.Diagnostics) {
  parse_string("<input>", source)
}

// ----------------------------------------------------------------------
// Items
// ----------------------------------------------------------------------

///|
fn Parser::parse_item(self : Parser) -> @core.Spanned[@ast.Item]? {
  let start = self.peek().span()
  match self.peek_kind() {
    @lexer.Let => self.parse_let_item(start)
    @lexer.Set => self.parse_set_item(start)
    @lexer.Scale => self.parse_scale_item(start)
    @lexer.Chord => self.parse_chord_item(start)
    @lexer.Import => self.parse_import_item(start)
    _ =>
      match self.parse_expr() {
        Some(e) => Some(@core.Spanned::new(@ast.ExprStmt(e), e.span()))
        None => {
          self.error("expected an item or expression at top level")
          None
        }
      }
  }
}

///|
fn Parser::parse_let_item(
  self : Parser,
  start : @core.Span,
) -> @core.Spanned[@ast.Item]? {
  let _ = self.advance() // `let`
  match self.parse_pattern() {
    None => None
    Some(pat) =>
      if !self.eat(@lexer.Equals) {
        self.error("expected `=` in let binding")
        None
      } else {
        match self.parse_expr() {
          None => None
          Some(value) => {
            let binding = @ast.LetBinding::new(pat, None, value)
            Some(@core.Spanned::new(@ast.LetBinding(binding), start))
          }
        }
      }
  }
}

///|
fn Parser::parse_set_item(
  self : Parser,
  start : @core.Span,
) -> @core.Spanned[@ast.Item]? {
  let _ = self.advance() // `set`
  match self.parse_ident_token() {
    None => None
    Some(name) =>
      if !self.eat(@lexer.Equals) {
        self.error("expected `=` in set binding")
        None
      } else {
        match self.parse_expr() {
          None => None
          Some(value) => {
            let s = @ast.SetBinding::new(name, value)
            Some(@core.Spanned::new(@ast.SetBinding(s), start))
          }
        }
      }
  }
}

///|
