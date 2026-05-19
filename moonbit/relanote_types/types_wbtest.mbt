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
  // `TypeScheme` doesn't derive `Eq`, so `Option[TypeScheme] == None`
  // can't reuse the prelude's Option Eq instance — use an explicit
  // match.
  match ctx.lookup("x") {
    None => ()
    Some(_) => abort("expected the binding to be popped")
  }
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
  let tv = match v {
    Var(x) => x
    _ => abort("fresh_var should return Var")
  }
  // t0 = t0 -> t0 would be infinite — must fail occurs check.
  match ctx.unify(Var(tv), Function(Var(tv), Var(tv)), span) {
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
  // Build the quantifier through `fresh_var` so the context's counter
  // advances past it; otherwise the next `fresh_var` call inside
  // `instantiate` would hand out the same id and the substitution
  // would be indistinguishable from the original.
  let quantifier_ty = ctx.fresh_var()
  let v0 = match quantifier_ty {
    Var(x) => x
    _ => abort("fresh_var should return a Var")
  }
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

// `install_prelude` is called from `TypeChecker::new()`, so we drive these
// tests through the public entry point and look up bindings in the
// checker's context.

test "install_prelude seeds reverse : Block -> Block" {
  let checker = TypeChecker::new()
  match checker.context().lookup("reverse") {
    Some(scheme) =>
      match scheme.ty() {
        Function(Block, Block) => ()
        other =>
          abort("expected Block -> Block, got " + other.to_display_string())
      }
    None => abort("expected reverse to be in scope")
  }
}

test "install_prelude seeds a monomorphic synth preset" {
  let checker = TypeChecker::new()
  match checker.context().lookup("Chiptune") {
    Some(scheme) => {
      assert_eq(scheme.quantifiers().length(), 0)
      match scheme.ty() {
        Synth => ()
        other =>
          abort("expected Synth, got " + other.to_display_string())
      }
    }
    None => abort("expected Chiptune to be in scope")
  }
}

test "install_prelude seeds polymorphic map with two quantifiers" {
  let checker = TypeChecker::new()
  match checker.context().lookup("map") {
    Some(scheme) => {
      // `map : forall a b. (a -> b) -> [a] -> [b]` — two quantifiers.
      assert_eq(scheme.quantifiers().length(), 2)
    }
    None => abort("expected map to be in scope")
  }
}

test "check_program reports undefined variable" {
  let program = @ast.Program::new([
    @core.Spanned::new(
      @ast.Item::ExprStmt(
        @core.Spanned::new(
          @ast.Expr::Ident(@ast.Ident::new("undefined_xyz")),
          @core.Span::dummy(),
        ),
      ),
      @core.Span::dummy(),
    ),
  ])
  let checker = TypeChecker::new()
  let errors = checker.check_program(program)
  assert_eq(errors.length(), 1)
  match errors[0] {
    UndefinedVariable(name~, ..) => assert_eq(name, "undefined_xyz")
    other => abort("expected UndefinedVariable, got " + other.message())
  }
}

test "check_program accepts integer literal as no-op item" {
  let program = @ast.Program::new([
    @core.Spanned::new(
      @ast.Item::ExprStmt(
        @core.Spanned::new(
          @ast.Expr::Integer(42L),
          @core.Span::dummy(),
        ),
      ),
      @core.Span::dummy(),
    ),
  ])
  let checker = TypeChecker::new()
  let errors = checker.check_program(program)
  assert_eq(errors.length(), 0)
}

test "check_program binds let value type for downstream lookups" {
  let pattern = @core.Spanned::new(
    @ast.Pattern::Ident(@ast.Ident::new("x")),
    @core.Span::dummy(),
  )
  let value = @core.Spanned::new(
    @ast.Expr::Integer(7L),
    @core.Span::dummy(),
  )
  let program = @ast.Program::new([
    @core.Spanned::new(
      @ast.Item::LetBinding(@ast.LetBinding::new(pattern, None, value)),
      @core.Span::dummy(),
    ),
  ])
  let checker = TypeChecker::new()
  let _ = checker.check_program(program)
  match checker.lookup_type("x") {
    Some(IntTy) => ()
    Some(other) => abort("x should be Int, got " + other.to_display_string())
    None => abort("x should be bound after check_program")
  }
}

test "infer_expr flags type mismatch in if branches" {
  let condition = @core.Spanned::new(
    @ast.Expr::BoolLit(true),
    @core.Span::dummy(),
  )
  let then_branch = @core.Spanned::new(
    @ast.Expr::Integer(1L),
    @core.Span::dummy(),
  )
  let else_branch = @core.Spanned::new(
    @ast.Expr::BoolLit(false),
    @core.Span::dummy(),
  )
  let if_expr = @core.Spanned::new(
    @ast.Expr::If(
      @ast.IfExpr::new(condition, then_branch, Some(else_branch)),
    ),
    @core.Span::dummy(),
  )
  let ctx = TypeContext::new()
  match ctx.infer_expr(if_expr) {
    Ok(t) => abort("expected mismatch, inferred " + t.to_display_string())
    Err(UnificationError(_, _, _)) => ()
    Err(Mismatch(..)) => ()
    Err(other) => abort("expected unification error, got " + other.message())
  }
}

test "install_prelude seeds compose : [Section] -> Song" {
  let checker = TypeChecker::new()
  match checker.context().lookup("compose") {
    Some(scheme) =>
      match scheme.ty() {
        Function(ArrayTy(Section), Song) => ()
        other =>
          abort("expected [Section] -> Song, got " + other.to_display_string())
      }
    None => abort("expected compose to be in scope")
  }
}
