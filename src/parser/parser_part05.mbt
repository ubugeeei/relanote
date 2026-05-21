///|
fn Parser::parse_slot(self : Parser) -> @core.Spanned[@ast.Slot]? {
  let span = self.peek().span()
  // Rests carry an optional `:n` duration of their own; everything
  // else parses a pitch, then walks zero-or-more articulation /
  // duration suffixes.
  match self.peek_kind() {
    @lexer.Minus => {
      let _ = self.advance()
      let duration = self.parse_optional_slot_duration()
      Some(@core.Spanned::new(@ast.Rest(duration~), span))
    }
    @lexer.LBrace => self.parse_tuplet_slot(span)
    @lexer.LBracket => self.parse_chord_slot(span)
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
      Some(self.complete_note(@core.Spanned::new(pitch, span), span))
    }
    @lexer.Interval(data) => {
      let _ = self.advance()
      let iv = @ast.IntervalLit::new(data.quality(), data.degree()).with_accidentals(
        data.accidentals(),
      )
      let pitch : @ast.Pitch = @ast.Interval(iv)
      Some(self.complete_note(@core.Spanned::new(pitch, span), span))
    }
    @lexer.AbsolutePitch(data) => {
      let _ = self.advance()
      let lit = @ast.AbsolutePitchLit::from_data(data)
      // Absolute pitches inside a block fold into an interval-shaped
      // slot — we don't yet model absolute pitches as a `Pitch`
      // variant, so map to the corresponding semitone offset.
      let pitch : @ast.Pitch = @ast.Microtone(absolute_pitch_to_cents(lit))
      Some(self.complete_note(@core.Spanned::new(pitch, span), span))
    }
    @lexer.Root => {
      let _ = self.advance()
      let pitch : @ast.Pitch = @ast.Root
      Some(self.complete_note(@core.Spanned::new(pitch, span), span))
    }
    _ => {
      self.error("unexpected token inside block")
      let _ = self.advance()
      None
    }
  }
}

///|
fn Parser::parse_chord_slot(
  self : Parser,
  span : @core.Span,
) -> @core.Spanned[@ast.Slot]? {
  let _ = self.advance()
  let pitches : Array[@core.Spanned[@ast.Pitch]] = []
  while self.peek_kind() != @lexer.RBracket && !self.at_eof() {
    match self.parse_pitch_atom() {
      None => return None
      Some(pitch) => pitches.push(pitch)
    }
    let _ = self.eat(@lexer.Comma)
  }
  if !self.eat(@lexer.RBracket) {
    self.error("expected `]` to close chord slot")
    return None
  }
  let articulations = self.parse_optional_articulations()
  let duration = self.parse_optional_slot_duration()
  Some(
    @core.Spanned::new(@ast.Chord(pitches~, articulations~, duration~), span),
  )
}

///|
fn Parser::parse_tuplet_slot(
  self : Parser,
  span : @core.Span,
) -> @core.Spanned[@ast.Slot]? {
  let _ = self.advance()
  let contents : Array[@core.Spanned[@ast.Slot]] = []
  while self.peek_kind() != @lexer.RBrace && !self.at_eof() {
    match self.parse_slot() {
      None => return None
      Some(slot) => contents.push(slot)
    }
  }
  if !self.eat(@lexer.RBrace) {
    self.error("expected `}` to close tuplet")
    return None
  }
  if !self.eat(@lexer.Colon) {
    self.error("expected `:` after tuplet")
    return None
  }
  match self.parse_expr() {
    None => None
    Some(target) => {
      let tuplet = @ast.Tuplet::new(contents, target)
      Some(@core.Spanned::new(@ast.Tuplet(tuplet), span))
    }
  }
}

///|
fn Parser::parse_pitch_atom(self : Parser) -> @core.Spanned[@ast.Pitch]? {
  let span = self.peek().span()
  match self.peek_kind() {
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
      Some(@core.Spanned::new(@ast.ScaleIndex(degree), span))
    }
    @lexer.Interval(data) => {
      let _ = self.advance()
      let iv = @ast.IntervalLit::new(data.quality(), data.degree()).with_accidentals(
        data.accidentals(),
      )
      Some(@core.Spanned::new(@ast.Interval(iv), span))
    }
    @lexer.Root => {
      let _ = self.advance()
      Some(@core.Spanned::new(@ast.Root, span))
    }
    _ => {
      self.error("expected a pitch inside chord")
      None
    }
  }
}

///|
/// Finish a `Note` slot by reading any trailing articulations and an
/// optional `:n` duration. Articulations come before the duration —
/// `<1>^*:2` parses but `<1>:2^*` does not (matches the legacy implementation).
fn Parser::complete_note(
  self : Parser,
  pitch : @core.Spanned[@ast.Pitch],
  span : @core.Span,
) -> @core.Spanned[@ast.Slot] {
  let articulations = self.parse_optional_articulations()
  let duration = self.parse_optional_slot_duration()
  let slot : @ast.Slot = @ast.Note(pitch~, articulations~, duration~)
  @core.Spanned::new(slot, span)
}

///|
/// Read zero-or-more articulation markers in source order.
/// `^` is `Accent`, `*` is `Staccato` (or `Star` when the lexer cannot
/// prove suffix context), `~` is `Portamento`.
fn Parser::parse_optional_articulations(
  self : Parser,
) -> Array[@ast.Articulation] {
  let acc : Array[@ast.Articulation] = []
  while true {
    match self.peek_kind() {
      @lexer.Accent => {
        let _ = self.advance()
        acc.push(@ast.Accent)
      }
      @lexer.Staccato => {
        let _ = self.advance()
        acc.push(@ast.Staccato)
      }
      @lexer.Star => {
        let _ = self.advance()
        acc.push(@ast.Staccato)
      }
      @lexer.Portamento => {
        let _ = self.advance()
        acc.push(@ast.Portamento)
      }
      _ => break
    }
  }
  acc
}

///|
/// Read an optional `:n` duration multiplier. Returns `None` when
/// the next token isn't a colon.
fn Parser::parse_optional_slot_duration(self : Parser) -> Int? {
  if self.peek_kind() == @lexer.Colon {
    let _ = self.advance()
    match self.peek_kind() {
      @lexer.Integer(n) => {
        let _ = self.advance()
        Some(n)
      }
      _ => {
        self.error("expected an integer after `:`")
        None
      }
    }
  } else {
    None
  }
}

///|
/// Reduce an `AbsolutePitchLit` to cents-from-C. The AST keeps the
/// raw lit shape for the formatter, but the renderer / evaluator
/// want a flat number — until `Pitch::Absolute` lands we fold the
/// pitch into a `Microtone` carrying the same cents value.
fn absolute_pitch_to_cents(lit : @ast.AbsolutePitchLit) -> Double {
  let letter = match lit.note() {
    'C' => 0
    'D' => 2
    'E' => 4
    'F' => 5
    'G' => 7
    'A' => 9
    'B' => 11
    _ => 0
  }
  let midi = (lit.octave() + 1) * 12 + letter + lit.accidental()
  (midi - 60).to_double() * 100.0
}
