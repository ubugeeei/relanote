///|
pub(all) enum BinaryOp {
  // Arithmetic
  Add
  Sub
  Mul
  Div
  Mod
  // Comparison
  EqOp
  NeOp
  Lt
  Le
  Gt
  Ge
  // Logical
  And
  Or
  // Music-specific
  Concat
  Compose
} derive(Eq)

///|
pub struct Unary {
  op : UnaryOp
  operand : @core.Spanned[Expr]
}

///|
pub fn Unary::new(op : UnaryOp, operand : @core.Spanned[Expr]) -> Unary {
  { op, operand }
}

///|
pub fn Unary::op(self : Unary) -> UnaryOp {
  self.op
}

///|
pub fn Unary::operand(self : Unary) -> @core.Spanned[Expr] {
  self.operand
}

///|
pub(all) enum UnaryOp {
  Neg
  Not
} derive(Eq)

///|
pub struct Index {
  base : @core.Spanned[Expr]
  index : @core.Spanned[Expr]
}

///|
pub fn Index::new(
  base : @core.Spanned[Expr],
  index : @core.Spanned[Expr],
) -> Index {
  { base, index }
}

///|
pub fn Index::base(self : Index) -> @core.Spanned[Expr] {
  self.base
}

///|
pub fn Index::index(self : Index) -> @core.Spanned[Expr] {
  self.index
}

///|
pub struct Field {
  base : @core.Spanned[Expr]
  field : Ident
}

///|
pub fn Field::new(base : @core.Spanned[Expr], field : Ident) -> Field {
  { base, field }
}

///|
pub fn Field::base(self : Field) -> @core.Spanned[Expr] {
  self.base
}

///|
pub fn Field::field(self : Field) -> Ident {
  self.field
}

///|
pub struct IfExpr {
  condition : @core.Spanned[Expr]
  then_branch : @core.Spanned[Expr]
  else_branch : @core.Spanned[Expr]?
}

///|
pub fn IfExpr::new(
  condition : @core.Spanned[Expr],
  then_branch : @core.Spanned[Expr],
  else_branch : @core.Spanned[Expr]?,
) -> IfExpr {
  { condition, then_branch, else_branch }
}

///|
pub fn IfExpr::condition(self : IfExpr) -> @core.Spanned[Expr] {
  self.condition
}

///|
pub fn IfExpr::then_branch(self : IfExpr) -> @core.Spanned[Expr] {
  self.then_branch
}

///|
pub fn IfExpr::else_branch(self : IfExpr) -> @core.Spanned[Expr]? {
  self.else_branch
}

///|
pub struct MatchExpr {
  scrutinee : @core.Spanned[Expr]
  arms : Array[MatchArm]
}

///|
pub fn MatchExpr::new(
  scrutinee : @core.Spanned[Expr],
  arms : Array[MatchArm],
) -> MatchExpr {
  { scrutinee, arms }
}

///|
pub fn MatchExpr::scrutinee(self : MatchExpr) -> @core.Spanned[Expr] {
  self.scrutinee
}

///|
pub fn MatchExpr::arms(self : MatchExpr) -> Array[MatchArm] {
  self.arms
}

///|
pub struct MatchArm {
  pattern : @core.Spanned[Pattern]
  guard_expr : @core.Spanned[Expr]?
  body : @core.Spanned[Expr]
}

///|
pub fn MatchArm::new(
  pattern : @core.Spanned[Pattern],
  guard_expr : @core.Spanned[Expr]?,
  body : @core.Spanned[Expr],
) -> MatchArm {
  { pattern, guard_expr, body }
}

///|
pub fn MatchArm::pattern(self : MatchArm) -> @core.Spanned[Pattern] {
  self.pattern
}

///|
pub fn MatchArm::guard_expr(self : MatchArm) -> @core.Spanned[Expr]? {
  self.guard_expr
}

///|
pub fn MatchArm::body(self : MatchArm) -> @core.Spanned[Expr] {
  self.body
}

///|
pub struct LetExpr {
  pattern : @core.Spanned[Pattern]
  type_ann : TypeAnnotation?
  value : @core.Spanned[Expr]
  body : @core.Spanned[Expr]
}

///|
pub fn LetExpr::new(
  pattern : @core.Spanned[Pattern],
  type_ann : TypeAnnotation?,
  value : @core.Spanned[Expr],
  body : @core.Spanned[Expr],
) -> LetExpr {
  { pattern, type_ann, value, body }
}

///|
pub fn LetExpr::pattern(self : LetExpr) -> @core.Spanned[Pattern] {
  self.pattern
}

///|
pub fn LetExpr::type_ann(self : LetExpr) -> TypeAnnotation? {
  self.type_ann
}

///|
pub fn LetExpr::value(self : LetExpr) -> @core.Spanned[Expr] {
  self.value
}

///|
pub fn LetExpr::body(self : LetExpr) -> @core.Spanned[Expr] {
  self.body
}

///|
pub struct WithExpr {
  base : @core.Spanned[Expr]
  modifications : Array[@core.Spanned[Expr]]
}

///|
pub fn WithExpr::new(
  base : @core.Spanned[Expr],
  modifications : Array[@core.Spanned[Expr]],
) -> WithExpr {
  { base, modifications }
}

///|
pub fn WithExpr::base(self : WithExpr) -> @core.Spanned[Expr] {
  self.base
}

///|
