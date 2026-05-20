///|
/// Configuration options for the formatter. Mirrors
/// `relanote_format::config::FormatConfig` one-to-one.
pub struct FormatConfig {
  indent_size : Int
  max_line_width : Int
  trailing_commas : Bool
  block_multiline : Bool
}

///|
/// Default config: 4-space indent, 80-column wrap, trailing commas,
/// inline blocks — matches the legacy implementation `Default` impl.
pub fn FormatConfig::default() -> FormatConfig {
  {
    indent_size: 4,
    max_line_width: 80,
    trailing_commas: true,
    block_multiline: false,
  }
}

///|
pub fn FormatConfig::indent_size(self : FormatConfig) -> Int {
  self.indent_size
}

///|
pub fn FormatConfig::max_line_width(self : FormatConfig) -> Int {
  self.max_line_width
}

///|
pub fn FormatConfig::trailing_commas(self : FormatConfig) -> Bool {
  self.trailing_commas
}

///|
pub fn FormatConfig::block_multiline(self : FormatConfig) -> Bool {
  self.block_multiline
}
