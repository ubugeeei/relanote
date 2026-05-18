///|
/// Hand-written lexer mirroring `crates/relanote_lexer`. The Rust version is
/// driven by `logos` regexes; this port replicates the same longest-match
/// + priority disambiguation rules:
///
///   * Absolute pitches (priority 4) win same-length ties against
///     intervals, the `R` root marker and identifiers.
///   * Intervals and `R` (priority 3) win same-length ties against
///     identifiers.
///   * Otherwise the longest match wins, exactly like `logos`.
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
/// span sits at the end of input — matching the Rust API exactly.
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

fn Lexer::charcode_at(self : Lexer, idx : Int) -> Int {
  if idx >= self.content.length() {
    -1
  } else {
    self.content.unsafe_get(idx).to_int()
  }
}

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

fn is_ascii_digit(c : Int) -> Bool {
  c >= '0'.to_int() && c <= '9'.to_int()
}

fn is_alpha(c : Int) -> Bool {
  (c >= 'A'.to_int() && c <= 'Z'.to_int()) ||
  (c >= 'a'.to_int() && c <= 'z'.to_int())
}

fn is_ident_start(c : Int) -> Bool {
  is_alpha(c) || c == '_'.to_int()
}

fn is_ident_cont(c : Int) -> Bool {
  is_ident_start(c) || is_ascii_digit(c)
}

fn is_pitch_letter(c : Int) -> Bool {
  c == 'C'.to_int() ||
  c == 'D'.to_int() ||
  c == 'E'.to_int() ||
  c == 'F'.to_int() ||
  c == 'G'.to_int() ||
  c == 'B'.to_int()
}

fn is_quality_letter(c : Int) -> Bool {
  c == 'M'.to_int() ||
  c == 'P'.to_int() ||
  c == 'm'.to_int() ||
  c == 'A'.to_int() ||
  c == 'd'.to_int()
}

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

fn Lexer::lex_line_comment(self : Lexer) -> TokenKind {
  let start = self.offset
  while self.offset < self.content.length() &&
    self.charcode_at(self.offset) != '\n'.to_int() {
    self.offset += 1
  }
  let text = self.content.substring(start=start, end=self.offset)
  LineComment(text)
}

fn Lexer::lex_string(self : Lexer) -> TokenKind {
  // We arrive at the opening quote.
  self.offset += 1
  let content_start = self.offset
  while self.offset < self.content.length() &&
    self.charcode_at(self.offset) != '"'.to_int() {
    self.offset += 1
  }
  let s = self.content.substring(start=content_start, end=self.offset)
  if self.offset < self.content.length() {
    // Consume the closing quote.
    self.offset += 1
  }
  StringLit(s)
}

fn Lexer::lex_number(self : Lexer) -> TokenKind {
  let start = self.offset
  while self.offset < self.content.length() &&
    is_ascii_digit(self.charcode_at(self.offset)) {
    self.offset += 1
  }
  // `[0-9]+bears?` / `[0-9]+beats?` / `[0-9]+bars?` — match the longest
  // suffix first.
  if self.starts_with(self.offset, "beats") {
    self.offset += 5
    return Beats
  }
  if self.starts_with(self.offset, "beat") {
    self.offset += 4
    return Beats
  }
  if self.starts_with(self.offset, "bars") {
    self.offset += 4
    return Bars
  }
  if self.starts_with(self.offset, "bar") {
    self.offset += 3
    return Bars
  }
  // Float: `[0-9]+\.[0-9]+`
  if self.charcode_at(self.offset) == '.'.to_int() &&
    is_ascii_digit(self.charcode_at(self.offset + 1)) {
    self.offset += 1
    while self.offset < self.content.length() &&
      is_ascii_digit(self.charcode_at(self.offset)) {
      self.offset += 1
    }
    let text = self.content.substring(start=start, end=self.offset)
    let parsed = try? @strconv.parse_double(text)
    match parsed {
      Ok(f) => return Float(f)
      Err(_) => return Integer(0)
    }
  }
  let text = self.content.substring(start=start, end=self.offset)
  let parsed = try? @strconv.parse_int(text)
  match parsed {
    Ok(n) => Integer(n)
    Err(_) => Integer(0)
  }
}

// Helpers that look ahead WITHOUT mutating `self.offset`.

fn Lexer::ident_end(self : Lexer, from : Int) -> Int {
  let mut i = from
  while i < self.content.length() && is_ident_cont(self.charcode_at(i)) {
    i += 1
  }
  i
}

fn Lexer::interval_end(self : Lexer, from : Int) -> Int {
  // [MPmAd][1-9][0-9]*[+-]*
  if !is_quality_letter(self.charcode_at(from)) {
    return from
  }
  let d1 = self.charcode_at(from + 1)
  if d1 < '1'.to_int() || d1 > '9'.to_int() {
    return from
  }
  let mut i = from + 2
  while i < self.content.length() && is_ascii_digit(self.charcode_at(i)) {
    i += 1
  }
  while i < self.content.length() {
    let c = self.charcode_at(i)
    if c == '+'.to_int() || c == '-'.to_int() {
      i += 1
    } else {
      break
    }
  }
  i
}

fn Lexer::absolute_pitch_end(self : Lexer, from : Int) -> Int {
  // ( [CDEFGB][#b]? | A[#b] ) [0-9]
  let c0 = self.charcode_at(from)
  let c1 = self.charcode_at(from + 1)
  let c2 = self.charcode_at(from + 2)
  if is_pitch_letter(c0) {
    if c1 == '#'.to_int() || c1 == 'b'.to_int() {
      if is_ascii_digit(c2) {
        return from + 3
      }
    }
    if is_ascii_digit(c1) {
      return from + 2
    }
  }
  if c0 == 'A'.to_int() {
    if (c1 == '#'.to_int() || c1 == 'b'.to_int()) && is_ascii_digit(c2) {
      return from + 3
    }
  }
  from
}

fn Lexer::lex_word(self : Lexer) -> TokenKind {
  let start = self.offset
  let ident_end = self.ident_end(start)
  let ident_len = ident_end - start
  let interval_end = self.interval_end(start)
  let interval_len = interval_end - start
  let pitch_end = self.absolute_pitch_end(start)
  let pitch_len = pitch_end - start

  // Order of priority for same-length matches:
  //   AbsolutePitch (4) > Interval / Root (3) > Ident / keyword (default).
  let mut best_len = ident_len
  // 0 = ident, 1 = root, 2 = interval, 3 = absolute pitch
  let mut best_kind = 0

  if interval_len > best_len {
    best_len = interval_len
    best_kind = 2
  } else if interval_len == best_len && interval_len > 0 {
    best_kind = 2
  }

  // Special case: bare `R` (length 1) outranks an identifier `R`.
  if ident_len == 1 && self.charcode_at(start) == 'R'.to_int() && best_kind == 0 {
    best_kind = 1
    if best_len < 1 {
      best_len = 1
    }
  }

  if pitch_len > best_len {
    best_len = pitch_len
    best_kind = 3
  } else if pitch_len == best_len && pitch_len > 0 {
    best_kind = 3
  }

  if best_kind == 3 {
    self.offset = start + pitch_len
    return self.build_absolute_pitch(start, pitch_len)
  }
  if best_kind == 2 {
    self.offset = start + interval_len
    return self.build_interval(start, interval_len)
  }
  if best_kind == 1 {
    self.offset = start + 1
    return Root
  }
  // Ident or keyword.
  self.offset = start + ident_len
  let text = self.content.substring(start=start, end=start + ident_len)
  keyword_or_ident(text)
}

fn Lexer::build_interval(self : Lexer, start : Int, len : Int) -> TokenKind {
  let quality = quality_of(self.charcode_at(start))
  let mut i = start + 1
  let mut degree = 0
  while i < start + len {
    let c = self.charcode_at(i)
    if is_ascii_digit(c) {
      degree = degree * 10 + (c - '0'.to_int())
      i += 1
    } else {
      break
    }
  }
  let accidentals : Array[Accidental] = []
  while i < start + len {
    let c = self.charcode_at(i)
    if c == '+'.to_int() {
      accidentals.push(Sharp)
    } else if c == '-'.to_int() {
      accidentals.push(Flat)
    }
    i += 1
  }
  Interval(IntervalData::new(quality, degree, accidentals))
}

fn Lexer::build_absolute_pitch(
  self : Lexer,
  start : Int,
  len : Int,
) -> TokenKind {
  let note_code = self.charcode_at(start)
  let note : Char = if note_code == 'A'.to_int() {
    'A'
  } else if note_code == 'B'.to_int() {
    'B'
  } else if note_code == 'C'.to_int() {
    'C'
  } else if note_code == 'D'.to_int() {
    'D'
  } else if note_code == 'E'.to_int() {
    'E'
  } else if note_code == 'F'.to_int() {
    'F'
  } else {
    'G'
  }
  let (accidental, octave_idx) = if len == 3 {
    let c1 = self.charcode_at(start + 1)
    let acc = if c1 == '#'.to_int() {
      1
    } else {
      -1
    }
    (acc, start + 2)
  } else {
    (0, start + 1)
  }
  let octave = self.charcode_at(octave_idx) - '0'.to_int()
  AbsolutePitch(AbsolutePitchData::new(note, accidental, octave))
}

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

fn Lexer::lex_symbol(self : Lexer) -> TokenKind? {
  let c = self.charcode_at(self.offset)
  let c2 = self.charcode_at(self.offset + 1)
  // Two-character operators first.
  if c == '|'.to_int() && c2 == '>'.to_int() {
    self.offset += 2
    return Some(PipeOp)
  }
  if c == '>'.to_int() && c2 == '>'.to_int() {
    self.offset += 2
    return Some(Compose)
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
    Some(Staccato)
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
  } else {
    None
  }
  // Always advance — single-char tokens AND unknown characters both
  // consume one charcode. Unknown characters trigger `next_token`'s outer
  // loop to retry.
  self.offset += 1
  single
}
