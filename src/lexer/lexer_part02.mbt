///|
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
    let text = self.content[start:self.offset].to_owned()
    let parsed = try? @string.parse_double(text)
    match parsed {
      Ok(f) => return Float(f)
      Err(_) => return Integer(0)
    }
  }
  let text = self.content[start:self.offset].to_owned()
  let parsed = try? @string.parse_int(text)
  match parsed {
    Ok(n) => Integer(n)
    Err(_) => Integer(0)
  }
}

// Helpers that look ahead WITHOUT mutating `self.offset`.

///|
fn Lexer::ident_end(self : Lexer, from : Int) -> Int {
  let mut i = from
  while i < self.content.length() && is_ident_cont(self.charcode_at(i)) {
    i += 1
  }
  i
}

///|
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

///|
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

///|
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
  let text = self.content[start:start + ident_len].to_owned()
  keyword_or_ident(text)
}

///|
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

///|
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
    let acc = if c1 == '#'.to_int() { 1 } else { -1 }
    (acc, start + 2)
  } else {
    (0, start + 1)
  }
  let octave = self.charcode_at(octave_idx) - '0'.to_int()
  AbsolutePitch(AbsolutePitchData::new(note, accidental, octave))
}

///|
