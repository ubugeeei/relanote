test "diagnose feeds the parser and reports its diagnostics" {
  let s = RelanoteLanguageServer::new()
  // Clean source produces no diagnostics now that the parser is real.
  let clean = s.diagnose("file.rela", "let x = 1")
  assert_false(clean.has_errors())
  assert_eq(clean.error_count(), 0)
  // Malformed source is surfaced as diagnostics on the same channel.
  let broken = s.diagnose("file.rela", "let x 1")
  assert_true(broken.has_errors())
}

test "format runs the printer on the parsed program" {
  let s = RelanoteLanguageServer::new()
  let out = s.format("file.rela", "let x = 1")
  assert_eq(out, "let x = 1\n")
}

test "run_server is a no-op for now" {
  // Just confirm it can be invoked without crashing.
  run_server()
}
