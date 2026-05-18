///|
/// Errors produced by the type checker. Mirrors `TypeError` in the Rust
/// crate; field names are kept identical so future ports of the inference
/// engine can match patterns verbatim.
pub(all) enum TypeError {
  Mismatch(expected~ : Type, found~ : Type, span~ : @core.Span)
  UnificationError(Type, Type, @core.Span)
  UndefinedVariable(name~ : String, span~ : @core.Span)
  UndefinedType(name~ : String, span~ : @core.Span)
  OccursCheck(span~ : @core.Span)
  NotAFunction(Type, @core.Span)
  NotAScale(found~ : Type, span~ : @core.Span)
  InvalidScaleIndex(index~ : Int, span~ : @core.Span)
  TimeAlignmentMismatch(
    expected_duration~ : String,
    found_duration~ : String,
    part_index~ : Int,
    span~ : @core.Span,
  )
}

///|
/// Source span for this error, regardless of variant.
pub fn TypeError::span(self : TypeError) -> @core.Span {
  match self {
    Mismatch(span~, ..) => span
    UnificationError(_, _, sp) => sp
    UndefinedVariable(span~, ..) => span
    UndefinedType(span~, ..) => span
    OccursCheck(span~) => span
    NotAFunction(_, sp) => sp
    NotAScale(span~, ..) => span
    InvalidScaleIndex(span~, ..) => span
    TimeAlignmentMismatch(span~, ..) => span
  }
}

///|
/// Human-readable summary, matching the format strings on the Rust
/// `#[derive(Error)]` attributes one-to-one.
pub fn TypeError::message(self : TypeError) -> String {
  match self {
    Mismatch(expected~, found~, ..) =>
      "type mismatch: expected " +
      expected.to_display_string() +
      ", found " +
      found.to_display_string()
    UnificationError(a, b, _) =>
      "cannot unify types: " +
      a.to_display_string() +
      " and " +
      b.to_display_string()
    UndefinedVariable(name~, ..) => "undefined variable: " + name
    UndefinedType(name~, ..) => "undefined type: " + name
    OccursCheck(_) => "occurs check failed: infinite type"
    NotAFunction(t, _) => "not a function type: " + t.to_display_string()
    NotAScale(found~, ..) =>
      "not a scale type (found " + found.to_display_string() + ")"
    InvalidScaleIndex(index~, ..) =>
      "invalid scale index: " + index.to_string()
    TimeAlignmentMismatch(_) => "time alignment mismatch in layer"
  }
}
