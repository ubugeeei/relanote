///|
/// Parser error type. Mirrors `relanote_parser::error::ParseError` in the
/// Rust crate, including the constructor helpers used by recovery code.
pub(all) enum ParseError {
  UnexpectedToken(
    expected~ : String,
    found~ : @lexer.TokenKind,
    span~ : @core.Span,
  )
  UnexpectedEof(span~ : @core.Span)
  InvalidInterval(message~ : String, span~ : @core.Span)
  InvalidScaleIndex(index~ : Int, span~ : @core.Span)
  UnclosedDelimiter(expected~ : Char, span~ : @core.Span)
  InvalidExpression(span~ : @core.Span)
  Custom(message~ : String, span~ : @core.Span)
}

///|
pub fn ParseError::span(self : ParseError) -> @core.Span {
  match self {
    UnexpectedToken(span~, ..) => span
    UnexpectedEof(span~) => span
    InvalidInterval(span~, ..) => span
    InvalidScaleIndex(span~, ..) => span
    UnclosedDelimiter(span~, ..) => span
    InvalidExpression(span~) => span
    Custom(span~, ..) => span
  }
}

///|
pub fn ParseError::unexpected_token(
  expected : String,
  found : @lexer.TokenKind,
  span : @core.Span,
) -> ParseError {
  UnexpectedToken(expected~=expected, found~=found, span~=span)
}

///|
pub fn ParseError::custom(message : String, span : @core.Span) -> ParseError {
  Custom(message~=message, span~=span)
}

///|
/// `Result[T, ParseError]` — mirrors the Rust type alias.
pub type ParseResult[T] = Result[T, ParseError]
