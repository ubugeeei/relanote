///|
/// Vapor Moon web playground — skeleton.
///
/// The real Vapor Moon playground will replace `web/` (Nuxt + Vue) and
/// drive the same end-user features through the MoonBit pipeline:
///
///   * Monaco editor with relanote syntax highlighting
///   * Real-time error reporting against `relanote_parser`
///   * Staff-notation preview
///   * Audio playback via the browser's AudioContext
///   * MIDI export via `relanote_render`
///
/// The Vapor Moon component layer needs the lexer / parser / type /
/// evaluator pipeline to be real before the playground can drive its
/// `run` button end-to-end. Until then this skeleton exposes the JS-
/// callable bridge functions Vapor Moon components will need so the
/// component code can be sketched against a stable API.
///
/// Tracked in #14.

///|
/// Parse a source string and return the human-readable diagnostic
/// stream. The Vapor Moon "errors panel" component will subscribe to
/// this.
pub fn diagnose(source : String) -> Array[String] {
  let (_, diags) = @parser.parse_string("<playground>", source)
  let out : Array[String] = []
  for d in diags.items() {
    out.push("[" + d.kind().to_display_string() + "] " + d.message())
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
/// "play" button will call this and hand the bytes to the browser's
/// AudioContext (via JS interop).
pub fn render(source : String) -> Array[Byte] {
  let (program, _) = @parser.parse_string("<playground>", source)
  let evaluator = @eval.Evaluator::new()
  match evaluator.eval_program(program) {
    Ok(value) => @render.render_to_midi(value)
    Err(_) => []
  }
}
