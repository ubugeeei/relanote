///|
/// `SourceId` is an opaque handle into a `SourceDb`. The dummy value is used
/// for spans that are not attached to any concrete source file (e.g. spans
/// synthesised by tests or by the formatter).
pub struct SourceId {
  raw : UInt
} derive(Eq, Hash)

///|
pub fn SourceId::new(raw : UInt) -> SourceId {
  { raw, }
}

///|
pub fn SourceId::dummy() -> SourceId {
  { raw: 0xFFFFFFFF, }
}

///|
pub fn SourceId::is_dummy(self : SourceId) -> Bool {
  self.raw == 0xFFFFFFFF
}

///|
pub fn SourceId::index(self : SourceId) -> Int {
  self.raw.reinterpret_as_int()
}

///|
/// A location in source code (1-based line and column).
pub struct Location {
  line : Int
  column : Int
} derive(Eq, Hash)

///|
pub fn Location::new(line : Int, column : Int) -> Location {
  { line, column }
}

///|
/// A span in source code as a half-open `[start, end)` byte range together
/// with the source it points into.
pub struct Span {
  source : SourceId
  start : Int
  end : Int
} derive(Eq, Hash)

///|
pub fn Span::new(source : SourceId, start : Int, end : Int) -> Span {
  { source, start, end }
}

///|
pub fn Span::dummy() -> Span {
  { source: SourceId::dummy(), start: 0, end: 0 }
}

///|
pub fn Span::source(self : Span) -> SourceId {
  self.source
}

///|
pub fn Span::start(self : Span) -> Int {
  self.start
}

///|
pub fn Span::end(self : Span) -> Int {
  self.end
}

///|
pub fn Span::len(self : Span) -> Int {
  self.end - self.start
}

///|
pub fn Span::is_empty(self : Span) -> Bool {
  self.start == self.end
}

///|
/// Return the span that covers both `self` and `other`. They must originate
/// from the same source.
pub fn Span::merge(self : Span, other : Span) -> Span {
  let start = if self.start < other.start { self.start } else { other.start }
  let end = if self.end > other.end { self.end } else { other.end }
  { source: self.source, start, end }
}

///|
/// A value `node` paired with its `Span`. Mirrors `relanote_core::Spanned<T>`
/// in the Rust crate.
pub struct Spanned[T] {
  node : T
  span : Span
}

///|
pub fn[T] Spanned::new(node : T, span : Span) -> Spanned[T] {
  { node, span }
}

///|
pub fn[T] Spanned::dummy(node : T) -> Spanned[T] {
  { node, span: Span::dummy() }
}

///|
pub fn[T] Spanned::node(self : Spanned[T]) -> T {
  self.node
}

///|
pub fn[T] Spanned::span(self : Spanned[T]) -> Span {
  self.span
}

///|
/// Interned identifier text. The Rust crate keeps a global intern table
/// for fast equality; until the MoonBit port gains a real interner this is
/// just a `String` alias, so future code that wants to swap in an opaque
/// handle only needs to update this one definition.
pub type InternedStr = String
