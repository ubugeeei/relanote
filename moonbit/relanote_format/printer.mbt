///|
/// Formatter — walks a `Program` and produces formatted source. The Rust
/// crate's printer is ~450 lines of AST traversal; the MoonBit port keeps
/// the public surface stable and emits an empty string until the walker
/// is ported.
///
/// Tracked in #10.
pub struct Formatter {
  config : FormatConfig
  output : StringBuilder
  mut indent_level : Int
}

///|
pub fn Formatter::new(config : FormatConfig) -> Formatter {
  { config, output: StringBuilder::new(), indent_level: 0 }
}

///|
pub fn Formatter::config(self : Formatter) -> FormatConfig {
  self.config
}

///|
pub fn Formatter::format_program(
  self : Formatter,
  program : @ast.Program,
) -> String {
  let _ = program
  let _ = self
  ""
}

///|
/// Top-level convenience — `format(program, &config) -> String` in the
/// Rust crate.
pub fn format(program : @ast.Program, config : FormatConfig) -> String {
  Formatter::new(config).format_program(program)
}
