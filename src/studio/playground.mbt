///|
/// Vapor Moon studio playground bridge.
///
/// The bridge exposes the four pipeline phases the playground UI
/// drives — diagnose, format, run, render — as JS-callable functions
/// operating on plain strings and byte arrays. The Vapor Moon component
/// layer calls these functions from `App.mbtv`.
///
/// Tracked in #14.

///|
/// Parse + type-check a source string and return the human-readable
/// diagnostic stream. The Vapor Moon "errors panel" subscribes to
/// this; each entry is the ariadne-style report from
/// `@core.render_diagnostic`.
pub fn diagnose(source : String) -> Array[String] {
  let src = @core.Source::from_string("<playground>", source)
  let (program, parse_diags) = @parser.parse_source(src)
  let out : Array[String] = []
  for d in parse_diags.items() {
    out.push(@core.render_diagnostic(d, src))
  }
  if parse_diags.has_errors() {
    return out
  }
  let checker = @types.TypeChecker::new()
  for err in checker.check_program(program) {
    let d = @core.Diagnostic::error(err.message(), err.span())
    out.push(@core.render_diagnostic(d, src))
  }
  out
}

///|
pub fn default_source() -> String {
  (
    #|set tempo = 120
    #|
    #|scale Major = { R, M2, M3, P4, P5, M6, M7 }
    #|
    #|let theme = | <1> <3> <5> <3> <1> - <5> - |:4
    #|let answer = | <6> <5> <3> <2> <1> - - - |:4
    #|
    #|theme ++ answer
  )
}

///|
fn eval_source(source : String) -> Result[@eval.Value, String] {
  let src = @core.Source::from_string("<playground>", source)
  let (program, parse_diags) = @parser.parse_source(src)
  if parse_diags.has_errors() {
    return Err("parse error")
  }
  let checker = @types.TypeChecker::new()
  let type_errors = checker.check_program(program)
  if type_errors.length() > 0 {
    return Err("type error")
  }
  let evaluator = @eval.Evaluator::new()
  evaluator.eval_program(program).map_err(fn(e) { e.message() })
}

///|
/// Format a source string. The "format on save" / "format selection"
/// commands will call this.
pub fn format(source : String) -> String {
  let (program, _) = @parser.parse_string("<playground>", source)
  @format.format(program, @format.FormatConfig::default())
}

///|
/// Evaluate a source string and return the rendered MIDI bytes.
pub fn render(source : String) -> Array[Byte] {
  match eval_source(source) {
    Ok(value) => @render.render_to_midi(value)
    Err(_) => []
  }
}

///|
/// Evaluate a source string and return the final value's display
/// string, mirroring what the CLI's `run` subcommand prints.
pub fn run(source : String) -> String {
  match eval_source(source) {
    Ok(@eval.IntV(n)) => n.to_string()
    Ok(@eval.FloatV(f)) => f.to_string()
    Ok(@eval.BoolV(b)) => b.to_string()
    Ok(@eval.StringV(s)) => s
    Ok(@eval.UnitV) => "()"
    Ok(@eval.IntervalV(n)) => "interval(" + n.to_string() + ")"
    Ok(@eval.AbsolutePitchV(n)) => "absolute_pitch(" + n.to_string() + ")"
    Ok(@eval.RootV) => "<R>"
    Ok(_) => "<value>"
    Err(err) => err
  }
}

///|
pub fn events_json(source : String) -> String {
  @preview.events_json(source)
}

///|
pub fn playground_summary(source : String) -> String {
  @preview.playground_summary(source)
}

///|
pub fn staff_html(source : String, beat : Double) -> String {
  @preview.staff_html(source, beat)
}

///|
pub fn piano_html(source : String, beat : Double) -> String {
  @preview.piano_html(source, beat)
}
