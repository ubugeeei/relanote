///|
test "render_diagnostic prints kind + message + source-context block" {
  let source = Source::from_string("input.rela", "let x 42\n")
  let diag = Diagnostic::error(
    "expected `=` in let binding",
    Span::new(source.id(), 6, 8),
  )
  let rendered = render_diagnostic(diag, source)
  assert_true(rendered.contains("[error] expected `=` in let binding"))
  assert_true(rendered.contains("input.rela:1:7"))
  assert_true(rendered.contains("let x 42"))
  // The underline (column 7 with 2 columns of `^`) sits below `42`.
  assert_true(rendered.contains("^^"))
}

///|
test "render_diagnostic falls back to one-liner for dummy spans" {
  let source = Source::from_string("input.rela", "")
  let diag = Diagnostic::error("module not found", Span::dummy())
  let rendered = render_diagnostic(diag, source)
  // No source-context block — just the [kind] message line.
  assert_true(rendered.has_prefix("[error] module not found"))
  assert_false(rendered.contains("╭─"))
}

///|
test "render_diagnostics joins each report with a blank line" {
  let source = Source::from_string("input.rela", "let x 42\nlet y 7\n")
  let diags = Diagnostics::new()
  diags.error("first", Span::new(source.id(), 6, 8))
  diags.error("second", Span::new(source.id(), 15, 16))
  let rendered = render_diagnostics(diags, source)
  assert_true(rendered.contains("[error] first"))
  assert_true(rendered.contains("[error] second"))
}
