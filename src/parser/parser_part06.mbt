///|
/// Parse left-associative block concatenation above arithmetic terms.
fn Parser::parse_concat(self : Parser) -> @core.Spanned[@ast.Expr]? {
  let initial = self.parse_term()
  match initial {
    None => None
    Some(first) => {
      let mut left = first
      while self.peek_kind() == @lexer.PlusPlus {
        let _ = self.advance()
        self.skip_newlines()
        match self.parse_term() {
          None => return None
          Some(right) => {
            let span = left.span()
            let binary = @ast.Binary::new(@ast.Concat, left, right)
            left = @core.Spanned::new(@ast.Binary(binary), span)
          }
        }
      }
      Some(left)
    }
  }
}

///|
fn Parser::parse_synth_item(
  self : Parser,
  start : @core.Span,
) -> @core.Spanned[@ast.Item]? {
  let _ = self.advance() // `synth`
  match self.parse_ident_token() {
    None => None
    Some(name) =>
      if !self.eat(@lexer.Equals) {
        self.error("expected `=` in synth definition")
        None
      } else if !self.eat(@lexer.LBrace) {
        self.error("expected `{` in synth definition")
        None
      } else {
        let props : Array[@core.Spanned[@ast.SynthProperty]] = []
        self.skip_newlines()
        while self.peek_kind() != @lexer.RBrace && !self.at_eof() {
          match self.parse_synth_property() {
            Some(prop) => props.push(prop)
            None => return None
          }
          let _ = self.eat(@lexer.Comma)
          self.skip_newlines()
        }
        if !self.eat(@lexer.RBrace) {
          self.error("expected `}` to close synth definition")
          None
        } else {
          let s = @ast.SynthDef::new(name, props)
          Some(@core.Spanned::new(@ast.SynthDef(s), start))
        }
      }
  }
}

///|
fn Parser::parse_synth_property(
  self : Parser,
) -> @core.Spanned[@ast.SynthProperty]? {
  let span = self.peek().span()
  let mut which = 0
  match self.peek_kind() {
    @lexer.Osc => {
      let _ = self.advance()
      which = 1
    }
    @lexer.Env => {
      let _ = self.advance()
      which = 2
    }
    @lexer.Filter => {
      let _ = self.advance()
      which = 3
    }
    @lexer.Ident(name) => {
      let _ = self.advance()
      if name == "detune" {
        which = 4
      } else if name == "pitch_env" {
        which = 5
      } else {
        self.error("unknown synth property")
        return None
      }
    }
    _ => {
      self.error("expected a synth property")
      return None
    }
  }
  if !self.eat(@lexer.Colon) {
    self.error("expected `:` after synth property")
    return None
  }
  match self.parse_expr() {
    None => None
    Some(value) => {
      let prop = if which == 1 {
        @ast.Oscillator(value)
      } else if which == 2 {
        @ast.Envelope(value)
      } else if which == 3 {
        @ast.Filter(value)
      } else if which == 4 {
        @ast.Detune(value)
      } else {
        @ast.PitchEnvelope(value)
      }
      Some(@core.Spanned::new(prop, span))
    }
  }
}
