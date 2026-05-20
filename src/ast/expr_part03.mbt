///|
pub fn WithExpr::modifications(self : WithExpr) -> Array[@core.Spanned[Expr]] {
  self.modifications
}

///|
pub struct InScaleExpr {
  scale : @core.Spanned[Expr]
}

///|
pub fn InScaleExpr::new(scale : @core.Spanned[Expr]) -> InScaleExpr {
  { scale, }
}

///|
pub fn InScaleExpr::scale(self : InScaleExpr) -> @core.Spanned[Expr] {
  self.scale
}
