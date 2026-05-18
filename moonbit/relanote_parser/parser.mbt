///|
/// Parser state. The Rust crate keeps a token stream + cursor + diagnostic
/// sink; the MoonBit port keeps the same public surface so call sites can
/// be ported in place. The actual descent is deferred to a follow-up — see
/// the note at the bottom of this file.
pub struct Parser {
  source : @core.Source
  tokens : Array[@lexer.Token]
  mut cursor : Int
  diagnostics : @core.Diagnostics
}

///|
pub fn Parser::new(source : @core.Source) -> Parser {
  let tokens = @lexer.Lexer::new(source).tokenize()
  { source, tokens, cursor: 0, diagnostics: @core.Diagnostics::new() }
}

///|
pub fn Parser::source(self : Parser) -> @core.Source {
  self.source
}

///|
pub fn Parser::tokens(self : Parser) -> Array[@lexer.Token] {
  self.tokens
}

///|
pub fn Parser::diagnostics(self : Parser) -> @core.Diagnostics {
  self.diagnostics
}

///|
/// Run the parser over its captured source. The skeleton always emits a
/// single "parser not yet ported" diagnostic and returns an empty program
/// so downstream callers can be wired up before the real descent arrives.
pub fn Parser::parse_program(
  self : Parser,
) -> (@ast.Program, @core.Diagnostics) {
  self.diagnostics.error(
    "relanote_parser MoonBit port is a placeholder — see #4",
    @core.Span::new(self.source.id(), 0, 0),
  )
  (@ast.Program::empty(), self.diagnostics)
}

///|
/// Parse a source file. Mirrors `relanote_parser::parse_source`.
pub fn parse_source(source : @core.Source) -> (@ast.Program, @core.Diagnostics) {
  Parser::new(source).parse_program()
}

///|
/// Convenience entry mirroring `relanote_parser::parse_string`.
pub fn parse_string(
  name : String,
  content : String,
) -> (@ast.Program, @core.Diagnostics) {
  let source = @core.Source::from_string(name, content)
  parse_source(source)
}

///|
/// Convenience entry mirroring `relanote_parser::parse`.
pub fn parse(source : String) -> (@ast.Program, @core.Diagnostics) {
  parse_string("<input>", source)
}

// The real expression / item / music descent (Rust: `expr.rs`, `item.rs`,
// `music.rs`) is intentionally deferred to a follow-up. MoonBit has no
// `chumsky` equivalent, so this will become hand-rolled recursive descent
// — tracked in #4. The skeleton keeps the public surface stable so
// downstream packages can build against it today.
