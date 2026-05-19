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
/// mirroring the Rust crate's best-effort recovery.
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
pub fn parse_source(
  source : @core.Source,
) -> (@ast.Program, @core.Diagnostics) {
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
fn Parser::parse_item(
  self : Parser,
) -> (@core.Spanned[@ast.Item])? {
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
) -> (@core.Spanned[@ast.Item])? {
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
) -> (@core.Spanned[@ast.Item])? {
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
fn Parser::parse_scale_item(
  self : Parser,
  start : @core.Span,
) -> (@core.Spanned[@ast.Item])? {
  let _ = self.advance() // `scale`
  match self.parse_ident_token() {
    None => None
    Some(name) =>
      if !self.eat(@lexer.Equals) {
        self.error("expected `=` in scale definition")
        None
      } else if !self.eat(@lexer.LBrace) {
        self.error("expected `{` in scale definition")
        None
      } else {
        let intervals = self.parse_interval_list(@lexer.RBrace)
        if !self.eat(@lexer.RBrace) {
          self.error("expected `}` to close scale definition")
          None
        } else {
          let s = @ast.ScaleDef::new(name, None, intervals)
          Some(@core.Spanned::new(@ast.ScaleDef(s), start))
        }
      }
  }
}

///|
fn Parser::parse_chord_item(
  self : Parser,
  start : @core.Span,
) -> (@core.Spanned[@ast.Item])? {
  let _ = self.advance() // `chord`
  match self.parse_ident_token() {
    None => None
    Some(name) =>
      if !self.eat(@lexer.Equals) {
        self.error("expected `=` in chord definition")
        None
      } else if !self.eat(@lexer.LBracket) {
        self.error("expected `[` in chord definition")
        None
      } else {
        let intervals = self.parse_interval_list(@lexer.RBracket)
        if !self.eat(@lexer.RBracket) {
          self.error("expected `]` to close chord definition")
          None
        } else {
          let c = @ast.ChordDef::new(name, intervals)
          Some(@core.Spanned::new(@ast.ChordDef(c), start))
        }
      }
  }
}

///|
/// Parse an `import` declaration. Mirrors `parse_import` in the Rust
/// crate: the head is either a `*` wildcard (optionally `as Alias`), a
/// `{ name [as alias], ... }` group, or a single `name [as alias]`,
/// followed by `from "module-path"`.
fn Parser::parse_import_item(
  self : Parser,
  start : @core.Span,
) -> (@core.Spanned[@ast.Item])? {
  let _ = self.advance() // `import`
  let items : Array[@ast.ImportItem] = []
  match self.peek_kind() {
    @lexer.Staccato => {
      let _ = self.advance()
      if self.eat(@lexer.As) {
        match self.parse_ident_token() {
          None => return None
          Some(as_ident) => items.push(@ast.AllAliased(as_ident))
        }
      } else {
        items.push(@ast.All)
      }
    }
    @lexer.LBrace => {
      let _ = self.advance()
      while true {
        match self.parse_ident_token() {
          None => return None
          Some(name) =>
            if self.eat(@lexer.As) {
              match self.parse_ident_token() {
                None => return None
                Some(as_ident) =>
                  items.push(@ast.Aliased(name=name, as_name=as_ident))
              }
            } else {
              items.push(@ast.Named(name))
            }
        }
        if !self.eat(@lexer.Comma) {
          break
        }
      }
      if !self.eat(@lexer.RBrace) {
        self.error("expected `}` to close import list")
        return None
      }
    }
    _ =>
      match self.parse_ident_token() {
        None => return None
        Some(name) =>
          if self.eat(@lexer.As) {
            match self.parse_ident_token() {
              None => return None
              Some(as_ident) =>
                items.push(@ast.Aliased(name=name, as_name=as_ident))
            }
          } else {
            items.push(@ast.Named(name))
          }
      }
  }
  if !self.eat(@lexer.From) {
    self.error("expected `from` in import declaration")
    return None
  }
  let from = match self.peek_kind() {
    @lexer.StringLit(s) => {
      let _ = self.advance()
      s
    }
    _ => {
      self.error("expected module path string after `from`")
      return None
    }
  }
  let decl = @ast.ImportDecl::new(items, from)
  Some(@core.Spanned::new(@ast.Import(decl), start))
}

///|
/// Parse a comma-separated list of interval literals up to (but not
/// consuming) `end`.
fn Parser::parse_interval_list(
  self : Parser,
  end : @lexer.TokenKind,
) -> Array[@core.Spanned[@ast.IntervalLit]] {
  let out : Array[@core.Spanned[@ast.IntervalLit]] = []
  while self.peek_kind() != end && !self.at_eof() {
    let span = self.peek().span()
    match self.peek_kind() {
      @lexer.Interval(data) => {
        let _ = self.advance()
        let iv = @ast.IntervalLit::new(data.quality(), data.degree())
          .with_accidentals(data.accidentals())
        out.push(@core.Spanned::new(iv, span))
      }
      @lexer.Root => {
        let _ = self.advance()
        let iv = @ast.IntervalLit::new(@lexer.Perfect, 1)
        out.push(@core.Spanned::new(iv, span))
      }
      _ => {
        self.error("expected an interval literal")
        let _ = self.advance()
      }
    }
    let _ = self.eat(@lexer.Comma)
    self.skip_newlines()
  }
  out
}

// ----------------------------------------------------------------------
// Patterns
// ----------------------------------------------------------------------

///|
fn Parser::parse_pattern(self : Parser) -> (@core.Spanned[@ast.Pattern])? {
  let span = self.peek().span()
  match self.peek_kind() {
    @lexer.Ident(name) => {
      let _ = self.advance()
      if name == "_" {
        Some(@core.Spanned::new(@ast.Wildcard, span))
      } else {
        let id = @ast.Ident::new(name)
        Some(@core.Spanned::new(@ast.Ident(id), span))
      }
    }
    @lexer.Integer(n) => {
      let _ = self.advance()
      let lit : @ast.LiteralPattern = @ast.Integer(n.to_int64())
      Some(@core.Spanned::new(@ast.Literal(lit), span))
    }
    @lexer.True => {
      let _ = self.advance()
      Some(@core.Spanned::new(@ast.Literal(@ast.BoolLit(true)), span))
    }
    @lexer.False => {
      let _ = self.advance()
      Some(@core.Spanned::new(@ast.Literal(@ast.BoolLit(false)), span))
    }
    _ => {
      self.error("expected a pattern")
      None
    }
  }
}

///|
fn Parser::parse_ident_token(self : Parser) -> @ast.Ident? {
  match self.peek_kind() {
    @lexer.Ident(name) => {
      let _ = self.advance()
      Some(@ast.Ident::new(name))
    }
    _ => {
      self.error("expected an identifier")
      None
    }
  }
}

// ----------------------------------------------------------------------
// Expressions
// ----------------------------------------------------------------------

///|
fn Parser::parse_expr(self : Parser) -> (@core.Spanned[@ast.Expr])? {
  // Pipe (`|>`) is the lowest-precedence operator wired today. Each
  // pipe segment is `parse_postfix`, which handles `expr(args)`
  // application calls so `arg |> f(x)` parses naturally.
  let initial = self.parse_postfix()
  match initial {
    None => None
    Some(first) => {
      let mut left = first
      while self.peek_kind() == @lexer.PipeOp {
        let _ = self.advance()
        match self.parse_postfix() {
          None => return None
          Some(right) => {
            let span = left.span()
            let pipe = @ast.Pipe::new(left, right)
            left = @core.Spanned::new(@ast.Pipe(pipe), span)
          }
        }
      }
      Some(left)
    }
  }
}

///|
/// Parse a primary expression followed by zero or more postfix call
/// applications `expr(args, ...)`. Mirrors `parse_postfix_expr` in the
/// Rust crate — the Haskell-style space-separated form lands in a
/// follow-up because it needs the full `can_start_argument` analysis.
fn Parser::parse_postfix(
  self : Parser,
) -> (@core.Spanned[@ast.Expr])? {
  let initial = self.parse_primary()
  match initial {
    None => None
    Some(first) => {
      let mut head = first
      while self.peek_kind() == @lexer.LParen {
        let _ = self.advance() // `(`
        let args : Array[@core.Spanned[@ast.Expr]] = []
        if self.peek_kind() != @lexer.RParen {
          while true {
            match self.parse_expr() {
              None => return None
              Some(arg) => args.push(arg)
            }
            if !self.eat(@lexer.Comma) {
              break
            }
          }
        }
        if !self.eat(@lexer.RParen) {
          self.error("expected `)` to close call arguments")
          return None
        }
        let span = head.span()
        head = @core.Spanned::new(
          @ast.Application(@ast.Application::new(head, args)),
          span,
        )
      }
      Some(head)
    }
  }
}

///|
fn Parser::parse_primary(
  self : Parser,
) -> (@core.Spanned[@ast.Expr])? {
  let span = self.peek().span()
  match self.peek_kind() {
    @lexer.Integer(n) => {
      let _ = self.advance()
      Some(@core.Spanned::new(@ast.Integer(n.to_int64()), span))
    }
    @lexer.Float(f) => {
      let _ = self.advance()
      Some(@core.Spanned::new(@ast.Float(f), span))
    }
    @lexer.StringLit(s) => {
      let _ = self.advance()
      Some(@core.Spanned::new(@ast.StringLit(s), span))
    }
    @lexer.True => {
      let _ = self.advance()
      Some(@core.Spanned::new(@ast.BoolLit(true), span))
    }
    @lexer.False => {
      let _ = self.advance()
      Some(@core.Spanned::new(@ast.BoolLit(false), span))
    }
    @lexer.Ident(name) => {
      let _ = self.advance()
      Some(@core.Spanned::new(@ast.Ident(@ast.Ident::new(name)), span))
    }
    @lexer.Interval(data) => {
      let _ = self.advance()
      let iv = @ast.IntervalLit::new(data.quality(), data.degree())
        .with_accidentals(data.accidentals())
      Some(@core.Spanned::new(@ast.Interval(iv), span))
    }
    @lexer.AbsolutePitch(data) => {
      let _ = self.advance()
      let ap = @ast.AbsolutePitchLit::from_data(data)
      Some(@core.Spanned::new(@ast.AbsolutePitch(ap), span))
    }
    @lexer.Root => {
      let _ = self.advance()
      Some(@core.Spanned::new(@ast.Root, span))
    }
    @lexer.LParen => {
      let _ = self.advance()
      if self.peek_kind() == @lexer.RParen {
        let _ = self.advance()
        Some(@core.Spanned::new(@ast.UnitLit, span))
      } else {
        match self.parse_expr() {
          None => None
          Some(inner) => {
            if !self.eat(@lexer.RParen) {
              self.error("expected `)`")
            }
            Some(@core.Spanned::new(@ast.Paren(inner), span))
          }
        }
      }
    }
    @lexer.Pipe => self.parse_block_expr(span)
    @lexer.Lambda => self.parse_lambda_expr(span)
    _ => {
      self.error("expected an expression")
      None
    }
  }
}

///|
/// Parse a lambda literal — `\pat -> expr` or `\p1 p2 -> expr`.
fn Parser::parse_lambda_expr(
  self : Parser,
  start : @core.Span,
) -> (@core.Spanned[@ast.Expr])? {
  let _ = self.advance() // `\`
  let params : Array[@core.Spanned[@ast.Pattern]] = []
  while self.peek_kind() != @lexer.Arrow && !self.at_eof() {
    match self.parse_pattern() {
      None => return None
      Some(p) => params.push(p)
    }
  }
  if !self.eat(@lexer.Arrow) {
    self.error("expected `->` in lambda")
    return None
  }
  if params.length() == 0 {
    self.error("lambda needs at least one parameter")
    return None
  }
  match self.parse_expr() {
    None => None
    Some(body) =>
      Some(
        @core.Spanned::new(
          @ast.Lambda(@ast.Lambda::new(params, body)),
          start,
        ),
      )
  }
}

///|
/// Parse `| slot slot ... |` and an optional `:n` beats annotation.
fn Parser::parse_block_expr(
  self : Parser,
  start : @core.Span,
) -> (@core.Spanned[@ast.Expr])? {
  let _ = self.advance() // opening `|`
  let slots : Array[@core.Spanned[@ast.Slot]] = []
  while self.peek_kind() != @lexer.Pipe && !self.at_eof() {
    match self.parse_slot() {
      Some(slot) => slots.push(slot)
      None => break
    }
  }
  if !self.eat(@lexer.Pipe) {
    self.error("expected closing `|`")
    return None
  }
  // Optional `:n` beats annotation.
  let block = if self.eat(@lexer.Colon) {
    match self.peek_kind() {
      @lexer.Integer(n) => {
        let _ = self.advance()
        @ast.Block::with_beats(slots, n.to_double())
      }
      @lexer.Float(f) => {
        let _ = self.advance()
        @ast.Block::with_beats(slots, f)
      }
      _ => {
        self.error("expected a beat count after `:`")
        @ast.Block::new(slots)
      }
    }
  } else {
    @ast.Block::new(slots)
  }
  Some(@core.Spanned::new(@ast.Block(block), start))
}

///|
fn Parser::parse_slot(self : Parser) -> (@core.Spanned[@ast.Slot])? {
  let span = self.peek().span()
  match self.peek_kind() {
    @lexer.Minus => {
      let _ = self.advance()
      Some(@core.Spanned::new(@ast.Rest(duration=None), span))
    }
    @lexer.LAngle => {
      let _ = self.advance()
      let degree = match self.peek_kind() {
        @lexer.Integer(n) => {
          let _ = self.advance()
          n
        }
        _ => {
          self.error("expected a scale degree after `<`")
          return None
        }
      }
      if !self.eat(@lexer.RAngle) {
        self.error("expected `>` to close scale-degree reference")
        return None
      }
      let pitch : @ast.Pitch = @ast.ScaleIndex(degree)
      let slot : @ast.Slot = @ast.Note(
        pitch=@core.Spanned::new(pitch, span),
        articulations=[],
        duration=None,
      )
      Some(@core.Spanned::new(slot, span))
    }
    @lexer.Interval(data) => {
      let _ = self.advance()
      let iv = @ast.IntervalLit::new(data.quality(), data.degree())
        .with_accidentals(data.accidentals())
      let pitch : @ast.Pitch = @ast.Interval(iv)
      let slot : @ast.Slot = @ast.Note(
        pitch=@core.Spanned::new(pitch, span),
        articulations=[],
        duration=None,
      )
      Some(@core.Spanned::new(slot, span))
    }
    @lexer.Root => {
      let _ = self.advance()
      let pitch : @ast.Pitch = @ast.Root
      let slot : @ast.Slot = @ast.Note(
        pitch=@core.Spanned::new(pitch, span),
        articulations=[],
        duration=None,
      )
      Some(@core.Spanned::new(slot, span))
    }
    _ => {
      self.error("unexpected token inside block")
      let _ = self.advance()
      None
    }
  }
}
