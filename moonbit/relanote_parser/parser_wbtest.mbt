// Smoke tests for the parser skeleton. The real descent is tracked in
// #4 — these just confirm the public surface compiles and behaves as
// "always returns an empty program with the placeholder diagnostic".

test "parse_string returns an empty program with one error diagnostic" {
  let (prog, diags) = parse_string("test", "let x = 1")
  assert_eq(prog.items().length(), 0)
  assert_true(diags.has_errors())
  assert_eq(diags.error_count(), 1)
}

test "ParseError::unexpected_token populates the variant fields" {
  let span = @core.Span::dummy()
  let err = ParseError::unexpected_token("identifier", @lexer.Eof, span)
  match err {
    UnexpectedToken(expected~, ..) => assert_eq(expected, "identifier")
    _ => abort("expected UnexpectedToken variant")
  }
  assert_true(err.span() == span)
}

test "ParseError::custom wraps an arbitrary message" {
  let span = @core.Span::dummy()
  let err = ParseError::custom("nope", span)
  match err {
    Custom(message~, ..) => assert_eq(message, "nope")
    _ => abort("expected Custom variant")
  }
}
