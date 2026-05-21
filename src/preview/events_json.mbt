///|
pub fn total_beats(source : String) -> Double {
  let mut end_ = 0.0
  for n in note_events(source) {
    let note_end = n.start() + n.duration()
    if note_end > end_ {
      end_ = note_end
    }
  }
  end_
}

///|
pub fn events_json(source : String) -> String {
  let mut out = "["
  let mut first = true
  for n in note_events(source) {
    if first {
      first = false
    } else {
      out = out + ","
    }
    let voice = if n.voice() == "" {
      ""
    } else {
      ",\"voice\":\"" + n.voice() + "\""
    }
    out = out +
      "{\"pitch\":" +
      n.pitch().to_string() +
      ",\"start\":" +
      n.start().to_string() +
      ",\"duration\":" +
      n.duration().to_string() +
      ",\"velocity\":100" +
      voice +
      "}"
  }
  out + "]"
}
