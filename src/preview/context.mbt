///|
pub struct PreviewContext {
  root_midi : Int
  tempo : Int
}

///|
pub fn PreviewContext::default() -> PreviewContext {
  { root_midi: 60, tempo: 0 }
}

///|
pub fn PreviewContext::root_midi(self : PreviewContext) -> Int {
  self.root_midi
}

///|
pub fn PreviewContext::tempo(self : PreviewContext) -> Int {
  self.tempo
}

///|
pub struct PreviewProgram {
  value : @eval.Value
  context : PreviewContext
}

///|
pub fn PreviewProgram::value(self : PreviewProgram) -> @eval.Value {
  self.value
}

///|
pub fn PreviewProgram::context(self : PreviewProgram) -> PreviewContext {
  self.context
}

///|
fn eval_preview(source : String) -> Result[PreviewProgram, String] {
  let src = @core.Source::from_string("<preview>", source)
  let (program, parse_diags) = @parser.parse_source(src)
  if parse_diags.has_errors() {
    return Err("parse error")
  }
  let checker = @types.TypeChecker::new()
  if checker.check_program(program).length() > 0 {
    return Err("type error")
  }
  let evaluator = @eval.Evaluator::new()
  match evaluator.eval_program(program) {
    Ok(value) => Ok({ value, context: context_from_env(evaluator.env()) })
    Err(err) => Err(err.message())
  }
}

///|
fn context_from_env(env : @eval.Env) -> PreviewContext {
  {
    root_midi: key_from_env(env),
    tempo: tempo_from_env(env),
  }
}

///|
fn key_from_env(env : @eval.Env) -> Int {
  match env.lookup("key") {
    Some(@eval.AbsolutePitchV(midi)) => clamp_midi(midi)
    Some(@eval.IntervalV(offset)) => clamp_midi(60 + offset)
    Some(@eval.RootV) => 60
    _ => 60
  }
}

///|
fn tempo_from_env(env : @eval.Env) -> Int {
  let bpm = match env.lookup("tempo") {
    Some(@eval.IntV(n)) => n.to_int()
    Some(@eval.FloatV(f)) => f.to_int()
    _ => 0
  }
  if bpm > 0 { bpm } else { 0 }
}

///|
fn clamp_midi(pitch : Int) -> Int {
  if pitch < 0 {
    0
  } else if pitch > 127 {
    127
  } else {
    pitch
  }
}

///|
pub fn preview_tempo(source : String) -> Int {
  match eval_preview(source) {
    Ok(result) => result.context().tempo()
    Err(_) => 0
  }
}
