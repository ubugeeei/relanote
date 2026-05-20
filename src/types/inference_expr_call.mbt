///|
fn TypeContext::infer_lambda(
  self : TypeContext,
  lambda : @ast.Lambda,
) -> Result[Type, TypeError] {
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

///|
fn TypeContext::infer_application(
  self : TypeContext,
  app : @ast.Application,
  span : @core.Span,
) -> Result[Type, TypeError] {
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
    match self.unify(result_ty, Function(arg_ty, ret_ty), span) {
      Ok(_) => ()
      Err(e) => return Err(e)
    }
    result_ty = self.apply(ret_ty)
  }
  Ok(result_ty)
}

///|
fn TypeContext::infer_pipe(
  self : TypeContext,
  pipe : @ast.Pipe,
  span : @core.Span,
) -> Result[Type, TypeError] {
  let arg_ty = match self.infer_expr(pipe.left()) {
    Ok(t) => t
    Err(e) => return Err(e)
  }
  let func_ty = match self.infer_expr(pipe.right()) {
    Ok(t) => t
    Err(e) => return Err(e)
  }
  let ret_ty = self.fresh_var()
  match self.unify(func_ty, Function(arg_ty, ret_ty), span) {
    Ok(_) => Ok(self.apply(ret_ty))
    Err(e) => Err(e)
  }
}

///|
fn TypeContext::infer_unary(
  self : TypeContext,
  unary : @ast.Unary,
  span : @core.Span,
) -> Result[Type, TypeError] {
  let operand_ty = match self.infer_expr(unary.operand()) {
    Ok(t) => t
    Err(e) => return Err(e)
  }
  match unary.op() {
    Neg =>
      match self.unify(operand_ty, IntTy, span) {
        Err(e) => Err(e)
        Ok(_) => Ok(IntTy)
      }
    Not =>
      match self.unify(operand_ty, BoolTy, span) {
        Err(e) => Err(e)
        Ok(_) => Ok(BoolTy)
      }
  }
}
