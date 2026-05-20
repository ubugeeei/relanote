///|
/// Patterns for `match` and bindings. Mirrors `relanote_ast::pattern::Pattern`.
pub(all) enum Pattern {
  /// `_`.
  Wildcard
  /// Variable binding — `x`.
  Ident(Ident)
  /// Literal — `42`, `"hi"`, `true`, `()`.
  Literal(LiteralPattern)
  /// Tuple — `(a, b, c)`.
  Tuple(Array[@core.Spanned[Pattern]])
  /// Array — `[a, b, ...rest]`.
  Array(ArrayPattern)
  /// Constructor — `Some(x)`, `Interval(quality, degree)`.
  Constructor(name~ : Ident, args~ : Array[@core.Spanned[Pattern]])
  /// Or — `p1 | p2`.
  Or(@core.Spanned[Pattern], @core.Spanned[Pattern])
  /// Annotated — `p : Type`.
  Annotated(@core.Spanned[Pattern], TypeAnnotation)
}

///|
/// Literal patterns. Variants are suffixed with `Lit` where the unsuffixed
/// name would clash with a builtin type (`Bool`, `String`, `Unit`); the
/// non-clashing `Integer` and `Float` keep the legacy naming.
pub(all) enum LiteralPattern {
  Integer(Int64)
  Float(Double)
  StringLit(String)
  BoolLit(Bool)
  UnitLit
}

///|
/// Array pattern with an optional `...rest` tail.
pub struct ArrayPattern {
  elements : Array[@core.Spanned[Pattern]]
  rest : @core.Spanned[Pattern]?
}

///|
pub fn ArrayPattern::new(
  elements : Array[@core.Spanned[Pattern]],
  rest : @core.Spanned[Pattern]?,
) -> ArrayPattern {
  { elements, rest }
}

///|
pub fn ArrayPattern::elements(
  self : ArrayPattern,
) -> Array[@core.Spanned[Pattern]] {
  self.elements
}

///|
pub fn ArrayPattern::rest(self : ArrayPattern) -> @core.Spanned[Pattern]? {
  self.rest
}

///|
/// `true` if `self` always matches — useful for the resolver to know when a
/// `let` binding can be desugared without a fallible match.
pub fn Pattern::is_irrefutable(self : Pattern) -> Bool {
  match self {
    Wildcard => true
    Ident(_) => true
    Tuple(patterns) => {
      for p in patterns {
        if !p.node().is_irrefutable() {
          return false
        }
      }
      true
    }
    Annotated(p, _) => p.node().is_irrefutable()
    _ => false
  }
}
