///|
/// Unique identifier for AST nodes (used for HIR mapping and analyses).
pub struct NodeId {
  raw : UInt
} derive(Eq, Hash)

///|
pub fn NodeId::new(raw : UInt) -> NodeId {
  { raw, }
}

///|
pub fn NodeId::dummy() -> NodeId {
  { raw: 0xFFFFFFFF, }
}

///|
pub fn NodeId::is_dummy(self : NodeId) -> Bool {
  self.raw == 0xFFFFFFFF
}

///|
/// A free-floating comment, preserved through parsing so the formatter can
/// keep them.
pub struct Comment {
  text : String
  span : @core.Span
}

///|
pub fn Comment::new(text : String, span : @core.Span) -> Comment {
  { text, span }
}

///|
pub fn Comment::text(self : Comment) -> String {
  self.text
}

///|
pub fn Comment::span(self : Comment) -> @core.Span {
  self.span
}

///|
/// A complete relanote program — the root AST node.
pub struct Program {
  items : Array[@core.Spanned[Item]]
  comments : Array[Comment]
}

///|
pub fn Program::new(items : Array[@core.Spanned[Item]]) -> Program {
  { items, comments: [] }
}

///|
pub fn Program::with_comments(
  items : Array[@core.Spanned[Item]],
  comments : Array[Comment],
) -> Program {
  { items, comments }
}

///|
pub fn Program::empty() -> Program {
  { items: [], comments: [] }
}

///|
pub fn Program::items(self : Program) -> Array[@core.Spanned[Item]] {
  self.items
}

///|
pub fn Program::comments(self : Program) -> Array[Comment] {
  self.comments
}
