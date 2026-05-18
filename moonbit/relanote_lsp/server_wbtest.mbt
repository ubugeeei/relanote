test "diagnose feeds the parser and reports its diagnostics" {
  let s = RelanoteLanguageServer::new()
  let diags = s.diagnose("file.rela", "let x = 1")
  // Parser is a skeleton — it always reports one placeholder error.
  assert_true(diags.has_errors())
  assert_eq(diags.error_count(), 1)
}

test "format returns the empty string today" {
  let s = RelanoteLanguageServer::new()
  let out = s.format("file.rela", "let x = 1")
  assert_eq(out, "")
}

test "run_server is a no-op for now" {
  // Just confirm it can be invoked without crashing.
  run_server()
}
