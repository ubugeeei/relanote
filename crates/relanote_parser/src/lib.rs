//! Parser for relanote language

mod error;
mod expr;
mod item;
mod music;
mod parser;

pub use error::{ParseError, ParseResult};
pub use parser::{parse, parse_expr, Parser};

use relanote_ast::Program;
use relanote_core::{Diagnostics, Source, SourceDb};

/// Parse a source file and return the AST with diagnostics
pub fn parse_source(source: &Source) -> (Program, Diagnostics) {
    let parser = Parser::new(source);
    parser.parse_program()
}

/// Parse a source file from the database
pub fn parse_file(
    db: &SourceDb,
    source_id: relanote_core::SourceId,
) -> Option<(Program, Diagnostics)> {
    db.get(source_id).map(parse_source)
}

/// Parse source code from a string
pub fn parse_string(name: &str, content: &str) -> (Program, Diagnostics) {
    let source = Source::from_string(name, content.to_string());
    parse_source(&source)
}
