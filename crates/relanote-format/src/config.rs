//! Formatter configuration

/// Configuration options for the formatter
#[derive(Clone, Debug)]
pub struct FormatConfig {
    /// Number of spaces per indentation level
    pub indent_size: usize,
    /// Maximum line width before wrapping
    pub max_line_width: usize,
    /// Whether to use trailing commas
    pub trailing_commas: bool,
    /// Whether to put block contents on separate lines
    pub block_multiline: bool,
}

impl Default for FormatConfig {
    fn default() -> Self {
        Self {
            indent_size: 4,
            max_line_width: 80,
            trailing_commas: true,
            block_multiline: false,
        }
    }
}
