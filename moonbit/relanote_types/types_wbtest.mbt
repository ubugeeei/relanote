// Whitebox tests for the type-system substrate. Inference itself is not
// ported yet — the test coverage here is for the data types and the
// unification / context machinery they need.

test "Type::function curries" {
  let t = Type::function(IntTy, Type::function(BoolTy, StringTy))
  match t {
    Function(_, rest) =>
      match rest {
        Function(_, _) => ()
        _ => abort("expected nested function for the curried second arg")
      }
    _ => abort("expected outer Function variant")
  }
}

test "Type::function_n is right-associative" {
  let t = Type::function_n([IntTy, BoolTy], StringTy)
  // (Int, Bool) -> String == Int -> (Bool -> String)
  match t {
    Function(_, rest) =>
      match rest {
        Function(_, _) => ()
        _ => abort("expected curried inner function")
      }
    _ => abort("expected outer Function variant")
  }
}

test "has_vars / free_vars" {
  let v0 = TyVar::new(0)
  let v1 = TyVar::new(1)
  let mono = IntTy
  let poly = Function(Var(v0), Tuple([Var(v1), IntTy]))
  assert_false(mono.has_vars())
  assert_true(poly.has_vars())
  let frees = poly.free_vars()
  assert_eq(frees.length(), 2)
  assert_true(frees[0] == v0)
  assert_true(frees[1] == v1)
}

test "Type::to_display_string matches Rust crate" {
  assert_eq(IntTy.to_display_string(), "Int")
  assert_eq(Type::array(BoolTy).to_display_string(), "[Bool]")
  assert_eq(
    Type::function(IntTy, BoolTy).to_display_string(),
    "Int -> Bool",
  )
  assert_eq(
    Type::function(Type::function(IntTy, IntTy), BoolTy).to_display_string(),
    "(Int -> Int) -> Bool",
  )
  assert_eq(Var(TyVar::new(7)).to_display_string(), "t7")
}

test "TypeContext bind / lookup / pop_scope" {
  let ctx = TypeContext::new()
  ctx.push_scope()
  ctx.bind_mono("x", IntTy)
  match ctx.lookup("x") {
    Some(scheme) =>
      match scheme.ty() {
        IntTy => ()
        _ => abort("expected Int")
      }
    None => abort("expected binding for x")
  }
  ctx.pop_scope()
  assert_true(ctx.lookup("x") == None)
}

test "TypeContext fresh_var hands out fresh ids" {
  let ctx = TypeContext::new()
  let a = ctx.fresh_var()
  let b = ctx.fresh_var()
  match (a, b) {
    (Var(va), Var(vb)) => {
      assert_eq(va.id(), 0)
      assert_eq(vb.id(), 1)
    }
    _ => abort("fresh_var should always return a Var")
  }
}

test "unify of two equal primitives succeeds" {
  let ctx = TypeContext::new()
  let span = @core.Span::dummy()
  match ctx.unify(IntTy, IntTy, span) {
    Ok(_) => ()
    Err(_) => abort("Int should unify with Int")
  }
}

test "unify of variable with primitive records substitution" {
  let ctx = TypeContext::new()
  let span = @core.Span::dummy()
  let v = ctx.fresh_var()
  match ctx.unify(v, IntTy, span) {
    Ok(_) => ()
    Err(_) => abort("var should unify with Int")
  }
  match ctx.apply(v) {
    IntTy => ()
    _ => abort("apply should rewrite the variable to Int")
  }
}

test "unify mismatched primitives reports UnificationError" {
  let ctx = TypeContext::new()
  let span = @core.Span::dummy()
  match ctx.unify(IntTy, BoolTy, span) {
    Ok(_) => abort("Int should not unify with Bool")
    Err(UnificationError(_, _, _)) => ()
    Err(_) => abort("expected UnificationError variant")
  }
}

test "occurs check rejects infinite types" {
  let ctx = TypeContext::new()
  let span = @core.Span::dummy()
  let v = ctx.fresh_var()
  let var = match v {
    Var(x) => x
    _ => abort("fresh_var should return Var")
  }
  // t0 = t0 -> t0 would be infinite — must fail occurs check.
  match ctx.unify(Var(var), Function(Var(var), Var(var)), span) {
    Ok(_) => abort("occurs check should have failed")
    Err(OccursCheck(_)) => ()
    Err(_) => abort("expected OccursCheck error")
  }
}

test "TypeScheme::mono has no quantifiers" {
  let s = TypeScheme::mono(IntTy)
  assert_eq(s.quantifiers().length(), 0)
}

test "TypeScheme::poly retains its quantifiers" {
  let v0 = TyVar::new(0)
  let s = TypeScheme::poly([v0], Function(Var(v0), Var(v0)))
  assert_eq(s.quantifiers().length(), 1)
  assert_true(s.quantifiers()[0] == v0)
}

test "instantiate replaces quantifiers with fresh vars" {
  let ctx = TypeContext::new()
  let v0 = TyVar::new(0)
  let scheme = TypeScheme::poly([v0], Function(Var(v0), Var(v0)))
  let inst = ctx.instantiate(scheme)
  match inst {
    Function(Var(a), Var(b)) => {
      // Same fresh var on both sides; not equal to the original quantifier.
      assert_true(a == b)
      assert_true(a != v0)
    }
    _ => abort("instantiate should yield a function type")
  }
}

test "TypeError::span returns the right span variant" {
  let span = @core.Span::dummy()
  let err = OccursCheck(span=span)
  assert_true(err.span() == span)
}
