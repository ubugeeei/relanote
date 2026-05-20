///|
fn Parser::parse_scale_item(
  self : Parser,
  start : @core.Span,
) -> @core.Spanned[@ast.Item]? {
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
) -> @core.Spanned[@ast.Item]? {
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
/// Parse an `import` declaration. Mirrors `parse_import` in the legacy
/// crate: the head is either a `*` wildcard (optionally `as Alias`), a
/// `{ name [as alias], ... }` group, or a single `name [as alias]`,
/// followed by `from "module-path"`.
fn Parser::parse_import_item(
  self : Parser,
  start : @core.Span,
) -> @core.Spanned[@ast.Item]? {
  let _ = self.advance() // `import`
  let items : Array[@ast.ImportItem] = []
  match self.peek_kind() {
    @lexer.Staccato | @lexer.Star => {
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
                  items.push(@ast.Aliased(name~, as_name=as_ident))
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
                items.push(@ast.Aliased(name~, as_name=as_ident))
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
        let iv = @ast.IntervalLit::new(data.quality(), data.degree()).with_accidentals(
          data.accidentals(),
        )
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
fn Parser::parse_pattern(self : Parser) -> @core.Spanned[@ast.Pattern]? {
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
