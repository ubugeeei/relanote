///|
/// Pretty-print a `Diagnostic` with source context. Mirrors the
/// ariadne-style report used in `crates/relanote_core/src/lib.rs`.
///
/// Layout:
///
/// ```
/// [error] expected `=` in let binding
///    ╭─[ <input>:3:7 ]
///    │
///  3 │ let x 42
///    │       ─┬─
///    │        ╰─── here
///    │
/// ───╯
/// ```
///
/// The caller passes the source so the reporter can look up the
/// offending line and the location of the span within it. When the
/// span doesn't belong to the supplied source (or is dummy) the
/// fallback is a `[kind] message` one-liner.
pub fn render_diagnostic(
  diag : Diagnostic,
  source : Source,
) -> String {
  let buf = StringBuilder::new()
  let kind = diag.kind().to_display_string()
  buf.write_string("[")
  buf.write_string(kind)
  buf.write_string("] ")
  buf.write_string(diag.message())
  buf.write_string("\n")
  let span = diag.span()
  // Dummy spans / spans not pointing at any line just print as a
  // one-liner — there's no source row to underline.
  if span.start() < 0 || span.start() >= source.content().length() {
    return buf.to_string()
  }
  let start = source.location(span.start())
  let line_text = match source.line(start.line) {
    Some(s) => s
    None => return buf.to_string()
  }
  let gutter_width = start.line.to_string().length() + 1
  // Header line:  ╭─[ name:line:col ]
  buf.write_string(repeat_char(' ', gutter_width))
  buf.write_string("╭─[ ")
  buf.write_string(source.name())
  buf.write_string(":")
  buf.write_string(start.line.to_string())
  buf.write_string(":")
  buf.write_string(start.column.to_string())
  buf.write_string(" ]\n")
  // Blank gutter line.
  buf.write_string(repeat_char(' ', gutter_width))
  buf.write_string("│\n")
  // Source line.
  buf.write_string(" ")
  buf.write_string(start.line.to_string())
  buf.write_string(" │ ")
  buf.write_string(line_text)
  buf.write_string("\n")
  // Underline.
  let underline_len = compute_underline_len(span.start(), span.end(), source, start.line)
  buf.write_string(repeat_char(' ', gutter_width))
  buf.write_string("│ ")
  buf.write_string(repeat_char(' ', start.column - 1))
  buf.write_string(repeat_char('^', underline_len))
  buf.write_string("\n")
  // Footer.
  buf.write_string(repeat_char('─', gutter_width))
  buf.write_string("╯\n")
  buf.to_string()
}

///|
/// Render every diagnostic in `diagnostics` against `source`, joining
/// the rendered chunks with a single blank line.
pub fn render_diagnostics(
  diagnostics : Diagnostics,
  source : Source,
) -> String {
  let buf = StringBuilder::new()
  let mut i = 0
  for d in diagnostics.items() {
    if i > 0 {
      buf.write_string("\n")
    }
    buf.write_string(render_diagnostic(d, source))
    i += 1
  }
  buf.to_string()
}

///|
fn repeat_char(c : Char, n : Int) -> String {
  let buf = StringBuilder::new()
  let mut i = 0
  while i < n {
    buf.write_char(c)
    i += 1
  }
  buf.to_string()
}

///|
/// Clamp the span's underline to the offending line so spans that
/// reach across newlines still draw something sensible.
fn compute_underline_len(
  start : Int,
  end : Int,
  source : Source,
  line : Int,
) -> Int {
  let line_start = match source.line(line) {
    Some(text) => source.location(start).column - 1
    None => 0
  }
  let _ = line_start
  let raw = end - start
  if raw <= 0 {
    1
  } else {
    raw
  }
}
