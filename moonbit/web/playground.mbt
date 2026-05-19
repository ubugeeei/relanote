///|
/// Vapor Moon web playground bridge.
///
/// The bridge exposes the four pipeline phases the playground UI
/// drives — diagnose, format, run, render — as JS-callable functions
/// operating on plain strings / byte arrays. The Vapor Moon component
/// layer talks to these through generated JS interop, so a Vue
/// component's "play" handler is a single call here.
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
/// Format a source string. The "format on save" / "format selection"
/// commands will call this.
pub fn format(source : String) -> String {
  let (program, _) = @parser.parse_string("<playground>", source)
  @format.format(program, @format.FormatConfig::default())
}

///|
/// Evaluate a source string and return the rendered MIDI bytes. The
/// "play" button calls this and hands the bytes to the browser's
/// AudioContext (via JS interop).
///
/// Returns an empty array when parsing, type-checking, or evaluation
/// fails — the UI surfaces the human-readable error through
/// `diagnose`. The empty array is unambiguous because a valid SMF
/// file is always at least 22 bytes (14-byte header + 8-byte MTrk).
pub fn render(source : String) -> Array[Byte] {
  let src = @core.Source::from_string("<playground>", source)
  let (program, parse_diags) = @parser.parse_source(src)
  if parse_diags.has_errors() {
    return []
  }
  let checker = @types.TypeChecker::new()
  let type_errors = checker.check_program(program)
  if type_errors.length() > 0 {
    return []
  }
  let evaluator = @eval.Evaluator::new()
  match evaluator.eval_program(program) {
    Ok(value) => @render.render_to_midi(value)
    Err(_) => []
  }
}

///|
/// Evaluate a source string and return the final value's display
/// string, mirroring what the CLI's `run` subcommand prints.
pub fn run(source : String) -> String {
  let (program, parse_diags) = @parser.parse_string("<playground>", source)
  if parse_diags.has_errors() {
    return "parse error"
  }
  let checker = @types.TypeChecker::new()
  if checker.check_program(program).length() > 0 {
    return "type error"
  }
  let evaluator = @eval.Evaluator::new()
  match evaluator.eval_program(program) {
    Ok(@eval.IntV(n)) => n.to_string()
    Ok(@eval.FloatV(f)) => f.to_string()
    Ok(@eval.BoolV(b)) => b.to_string()
    Ok(@eval.StringV(s)) => s
    Ok(@eval.UnitV) => "()"
    Ok(@eval.IntervalV(n)) => "interval(" + n.to_string() + ")"
    Ok(@eval.AbsolutePitchV(n)) => "absolute_pitch(" + n.to_string() + ")"
    Ok(@eval.RootV) => "<R>"
    Ok(_) => "<value>"
    Err(err) => "runtime error: " + err.message()
  }
}
