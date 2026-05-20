///|
fn Formatter::format_interval(self : Formatter, iv : @ast.IntervalLit) -> Unit {
  let q = match iv.quality() {
    @lexer.Major => "M"
    @lexer.Minor => "m"
    @lexer.Perfect => "P"
    @lexer.Diminished => "d"
    @lexer.Augmented => "A"
  }
  self.write(q)
  self.write(iv.degree().to_string())
  for a in iv.accidentals() {
    self.write(
      match a {
        @lexer.Sharp => "+"
        @lexer.Flat => "-"
      },
    )
  }
}

///|
fn Formatter::format_absolute_pitch(
  self : Formatter,
  ap : @ast.AbsolutePitchLit,
) -> Unit {
  self.write(ap.note().to_string())
  if ap.accidental() > 0 {
    self.write("#")
  } else if ap.accidental() < 0 {
    self.write("b")
  }
  self.write(ap.octave().to_string())
}

///|
fn Formatter::format_pitch(self : Formatter, p : @ast.Pitch) -> Unit {
  match p {
    @ast.Interval(iv) => self.format_interval(iv)
    @ast.ScaleIndex(n) => {
      self.write("<")
      self.write(n.to_string())
      self.write(">")
    }
    @ast.ScaleIndexMod(n, acc) => {
      self.write("<")
      self.write(n.to_string())
      for a in acc {
        self.write(
          match a {
            @lexer.Sharp => "+"
            @lexer.Flat => "-"
          },
        )
      }
      self.write(">")
    }
    @ast.Microtone(cents) => {
      let sign = if cents >= 0.0 { "+" } else { "" }
      self.write(sign)
      self.write(cents.to_string())
      self.write("c")
    }
    @ast.MicrotonalInterval(iv, cents) => {
      self.format_interval(iv)
      self.write(" ")
      let sign = if cents >= 0.0 { "+" } else { "" }
      self.write(sign)
      self.write(cents.to_string())
      self.write("c")
    }
    @ast.ScaleIndexCents(n, cents) => {
      self.write("<")
      self.write(n.to_string())
      self.write(" ")
      let sign = if cents >= 0.0 { "+" } else { "" }
      self.write(sign)
      self.write(cents.to_string())
      self.write("c>")
    }
    @ast.Root => self.write("R")
  }
}

///|
fn Formatter::format_slot(self : Formatter, slot : @ast.Slot) -> Unit {
  match slot {
    @ast.Note(pitch~, articulations~, duration~) => {
      self.format_pitch(pitch.node())
      for a in articulations {
        self.write(
          match a {
            @ast.Staccato => "*"
            @ast.Accent => "^"
            @ast.Portamento => "~"
          },
        )
      }
      match duration {
        Some(d) => {
          self.write(":")
          self.write(d.to_string())
        }
        None => ()
      }
    }
    @ast.Rest(duration~) => {
      self.write("-")
      match duration {
        Some(d) => {
          self.write(":")
          self.write(d.to_string())
        }
        None => ()
      }
    }
    @ast.Chord(pitches~, articulations~, duration~) => {
      self.write("[")
      let mut i = 0
      while i < pitches.length() {
        if i > 0 {
          self.write(" ")
        }
        self.format_pitch(pitches[i].node())
        i += 1
      }
      self.write("]")
      for a in articulations {
        self.write(
          match a {
            @ast.Staccato => "*"
            @ast.Accent => "^"
            @ast.Portamento => "~"
          },
        )
      }
      match duration {
        Some(d) => {
          self.write(":")
          self.write(d.to_string())
        }
        None => ()
      }
    }
    @ast.Tuplet(t) => self.format_tuplet(t)
  }
}

///|
fn Formatter::format_block(self : Formatter, b : @ast.Block) -> Unit {
  self.write("| ")
  let mut i = 0
  while i < b.slots().length() {
    if i > 0 {
      self.write(" ")
    }
    self.format_slot(b.slots()[i].node())
    i += 1
  }
  self.write(" |")
  match b.beats() {
    Some(beats) => {
      self.write(":")
      self.write(beats.to_string())
    }
    None => ()
  }
}

///|
fn Formatter::format_tuplet(self : Formatter, t : @ast.Tuplet) -> Unit {
  self.write("{ ")
  let mut i = 0
  while i < t.contents().length() {
    if i > 0 {
      self.write(" ")
    }
    self.format_slot(t.contents()[i].node())
    i += 1
  }
  self.write(" }:")
  self.format_expr(t.target_beats().node())
}

///|
fn Formatter::format_envelope(self : Formatter, e : @ast.EnvelopeLit) -> Unit {
  self.write("env(")
  self.format_expr(e.from().node())
  self.write(", ")
  self.format_expr(e.to().node())
  self.write(", ")
  self.format_expr(e.duration().node())
  self.write(")")
}

// ============================================================
// Part / Section / Layer
// ============================================================

///|
fn Formatter::format_part(self : Formatter, p : @ast.PartExpr) -> Unit {
  self.write("part ")
  self.format_expr(p.instrument().node())
  match p.body() {
    Some(b) => {
      self.write(" { ")
      self.format_expr(b.node())
      self.write(" }")
    }
    None => ()
  }
}

///|
fn Formatter::format_section(self : Formatter, s : @ast.SectionExpr) -> Unit {
  self.write("section ")
  self.format_expr(s.name().node())
  self.write(" { ")
  self.format_expr(s.body().node())
  self.write(" }")
}

///|
fn Formatter::format_layer(self : Formatter, l : @ast.LayerExpr) -> Unit {
  self.write("layer [")
  let mut i = 0
  while i < l.parts().length() {
    if i > 0 {
      self.write(", ")
    }
    self.format_expr(l.parts()[i].node())
    i += 1
  }
  self.write("]")
}

// ============================================================
// Pattern
// ============================================================

///|
