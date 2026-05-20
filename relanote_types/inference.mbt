///|
/// Inference engine — walks an AST expression and returns its type, threading
/// unification state through `TypeContext`. Mirrors the implementation in
/// legacy source.

///|
pub fn TypeContext::infer_expr(
  self : TypeContext,
  expr : @core.Spanned[@ast.Expr],
) -> Result[Type, TypeError] {
  match expr.node() {
    // Literals
    Integer(_) => Ok(IntTy)
    Float(_) => Ok(FloatTy)
    StringLit(_) => Ok(StringTy)
    BoolLit(_) => Ok(BoolTy)
    UnitLit => Ok(Unit)

    // Identifiers
    Ident(ident) =>
      match self.lookup(ident.name()) {
        Some(scheme) => Ok(self.instantiate(scheme))
        None => Err(UndefinedVariable(name=ident.name(), span=expr.span()))
      }

    // Music primitives
    Interval(_) => Ok(Interval)
    AbsolutePitch(_) => Ok(Interval)
    Root => Ok(Interval)
    Articulation(_) => Ok(Articulation)
    Block(_) => Ok(Block)
    Tuplet(_) => Ok(Block)
    Envelope(_) => Ok(Envelope)
    Part(_) => Ok(Part)
    Section(_) => Ok(Section)
    Layer(_) => Ok(Section)

    // Lambda / application
    Lambda(lambda) => self.infer_lambda(lambda)
    Application(app) => self.infer_application(app, expr.span())
    Pipe(pipe) => self.infer_pipe(pipe, expr.span())

    // Binary operators
    Binary(binary) => self.infer_binary(binary, expr.span())

    // Compound forms
    Unary(unary) => self.infer_unary(unary, expr.span())
    Array(elements) => self.infer_array(elements)
    Tuple(elements) => self.infer_tuple(elements)
    Index(index) => self.infer_index(index, expr.span())
    If(if_expr) => self.infer_if(if_expr, expr.span())
    Let(let_expr) => self.infer_let(let_expr)

    // With expression — keeps base type
    With(with_expr) =>
      match self.infer_expr(with_expr.base()) {
        Ok(t) => Ok(t)
        Err(e) => Err(e)
      }

    // Field access — simplified to fresh var until record types are real
    Field(_) => Ok(self.fresh_var())

    // Match expression
    Match(match_expr) => self.infer_match(match_expr)

    // Parenthesised or annotated — pass through
    Paren(inner) => self.infer_expr(inner)
    Annotated(inner, _) => self.infer_expr(inner)

    // `in Scale` returns Block -> Block
    InScale(in_scale) =>
      match self.infer_expr(in_scale.scale()) {
        Err(e) => Err(e)
        Ok(_) => Ok(Function(Block, Block))
      }

    // Polyrhythm — `a over b`. Same type as `a`.
    Over(left, _) => self.infer_expr(left)

    // Error recovery
    Error => Ok(ErrorTy)
  }
}

///|
/// Infer a binary expression. Split out to keep the main walker readable.
fn TypeContext::infer_binary(
  self : TypeContext,
  binary : @ast.Binary,
  span : @core.Span,
) -> Result[Type, TypeError] {
  let left_ty = match self.infer_expr(binary.left()) {
    Ok(t) => t
    Err(e) => return Err(e)
  }
  let right_ty = match self.infer_expr(binary.right()) {
    Ok(t) => t
    Err(e) => return Err(e)
  }
  match binary.op() {
    Add | Sub => {
      // Allow Int and Interval arithmetic — if either side resolves to
      // Interval, coerce both to Interval; otherwise default to Int.
      let left_applied = self.apply(left_ty)
      let right_applied = self.apply(right_ty)
      let either_is_interval = match (left_applied, right_applied) {
        (Interval, _) => true
        (_, Interval) => true
        _ => false
      }
      if either_is_interval {
        match self.unify(left_ty, Interval, span) {
          Err(e) => return Err(e)
          Ok(_) => ()
        }
        match self.unify(right_ty, Interval, span) {
          Err(e) => return Err(e)
          Ok(_) => ()
        }
        Ok(Interval)
      } else {
        match self.unify(left_ty, IntTy, span) {
          Err(e) => return Err(e)
          Ok(_) => ()
        }
        match self.unify(right_ty, IntTy, span) {
          Err(e) => return Err(e)
          Ok(_) => ()
        }
        Ok(IntTy)
      }
    }
    Mul | Div => {
      match self.unify(left_ty, IntTy, span) {
        Err(e) => return Err(e)
        Ok(_) => ()
      }
      match self.unify(right_ty, IntTy, span) {
        Err(e) => return Err(e)
        Ok(_) => ()
      }
      Ok(IntTy)
    }
    Mod => {
      match self.unify(left_ty, IntTy, span) {
        Err(e) => return Err(e)
        Ok(_) => ()
      }
      match self.unify(right_ty, IntTy, span) {
        Err(e) => return Err(e)
        Ok(_) => ()
      }
      Ok(IntTy)
    }
    EqOp | NeOp | Lt | Le | Gt | Ge =>
      match self.unify(left_ty, right_ty, span) {
        Err(e) => Err(e)
        Ok(_) => Ok(BoolTy)
      }
    And | Or => {
      match self.unify(left_ty, BoolTy, span) {
        Err(e) => return Err(e)
        Ok(_) => ()
      }
      match self.unify(right_ty, BoolTy, span) {
        Err(e) => return Err(e)
        Ok(_) => ()
      }
      Ok(BoolTy)
    }
    Concat =>
      match self.unify(left_ty, right_ty, span) {
        Err(e) => Err(e)
        Ok(_) => Ok(left_ty)
      }
    Compose => {
      // Function composition: f >> g means \x -> g(f(x)).
      // If f : A -> B and g : B -> C, then f >> g : A -> C.
      let a = self.fresh_var()
      let b = self.fresh_var()
      let c = self.fresh_var()
      let f_ty = Function(a, b)
      let g_ty = Function(b, c)
      match self.unify(left_ty, f_ty, span) {
        Err(e) => return Err(e)
        Ok(_) => ()
      }
      match self.unify(right_ty, g_ty, span) {
        Err(e) => return Err(e)
        Ok(_) => ()
      }
      Ok(Function(a, c))
    }
  }
}

///|
/// Infer the type of a pattern. Binds variables to fresh type variables
/// in the current scope as a side effect.
pub fn TypeContext::infer_pattern(
  self : TypeContext,
  pattern : @core.Spanned[@ast.Pattern],
) -> Result[Type, TypeError] {
  match pattern.node() {
    Wildcard => Ok(self.fresh_var())
    Ident(ident) => {
      let ty = self.fresh_var()
      self.bind_mono(ident.name(), ty)
      Ok(ty)
    }
    Literal(lit) =>
      match lit {
        Integer(_) => Ok(IntTy)
        Float(_) => Ok(FloatTy)
        StringLit(_) => Ok(StringTy)
        BoolLit(_) => Ok(BoolTy)
        UnitLit => Ok(Unit)
      }
    Tuple(patterns) => {
      let types : Array[Type] = []
      for p in patterns {
        match self.infer_pattern(p) {
          Ok(t) => types.push(t)
          Err(err) => return Err(err)
        }
      }
      Ok(Tuple(types))
    }
    Array(arr) => {
      let elem_ty = self.fresh_var()
      for p in arr.elements() {
        let ty = match self.infer_pattern(p) {
          Ok(t) => t
          Err(e) => return Err(e)
        }
        match self.unify(elem_ty, ty, p.span()) {
          Ok(_) => ()
          Err(e) => return Err(e)
        }
      }
      Ok(ArrayTy(self.apply(elem_ty)))
    }
    Constructor(..) => Ok(self.fresh_var())
    Or(p1, _) => self.infer_pattern(p1)
    Annotated(p, _) => self.infer_pattern(p)
  }
}
