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

    // Lambda
    Lambda(lambda) => {
      self.push_scope()
      let param_types : Array[Type] = []
      for param in lambda.params() {
        let param_ty = self.fresh_var()
        match param.node() {
          Ident(ident) => self.bind_mono(ident.name(), param_ty)
          _ => ()
        }
        param_types.push(param_ty)
      }
      let body_ty = match self.infer_expr(lambda.body()) {
        Ok(t) => t
        Err(e) => {
          self.pop_scope()
          return Err(e)
        }
      }
      self.pop_scope()
      Ok(Type::function_n(param_types, body_ty))
    }

    // Application
    Application(app) => {
      let func_ty = match self.infer_expr(app.func()) {
        Ok(t) => t
        Err(e) => return Err(e)
      }
      let mut result_ty = func_ty
      for arg in app.args() {
        let arg_ty = match self.infer_expr(arg) {
          Ok(t) => t
          Err(e) => return Err(e)
        }
        let ret_ty = self.fresh_var()
        match self.unify(result_ty, Function(arg_ty, ret_ty), expr.span()) {
          Ok(_) => ()
          Err(e) => return Err(e)
        }
        result_ty = self.apply(ret_ty)
      }
      Ok(result_ty)
    }

    // Pipe — `arg |> func` = func(arg)
    Pipe(pipe) => {
      let arg_ty = match self.infer_expr(pipe.left()) {
        Ok(t) => t
        Err(e) => return Err(e)
      }
      let func_ty = match self.infer_expr(pipe.right()) {
        Ok(t) => t
        Err(e) => return Err(e)
      }
      let ret_ty = self.fresh_var()
      match self.unify(func_ty, Function(arg_ty, ret_ty), expr.span()) {
        Ok(_) => ()
        Err(e) => return Err(e)
      }
      Ok(self.apply(ret_ty))
    }

    // Binary operators
    Binary(binary) => self.infer_binary(binary, expr.span())

    // Unary operators
    Unary(unary) => {
      let operand_ty = match self.infer_expr(unary.operand()) {
        Ok(t) => t
        Err(e) => return Err(e)
      }
      match unary.op() {
        Neg =>
          match self.unify(operand_ty, IntTy, expr.span()) {
            Err(e) => Err(e)
            Ok(_) => Ok(IntTy)
          }
        Not =>
          match self.unify(operand_ty, BoolTy, expr.span()) {
            Err(e) => Err(e)
            Ok(_) => Ok(BoolTy)
          }
      }
    }

    // Array literal
    Array(elements) => {
      let elem_ty = self.fresh_var()
      for elem in elements {
        let ty = match self.infer_expr(elem) {
          Ok(t) => t
          Err(e) => return Err(e)
        }
        match self.unify(elem_ty, ty, elem.span()) {
          Ok(_) => ()
          Err(e) => return Err(e)
        }
      }
      Ok(ArrayTy(self.apply(elem_ty)))
    }

    // Tuple literal
    Tuple(elements) => {
      let types : Array[Type] = []
      for e in elements {
        match self.infer_expr(e) {
          Ok(t) => types.push(t)
          Err(err) => return Err(err)
        }
      }
      Ok(Tuple(types))
    }

    // Index
    Index(index) => {
      let base_ty = match self.infer_expr(index.base()) {
        Ok(t) => t
        Err(e) => return Err(e)
      }
      let index_ty = match self.infer_expr(index.index()) {
        Ok(t) => t
        Err(e) => return Err(e)
      }
      // Try array indexing
      match self.apply(base_ty) {
        ArrayTy(inner) =>
          match self.unify(index_ty, IntTy, expr.span()) {
            Ok(_) => Ok(inner)
            Err(e) => Err(e)
          }
        Scale =>
          match self.unify(index_ty, IntTy, expr.span()) {
            Ok(_) => Ok(Interval)
            Err(e) => Err(e)
          }
        _ => {
          // Generic: assume Array[fresh]
          let elem_ty = self.fresh_var()
          match self.unify(base_ty, ArrayTy(elem_ty), expr.span()) {
            Err(e) => return Err(e)
            Ok(_) => ()
          }
          match self.unify(index_ty, IntTy, expr.span()) {
            Err(e) => return Err(e)
            Ok(_) => ()
          }
          Ok(self.apply(elem_ty))
        }
      }
    }

    // If expression
    If(if_expr) => {
      let cond_ty = match self.infer_expr(if_expr.condition()) {
        Ok(t) => t
        Err(e) => return Err(e)
      }
      match self.unify(cond_ty, BoolTy, if_expr.condition().span()) {
        Ok(_) => ()
        Err(e) => return Err(e)
      }
      let then_ty = match self.infer_expr(if_expr.then_branch()) {
        Ok(t) => t
        Err(e) => return Err(e)
      }
      match if_expr.else_branch() {
        Some(else_branch) => {
          let else_ty = match self.infer_expr(else_branch) {
            Ok(t) => t
            Err(e) => return Err(e)
          }
          match self.unify(then_ty, else_ty, expr.span()) {
            Ok(_) => ()
            Err(e) => return Err(e)
          }
        }
        None => ()
      }
      Ok(self.apply(then_ty))
    }

    // Let expression
    Let(let_expr) => {
      let value_ty = match self.infer_expr(let_expr.value()) {
        Ok(t) => t
        Err(e) => return Err(e)
      }
      self.push_scope()
      match let_expr.pattern().node() {
        Ident(ident) => {
          let scheme = self.generalize(value_ty)
          self.bind(ident.name(), scheme)
        }
        _ => ()
      }
      let body_ty = match self.infer_expr(let_expr.body()) {
        Ok(t) => t
        Err(e) => {
          self.pop_scope()
          return Err(e)
        }
      }
      self.pop_scope()
      Ok(body_ty)
    }

    // With expression — keeps base type
    With(with_expr) =>
      match self.infer_expr(with_expr.base()) {
        Ok(t) => Ok(t)
        Err(e) => Err(e)
      }

    // Field access — simplified to fresh var until record types are real
    Field(_) => Ok(self.fresh_var())

    // Match expression
    Match(match_expr) => {
      let scrutinee_ty = match self.infer_expr(match_expr.scrutinee()) {
        Ok(t) => t
        Err(e) => return Err(e)
      }
      let result_ty = self.fresh_var()
      for arm in match_expr.arms() {
        let pattern_ty = match self.infer_pattern(arm.pattern()) {
          Ok(t) => t
          Err(e) => return Err(e)
        }
        match self.unify(scrutinee_ty, pattern_ty, arm.pattern().span()) {
          Ok(_) => ()
          Err(e) => return Err(e)
        }
        match arm.guard_expr() {
          Some(guard_e) => {
            let guard_ty = match self.infer_expr(guard_e) {
              Ok(t) => t
              Err(e) => return Err(e)
            }
            match self.unify(guard_ty, BoolTy, guard_e.span()) {
              Ok(_) => ()
              Err(e) => return Err(e)
            }
          }
          None => ()
        }
        let body_ty = match self.infer_expr(arm.body()) {
          Ok(t) => t
          Err(e) => return Err(e)
        }
        match self.unify(result_ty, body_ty, arm.body().span()) {
          Ok(_) => ()
          Err(e) => return Err(e)
        }
      }
      Ok(self.apply(result_ty))
    }

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
