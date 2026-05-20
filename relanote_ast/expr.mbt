///|
/// An identifier with its node id for downstream analyses.
///
/// `name` is stored as `InternedStr` so it can be swapped for a real
/// intern handle later without touching call sites.
pub struct Ident {
  name : @core.InternedStr
  id : NodeId
} derive(Eq)

///|
pub fn Ident::new(name : @core.InternedStr) -> Ident {
  { name, id: NodeId::dummy() }
}

///|
pub fn Ident::with_id(name : @core.InternedStr, id : NodeId) -> Ident {
  { name, id }
}

///|
pub fn Ident::name(self : Ident) -> @core.InternedStr {
  self.name
}

///|
pub fn Ident::id(self : Ident) -> NodeId {
  self.id
}

///|
/// Expression AST node — mirrors `relanote_ast::expr::Expr`. Variants are
/// suffixed with `Lit` only where the unsuffixed name would shadow a
/// builtin type or trait (`String`, `Bool`, `Unit`).
pub(all) enum Expr {
  // -- Literals --
  Integer(Int64)
  Float(Double)
  StringLit(String)
  BoolLit(Bool)
  UnitLit

  // -- Identifiers --
  Ident(Ident)

  // -- Music primitives --
  Interval(IntervalLit)
  AbsolutePitch(AbsolutePitchLit)
  Root
  Articulation(Articulation)
  Block(Block)
  Tuplet(Tuplet)
  Envelope(EnvelopeLit)

  // -- Higher-level music structures --
  Part(PartExpr)
  Section(SectionExpr)
  Layer(LayerExpr)

  // -- Functions --
  Lambda(Lambda)
  Application(Application)
  Pipe(Pipe)

  // -- Collections --
  Array(Array[@core.Spanned[Expr]])
  Tuple(Array[@core.Spanned[Expr]])

  // -- Operators --
  Binary(Binary)
  Unary(Unary)
  Index(Index)
  Field(Field)

  // -- Control flow --
  If(IfExpr)
  Match(MatchExpr)
  Let(LetExpr)

  // -- Special --
  With(WithExpr)
  InScale(InScaleExpr)
  Annotated(@core.Spanned[Expr], TypeAnnotation)
  Paren(@core.Spanned[Expr])
  /// Polyrhythm — `a over b`. Both sides play simultaneously with
  /// independent periods; the resulting figure repeats every lcm
  /// of their slot counts.
  Over(@core.Spanned[Expr], @core.Spanned[Expr])

  // Error node, for parser recovery.
  Error
}

///|
/// `true` if `self` is a side-effect-free value that can be duplicated
/// safely by the evaluator/optimiser.
pub fn Expr::is_simple(self : Expr) -> Bool {
  match self {
    Integer(_)
    | Float(_)
    | StringLit(_)
    | BoolLit(_)
    | UnitLit
    | Ident(_)
    | Root => true
    _ => false
  }
}

///|
/// `true` if this is the error-recovery node.
pub fn Expr::is_error(self : Expr) -> Bool {
  match self {
    Error => true
    _ => false
  }
}

// ============================================================
// Sub-structs
// ============================================================

///|
pub struct Lambda {
  params : Array[@core.Spanned[Pattern]]
  body : @core.Spanned[Expr]
}

///|
pub fn Lambda::new(
  params : Array[@core.Spanned[Pattern]],
  body : @core.Spanned[Expr],
) -> Lambda {
  { params, body }
}

///|
pub fn Lambda::params(self : Lambda) -> Array[@core.Spanned[Pattern]] {
  self.params
}

///|
pub fn Lambda::body(self : Lambda) -> @core.Spanned[Expr] {
  self.body
}

///|
pub struct Application {
  func : @core.Spanned[Expr]
  args : Array[@core.Spanned[Expr]]
}

///|
pub fn Application::new(
  func : @core.Spanned[Expr],
  args : Array[@core.Spanned[Expr]],
) -> Application {
  { func, args }
}

///|
pub fn Application::func(self : Application) -> @core.Spanned[Expr] {
  self.func
}

///|
pub fn Application::args(self : Application) -> Array[@core.Spanned[Expr]] {
  self.args
}

///|
pub struct Pipe {
  left : @core.Spanned[Expr]
  right : @core.Spanned[Expr]
}

///|
pub fn Pipe::new(
  left : @core.Spanned[Expr],
  right : @core.Spanned[Expr],
) -> Pipe {
  { left, right }
}

///|
pub fn Pipe::left(self : Pipe) -> @core.Spanned[Expr] {
  self.left
}

///|
pub fn Pipe::right(self : Pipe) -> @core.Spanned[Expr] {
  self.right
}

///|
pub struct Binary {
  op : BinaryOp
  left : @core.Spanned[Expr]
  right : @core.Spanned[Expr]
}

///|
pub fn Binary::new(
  op : BinaryOp,
  left : @core.Spanned[Expr],
  right : @core.Spanned[Expr],
) -> Binary {
  { op, left, right }
}

///|
pub fn Binary::op(self : Binary) -> BinaryOp {
  self.op
}

///|
pub fn Binary::left(self : Binary) -> @core.Spanned[Expr] {
  self.left
}

///|
pub fn Binary::right(self : Binary) -> @core.Spanned[Expr] {
  self.right
}

///|
/// Binary operators. The legacy variants `Eq`/`Ne` are renamed to
/// `EqOp`/`NeOp` to avoid shadowing the `Eq` trait.
