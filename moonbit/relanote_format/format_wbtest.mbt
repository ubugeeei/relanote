test "default config matches Rust crate" {
  let c = FormatConfig::default()
  assert_eq(c.indent_size(), 4)
  assert_eq(c.max_line_width(), 80)
  assert_true(c.trailing_commas())
  assert_false(c.block_multiline())
}

test "format on an empty program is the empty string" {
  let prog = @ast.Program::empty()
  let out = format(prog, FormatConfig::default())
  assert_eq(out, "")
}
