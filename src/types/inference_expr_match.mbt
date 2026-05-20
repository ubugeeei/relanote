///|
fn TypeContext::infer_match(
  self : TypeContext,
  match_expr : @ast.MatchExpr,
) -> Result[Type, TypeError] {
  let scrutinee_ty = match self.infer_expr(match_expr.scrutinee()) {
    Ok(t) => t
    Err(e) => return Err(e)
  }
  let result_ty = self.fresh_var()
  for arm in match_expr.arms() {
    match self.infer_match_arm(scrutinee_ty, result_ty, arm) {
      Ok(_) => ()
      Err(e) => return Err(e)
    }
  }
  Ok(self.apply(result_ty))
}

///|
fn TypeContext::infer_match_arm(
  self : TypeContext,
  scrutinee_ty : Type,
  result_ty : Type,
  arm : @ast.MatchArm,
) -> Result[Unit, TypeError] {
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
  self.unify(result_ty, body_ty, arm.body().span())
}
