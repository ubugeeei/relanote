///|
fn TypeContext::infer_array(
  self : TypeContext,
  elements : Array[@core.Spanned[@ast.Expr]],
) -> Result[Type, TypeError] {
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

///|
fn TypeContext::infer_tuple(
  self : TypeContext,
  elements : Array[@core.Spanned[@ast.Expr]],
) -> Result[Type, TypeError] {
  let types : Array[Type] = []
  for e in elements {
    match self.infer_expr(e) {
      Ok(t) => types.push(t)
      Err(err) => return Err(err)
    }
  }
  Ok(Tuple(types))
}

///|
fn TypeContext::infer_index(
  self : TypeContext,
  index : @ast.Index,
  span : @core.Span,
) -> Result[Type, TypeError] {
  let base_ty = match self.infer_expr(index.base()) {
    Ok(t) => t
    Err(e) => return Err(e)
  }
  let index_ty = match self.infer_expr(index.index()) {
    Ok(t) => t
    Err(e) => return Err(e)
  }
  match self.apply(base_ty) {
    ArrayTy(inner) =>
      match self.unify(index_ty, IntTy, span) {
        Ok(_) => Ok(inner)
        Err(e) => Err(e)
      }
    Scale =>
      match self.unify(index_ty, IntTy, span) {
        Ok(_) => Ok(Interval)
        Err(e) => Err(e)
      }
    _ => self.infer_generic_index(base_ty, index_ty, span)
  }
}

///|
fn TypeContext::infer_generic_index(
  self : TypeContext,
  base_ty : Type,
  index_ty : Type,
  span : @core.Span,
) -> Result[Type, TypeError] {
  let elem_ty = self.fresh_var()
  match self.unify(base_ty, ArrayTy(elem_ty), span) {
    Err(e) => return Err(e)
    Ok(_) => ()
  }
  match self.unify(index_ty, IntTy, span) {
    Err(e) => return Err(e)
    Ok(_) => Ok(self.apply(elem_ty))
  }
}

///|
fn TypeContext::infer_if(
  self : TypeContext,
  if_expr : @ast.IfExpr,
  span : @core.Span,
) -> Result[Type, TypeError] {
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
      match self.unify(then_ty, else_ty, span) {
        Ok(_) => ()
        Err(e) => return Err(e)
      }
    }
    None => ()
  }
  Ok(self.apply(then_ty))
}

///|
fn TypeContext::infer_let(
  self : TypeContext,
  let_expr : @ast.LetExpr,
) -> Result[Type, TypeError] {
  let value_ty = match self.infer_expr(let_expr.value()) {
    Ok(t) => t
    Err(e) => return Err(e)
  }
  self.push_scope()
  match let_expr.pattern().node() {
    Ident(ident) => self.bind(ident.name(), self.generalize(value_ty))
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
