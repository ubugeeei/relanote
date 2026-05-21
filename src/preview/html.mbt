///|
pub fn playground_summary(source : String) -> String {
  let notes = note_events(source)
  notes.length().to_string() +
  " notes / " +
  clean_beats(total_beats(source)) +
  " beats"
}

///|
fn clean_beats(value : Double) -> String {
  let rounded = (value * 1000.0 + 0.5).to_int()
  let whole = rounded / 1000
  let frac = rounded % 1000
  if frac == 0 {
    whole.to_string()
  } else if frac % 100 == 0 {
    whole.to_string() + "." + (frac / 100).to_string()
  } else if frac % 10 == 0 {
    whole.to_string() + "." + pad2(frac / 10)
  } else {
    whole.to_string() + "." + pad3(frac)
  }
}

///|
fn pad2(n : Int) -> String {
  if n < 10 { "0" + n.to_string() } else { n.to_string() }
}

///|
fn pad3(n : Int) -> String {
  if n < 10 {
    "00" + n.to_string()
  } else if n < 100 {
    "0" + n.to_string()
  } else {
    n.to_string()
  }
}

///|
pub fn staff_html(source : String, beat : Double) -> String {
  let notes = note_events(source)
  let width = html_width(source)
  let mut out = "<svg viewBox='0 0 " +
    width.to_string() +
    " 170' role='img' aria-label='Staff preview'>"
  for i = 0; i < 5; i = i + 1 {
    let y = 42 + i * 14
    out = out +
      "<line x1='36' y1='" +
      y.to_string() +
      "' x2='" +
      (width - 20).to_string() +
      "' y2='" +
      y.to_string() +
      "' stroke='#55616d'/>"
  }
  out = out + "<text x='8' y='82' fill='#f6f0e6' font-size='42'>G</text>"
  for n in notes {
    out = out + note_svg(n, beat)
  }
  out + "</svg>"
}

///|
pub fn piano_html(source : String, beat : Double) -> String {
  let width = html_width(source)
  let mut out = "<svg viewBox='0 0 " +
    width.to_string() +
    " 168' role='img' aria-label='Piano roll preview'>"
  for p = 48; p <= 72; p = p + 1 {
    let y = piano_y(p)
    let fill = if is_black_key(p) { "#22242c" } else { "#151820" }
    out = out +
      "<rect x='0' y='" +
      y.to_string() +
      "' width='" +
      width.to_string() +
      "' height='6' fill='" +
      fill +
      "'/>"
  }
  for n in note_events(source) {
    out = out + roll_rect(n, beat)
  }
  out + "</svg>"
}

///|
fn html_width(source : String) -> Int {
  let w = 80 + (total_beats(source) * 56.0).to_int()
  if w < 520 {
    520
  } else {
    w
  }
}

///|
fn note_svg(n : NoteEvent, beat : Double) -> String {
  let x = 58 + (n.start() * 56.0).to_int()
  let y = staff_y(n.pitch())
  let color = if playing(n, beat) { "#ffd05a" } else { "#fff8ed" }
  "<ellipse cx='" +
  x.to_string() +
  "' cy='" +
  y.to_string() +
  "' rx='8' ry='6' fill='" +
  color +
  "' transform='rotate(-18 " +
  x.to_string() +
  " " +
  y.to_string() +
  ")'/>" +
  "<line x1='" +
  (x + 7).to_string() +
  "' y1='" +
  y.to_string() +
  "' x2='" +
  (x + 7).to_string() +
  "' y2='" +
  (y - 42).to_string() +
  "' stroke='" +
  color +
  "'/>"
}

///|
fn roll_rect(n : NoteEvent, beat : Double) -> String {
  let x = 56 + (n.start() * 56.0).to_int()
  let y = piano_y(n.pitch())
  let w = max_int(12, (n.duration() * 56.0).to_int())
  let color = if playing(n, beat) { "#caff55" } else { "#ff4f7a" }
  "<rect x='" +
  x.to_string() +
  "' y='" +
  y.to_string() +
  "' width='" +
  w.to_string() +
  "' height='10' rx='3' fill='" +
  color +
  "'/>"
}

///|
fn staff_y(pitch : Int) -> Int {
  clamp_int(124 - (pitch - 60) * 3, 18, 150)
}

///|
fn piano_y(pitch : Int) -> Int {
  clamp_int(150 - (pitch - 48) * 6, 8, 154)
}

///|
fn is_black_key(pitch : Int) -> Bool {
  match pitch % 12 {
    1 | 3 | 6 | 8 | 10 => true
    _ => false
  }
}

///|
fn playing(n : NoteEvent, beat : Double) -> Bool {
  n.start() <= beat && beat < n.start() + n.duration()
}

///|
fn max_int(a : Int, b : Int) -> Int {
  if a > b {
    a
  } else {
    b
  }
}

///|
fn clamp_int(v : Int, lo : Int, hi : Int) -> Int {
  if v < lo {
    lo
  } else if v > hi {
    hi
  } else {
    v
  }
}
