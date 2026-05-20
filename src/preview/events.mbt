///|
pub struct NoteEvent {
  pitch : Int
  start : Double
  duration : Double
  velocity : Int
}

///|
fn NoteEvent::new(pitch : Int, start : Double, duration : Double) -> NoteEvent {
  { pitch, start, duration, velocity: 100 }
}

///|
pub fn NoteEvent::pitch(self : NoteEvent) -> Int {
  self.pitch
}

///|
pub fn NoteEvent::start(self : NoteEvent) -> Double {
  self.start
}

///|
pub fn NoteEvent::duration(self : NoteEvent) -> Double {
  self.duration
}

///|
pub fn note_events(source : String) -> Array[NoteEvent] {
  match eval_source(source) {
    Ok(value) => {
      let out : Array[NoteEvent] = []
      collect_value(value, out, 0.0) |> ignore
      out
    }
    Err(_) => []
  }
}

///|
fn eval_source(source : String) -> Result[@eval.Value, String] {
  let src = @core.Source::from_string("<preview>", source)
  let (program, parse_diags) = @parser.parse_source(src)
  if parse_diags.has_errors() {
    return Err("parse error")
  }
  let checker = @types.TypeChecker::new()
  if checker.check_program(program).length() > 0 {
    return Err("type error")
  }
  @eval.Evaluator::new().eval_program(program).map_err(fn(e) { e.message() })
}

///|
fn collect_value(
  value : @eval.Value,
  out : Array[NoteEvent],
  start : Double,
) -> Double {
  match value {
    @eval.BlockV(block) => collect_block(block, out, start)
    @eval.IntervalV(semitones) => {
      out.push(NoteEvent::new(60 + semitones, start, 1.0))
      start + 1.0
    }
    @eval.AbsolutePitchV(midi) => {
      out.push(NoteEvent::new(midi, start, 1.0))
      start + 1.0
    }
    @eval.RootV => {
      out.push(NoteEvent::new(60, start, 1.0))
      start + 1.0
    }
    _ => start
  }
}

///|
fn collect_block(
  block : @ast.Block,
  out : Array[NoteEvent],
  start : Double,
) -> Double {
  let count = block.slots().length()
  if count == 0 {
    return start
  }
  let per = block.duration_beats() / count.to_double()
  let mut cursor = start
  for spanned in block.slots() {
    let dur = slot_duration(spanned.node(), per)
    match spanned.node() {
      @ast.Note(pitch~, ..) =>
        out.push(NoteEvent::new(pitch_to_midi(pitch.node()), cursor, dur))
      @ast.Chord(pitches~, ..) =>
        for p in pitches {
          out.push(NoteEvent::new(pitch_to_midi(p.node()), cursor, dur))
        }
      @ast.Rest(_) | @ast.Tuplet(_) => ()
    }
    cursor += dur
  }
  cursor
}

///|
fn slot_duration(slot : @ast.Slot, per : Double) -> Double {
  let m = match slot {
    @ast.Note(duration~, ..) => duration
    @ast.Rest(duration~) => duration
    @ast.Chord(duration~, ..) => duration
    @ast.Tuplet(_) => None
  }
  match m {
    Some(n) => per * n.to_double()
    None => per
  }
}

///|
fn pitch_to_midi(pitch : @ast.Pitch) -> Int {
  match pitch {
    @ast.Interval(lit) => 60 + lit.semitones()
    @ast.ScaleIndex(n) => 60 + scale_degree(n)
    @ast.ScaleIndexMod(n, _) => 60 + scale_degree(n)
    @ast.MicrotonalInterval(lit, _) => 60 + lit.semitones()
    @ast.ScaleIndexCents(n, _) => 60 + scale_degree(n)
    @ast.Root => 60
    @ast.Microtone(_) => 60
  }
}

///|
fn scale_degree(n : Int) -> Int {
  match n {
    1 => 0
    2 => 2
    3 => 4
    4 => 5
    5 => 7
    6 => 9
    7 => 11
    _ => 0
  }
}

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
    out = out +
      "{\"pitch\":" +
      n.pitch().to_string() +
      ",\"start\":" +
      n.start().to_string() +
      ",\"duration\":" +
      n.duration().to_string() +
      ",\"velocity\":100}"
  }
  out + "]"
}
