///|
/// Unify `t1` with `t2`. Returns `Ok(())` on success and records the
/// resulting substitutions on `self`; otherwise returns the appropriate
/// `TypeError`. Mirrors `TypeContext::unify` in the Rust crate.
pub fn TypeContext::unify(
  self : TypeContext,
  t1 : Type,
  t2 : Type,
  span : @core.Span,
) -> Result[Unit, TypeError] {
  let t1 = self.apply(t1)
  let t2 = self.apply(t2)
  // Error types unify with anything — used during recovery.
  match (t1, t2) {
    (ErrorTy, _) => Ok(())
    (_, ErrorTy) => Ok(())
    (Var(v1), Var(v2)) =>
      if v1 == v2 {
        Ok(())
      } else if self.occurs_in(v1, Var(v2)) {
        Err(OccursCheck(span=span))
      } else {
        self.add_substitution(v1, Var(v2))
        Ok(())
      }
    (Var(v), other) =>
      if self.occurs_in(v, other) {
        Err(OccursCheck(span=span))
      } else {
        self.add_substitution(v, other)
        Ok(())
      }
    (other, Var(v)) =>
      if self.occurs_in(v, other) {
        Err(OccursCheck(span=span))
      } else {
        self.add_substitution(v, other)
        Ok(())
      }
    (Function(a1, r1), Function(a2, r2)) =>
      match self.unify(a1, a2, span) {
        Err(e) => Err(e)
        Ok(_) => self.unify(r1, r2, span)
      }
    (Tuple(e1), Tuple(e2)) =>
      if e1.length() != e2.length() {
        Err(UnificationError(Tuple(e1), Tuple(e2), span))
      } else {
        let mut i = 0
        let mut err : TypeError? = None
        while i < e1.length() {
          match err {
            Some(_) => break
            None =>
              match self.unify(e1[i], e2[i], span) {
                Err(e) => err = Some(e)
                Ok(_) => i += 1
              }
          }
        }
        match err {
          Some(e) => Err(e)
          None => Ok(())
        }
      }
    (ArrayTy(e1), ArrayTy(e2)) => self.unify(e1, e2, span)
    (a, b) =>
      if a == b {
        Ok(())
      } else {
        Err(UnificationError(a, b, span))
      }
  }
}

///|
/// Occurs check — does `needle` appear inside `ty` after substitution?
/// Used to reject infinite types like `t0 = t0 -> t0`.
pub fn TypeContext::occurs_in(
  self : TypeContext,
  needle : TyVar,
  ty : Type,
) -> Bool {
  let ty = self.apply(ty)
  match ty {
    Var(v) => v == needle
    Function(a, b) =>
      self.occurs_in(needle, a) || self.occurs_in(needle, b)
    Tuple(elems) => {
      for e in elems {
        if self.occurs_in(needle, e) {
          return true
        }
      }
      false
    }
    ArrayTy(elem) => self.occurs_in(needle, elem)
    _ => false
  }
}
