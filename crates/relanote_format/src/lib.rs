//! Code formatter for relanote

mod config;
mod printer;

pub use config::FormatConfig;
pub use printer::Formatter;

use relanote_ast::Program;

/// Format a program to a string
pub fn format(program: &Program, config: &FormatConfig) -> String {
    let mut formatter = Formatter::new(config.clone());
    formatter.format_program(program)
}
