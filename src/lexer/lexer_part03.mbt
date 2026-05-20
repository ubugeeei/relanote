///|
fn keyword_or_ident(text : String) -> TokenKind {
  match text {
    "let" => Let
    "set" => Set
    "in" => In
    "if" => If
    "then" => Then
    "else" => Else
    "match" => Match
    "with" => With
    "scale" => Scale
    "chord" => Chord
    "section" => Section
    "layer" => Layer
    "part" => Part
    "synth" => Synth
    "osc" => Osc
    "filter" => Filter
    "env" => Env
    "import" => Import
    "export" => Export
    "from" => From
    "as" => As
    "mod" => Mod
    "use" => Use
    "true" => True
    "false" => False
    "render" => Render
    "Context" => Context
    "Key" => Key
    _ => Ident(text)
  }
}

///|
fn Lexer::lex_symbol(self : Lexer) -> TokenKind? {
  let c = self.charcode_at(self.offset)
  let c2 = self.charcode_at(self.offset + 1)
  // Two-character operators first.
  if c == '|'.to_int() && c2 == '>'.to_int() {
    self.offset += 2
    return Some(PipeOp)
  }
  if c == '|'.to_int() && c2 == '|'.to_int() {
    self.offset += 2
    return Some(OrOr)
  }
  if c == '>'.to_int() && c2 == '>'.to_int() {
    self.offset += 2
    return Some(Compose)
  }
  if c == '>'.to_int() && c2 == '='.to_int() {
    self.offset += 2
    return Some(GtEq)
  }
  if c == '<'.to_int() && c2 == '='.to_int() {
    self.offset += 2
    return Some(LtEq)
  }
  if c == '='.to_int() && c2 == '='.to_int() {
    self.offset += 2
    return Some(EqEq)
  }
  if c == '!'.to_int() && c2 == '='.to_int() {
    self.offset += 2
    return Some(NotEq)
  }
  if c == '&'.to_int() && c2 == '&'.to_int() {
    self.offset += 2
    return Some(AndAnd)
  }
  if c == '-'.to_int() && c2 == '>'.to_int() {
    self.offset += 2
    return Some(Arrow)
  }
  if c == ':'.to_int() && c2 == ':'.to_int() {
    self.offset += 2
    return Some(ColonColon)
  }
  if c == '+'.to_int() && c2 == '+'.to_int() {
    self.offset += 2
    return Some(PlusPlus)
  }
  // Single-character tokens.
  let single : TokenKind? = if c == '*'.to_int() {
    if self.star_is_articulation_suffix() {
      Some(Staccato)
    } else {
      Some(Star)
    }
  } else if c == '^'.to_int() {
    Some(Accent)
  } else if c == '~'.to_int() {
    Some(Portamento)
  } else if c == '|'.to_int() {
    Some(Pipe)
  } else if c == '{'.to_int() {
    Some(LBrace)
  } else if c == '}'.to_int() {
    Some(RBrace)
  } else if c == '['.to_int() {
    Some(LBracket)
  } else if c == ']'.to_int() {
    Some(RBracket)
  } else if c == '('.to_int() {
    Some(LParen)
  } else if c == ')'.to_int() {
    Some(RParen)
  } else if c == '<'.to_int() {
    Some(LAngle)
  } else if c == '>'.to_int() {
    Some(RAngle)
  } else if c == '\\'.to_int() {
    Some(Lambda)
  } else if c == '='.to_int() {
    Some(Equals)
  } else if c == '!'.to_int() {
    Some(Bang)
  } else if c == ':'.to_int() {
    Some(Colon)
  } else if c == ','.to_int() {
    Some(Comma)
  } else if c == '.'.to_int() {
    Some(Dot)
  } else if c == '-'.to_int() {
    Some(Minus)
  } else if c == '+'.to_int() {
    Some(Plus)
  } else if c == '/'.to_int() {
    Some(Slash)
  } else if c == '%'.to_int() {
    Some(Percent)
  } else {
    None
  }
  // Always advance — single-char tokens AND unknown characters both
  // consume one charcode. Unknown characters trigger `next_token`'s outer
  // loop to retry.
  self.offset += 1
  single
}

///|
fn Lexer::star_is_articulation_suffix(self : Lexer) -> Bool {
  let prev = self.charcode_at(self.offset - 1)
  let next = self.charcode_at(self.offset + 1)
  let prev_can_end_slot = is_ident_cont(prev) ||
    prev == '>'.to_int() ||
    prev == '^'.to_int() ||
    prev == '~'.to_int()
  let next_can_follow_suffix = is_ascii_space(next) ||
    next == '|'.to_int() ||
    next == ':'.to_int() ||
    next == '^'.to_int() ||
    next == '~'.to_int()
  prev_can_end_slot && next_can_follow_suffix
}
