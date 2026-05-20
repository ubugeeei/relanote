///|
/// Hand-written lexer with longest-match + priority disambiguation:
///
///   * Absolute pitches (priority 4) win same-length ties against
///     intervals, the `R` root marker and identifiers.
///   * Intervals and `R` (priority 3) win same-length ties against
///     identifiers.
///   * Otherwise the longest match wins.
pub struct Lexer {
  source : @core.SourceId
  content : String
  mut offset : Int
}

///|
pub fn Lexer::new(source : @core.Source) -> Lexer {
  { source: source.id(), content: source.content(), offset: 0 }
}

///|
pub fn Lexer::from_string(source : @core.SourceId, content : String) -> Lexer {
  { source, content, offset: 0 }
}

///|
/// Tokenize the entire input, terminating with a single `Eof` token whose
/// span sits at the end of input.
pub fn Lexer::tokenize(self : Lexer) -> Array[Token] {
  let tokens : Array[Token] = []
  while true {
    match self.next_token() {
      Some(t) => tokens.push(t)
      None => break
    }
  }
  let end = self.offset
  tokens.push(Token::eof(@core.Span::new(self.source, end, end)))
  tokens
}

///|
/// Pull the next non-skipped token. Returns `None` only at end of input.
pub fn Lexer::next_token(self : Lexer) -> Token? {
  while true {
    // Skip whitespace except newlines, which are significant.
    while self.offset < self.content.length() {
      let c = self.charcode_at(self.offset)
      if c == ' '.to_int() || c == '\t'.to_int() || c == '\r'.to_int() {
        self.offset += 1
      } else {
        break
      }
    }
    if self.offset >= self.content.length() {
      return None
    }
    let start = self.offset
    match self.lex_one() {
      Some(kind) =>
        return Some(
          Token::new(kind, @core.Span::new(self.source, start, self.offset)),
        )
      None => continue
    }
  }
  None
}

// ============================================================
// Internal helpers
// ============================================================

///|
fn Lexer::charcode_at(self : Lexer, idx : Int) -> Int {
  if idx < 0 || idx >= self.content.length() {
    -1
  } else {
    self.content.unsafe_get(idx).to_int()
  }
}

///|
fn Lexer::starts_with(self : Lexer, idx : Int, needle : String) -> Bool {
  let n = needle.length()
  if idx + n > self.content.length() {
    return false
  }
  let mut i = 0
  while i < n {
    if self.content.unsafe_get(idx + i) != needle.unsafe_get(i) {
      return false
    }
    i += 1
  }
  true
}

///|
fn is_ascii_digit(c : Int) -> Bool {
  c >= '0'.to_int() && c <= '9'.to_int()
}

///|
fn is_alpha(c : Int) -> Bool {
  (c >= 'A'.to_int() && c <= 'Z'.to_int()) ||
  (c >= 'a'.to_int() && c <= 'z'.to_int())
}

///|
fn is_ident_start(c : Int) -> Bool {
  is_alpha(c) || c == '_'.to_int()
}

///|
fn is_ident_cont(c : Int) -> Bool {
  is_ident_start(c) || is_ascii_digit(c)
}

///|
fn is_ascii_space(c : Int) -> Bool {
  c == ' '.to_int() ||
  c == '\t'.to_int() ||
  c == '\r'.to_int() ||
  c == '\n'.to_int() ||
  c == -1
}

///|
fn is_pitch_letter(c : Int) -> Bool {
  c == 'C'.to_int() ||
  c == 'D'.to_int() ||
  c == 'E'.to_int() ||
  c == 'F'.to_int() ||
  c == 'G'.to_int() ||
  c == 'B'.to_int()
}

///|
fn is_quality_letter(c : Int) -> Bool {
  c == 'M'.to_int() ||
  c == 'P'.to_int() ||
  c == 'm'.to_int() ||
  c == 'A'.to_int() ||
  c == 'd'.to_int()
}

///|
fn quality_of(c : Int) -> IntervalQuality {
  if c == 'M'.to_int() {
    Major
  } else if c == 'P'.to_int() {
    Perfect
  } else if c == 'm'.to_int() {
    Minor
  } else if c == 'A'.to_int() {
    Augmented
  } else {
    Diminished
  }
}

// ============================================================
// Per-position dispatch
// ============================================================

///|
fn Lexer::lex_one(self : Lexer) -> TokenKind? {
  let c = self.charcode_at(self.offset)
  if c == '\n'.to_int() {
    self.offset += 1
    return Some(Newline)
  }
  if c == ';'.to_int() {
    return Some(self.lex_line_comment())
  }
  if c == '"'.to_int() {
    return Some(self.lex_string())
  }
  if is_ascii_digit(c) {
    return Some(self.lex_number())
  }
  if is_ident_start(c) {
    return Some(self.lex_word())
  }
  self.lex_symbol()
}

///|
fn Lexer::lex_line_comment(self : Lexer) -> TokenKind {
  let start = self.offset
  while self.offset < self.content.length() &&
        self.charcode_at(self.offset) != '\n'.to_int() {
    self.offset += 1
  }
  let text = self.content[start:self.offset].to_owned()
  LineComment(text)
}

///|
fn Lexer::lex_string(self : Lexer) -> TokenKind {
  // We arrive at the opening quote.
  self.offset += 1
  let content_start = self.offset
  while self.offset < self.content.length() &&
        self.charcode_at(self.offset) != '"'.to_int() {
    self.offset += 1
  }
  let s = self.content[content_start:self.offset].to_owned()
  if self.offset < self.content.length() {
    // Consume the closing quote.
    self.offset += 1
  }
  StringLit(s)
}

///|
