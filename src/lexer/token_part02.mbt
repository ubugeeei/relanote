///|
pub fn TokenKind::is_keyword(self : TokenKind) -> Bool {
  match self {
    Let
    | Set
    | In
    | If
    | Then
    | Else
    | Match
    | With
    | Scale
    | Chord
    | Section
    | Layer
    | Part
    | Synth
    | Osc
    | Filter
    | Env
    | Import
    | Export
    | From
    | As
    | Mod
    | Use
    | True
    | False => true
    _ => false
  }
}

///|
/// `true` if `self` is an operator token.
pub fn TokenKind::is_operator(self : TokenKind) -> Bool {
  match self {
    PipeOp
    | Compose
    | Arrow
    | Lambda
    | Equals
    | EqEq
    | NotEq
    | LtEq
    | GtEq
    | AndAnd
    | OrOr
    | Bang
    | ColonColon
    | Colon
    | Comma
    | Dot
    | Minus
    | PlusPlus
    | Plus
    | Star
    | Slash
    | Percent => true
    _ => false
  }
}

///|
/// `true` if `self` is an articulation marker.
pub fn TokenKind::is_articulation(self : TokenKind) -> Bool {
  match self {
    Staccato | Accent | Portamento => true
    _ => false
  }
}

///|
/// A token with its span in the source.
pub struct Token {
  kind : TokenKind
  span : @core.Span
} derive(Eq)

///|
pub fn Token::new(kind : TokenKind, span : @core.Span) -> Token {
  { kind, span }
}

///|
pub fn Token::eof(span : @core.Span) -> Token {
  { kind: Eof, span }
}

///|
pub fn Token::kind(self : Token) -> TokenKind {
  self.kind
}

///|
pub fn Token::span(self : Token) -> @core.Span {
  self.span
}
