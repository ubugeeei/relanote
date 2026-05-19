// `Value` no longer derives `Eq` (its variants now carry AST nodes that
// don't have value equality), so these tests pattern-match on lookups
// instead of using `==`.

test "Env::new is empty" {
  let env = Env::new()
  match env.lookup("x") {
    None => ()
    Some(_) => abort("expected empty env")
  }
}

test "Env::bind / lookup" {
  let env = Env::new()
  env.bind("x", IntV(42L))
  match env.lookup("x") {
    Some(IntV(42L)) => ()
    _ => abort("expected x = 42")
  }
}

test "Env::with_parent falls back to parent scope" {
  let outer = Env::new()
  outer.bind("x", IntV(1L))
  let inner = Env::with_parent(outer)
  match inner.lookup("x") {
    Some(IntV(1L)) => ()
    _ => abort("expected parent x = 1")
  }
  inner.bind("x", IntV(2L))
  match inner.lookup("x") {
    Some(IntV(2L)) => ()
    _ => abort("expected shadowed x = 2")
  }
}

test "Evaluator::eval_program returns UnitV on an empty program" {
  let ev = Evaluator::new()
  let prog = @ast.Program::empty()
  match ev.eval_program(prog) {
    Ok(UnitV) => ()
    Ok(_) => abort("expected UnitV")
    Err(_) => abort("empty program should not fail")
  }
}

test "Evaluator::eval_program threads the final expression" {
  let ev = Evaluator::new()
  let stmt : @ast.Item = @ast.ExprStmt(
    @core.Spanned::new(@ast.Expr::Integer(7L), @core.Span::dummy()),
  )
  let prog = @ast.Program::new([
    @core.Spanned::new(stmt, @core.Span::dummy()),
  ])
  match ev.eval_program(prog) {
    Ok(IntV(7L)) => ()
    Ok(_) => abort("expected the last expression to surface")
    Err(_) => abort("integer literal should evaluate")
  }
}

test "Evaluator binds let value into the environment" {
  let ev = Evaluator::new()
  let pat = @core.Spanned::new(
    @ast.Pattern::Ident(@ast.Ident::new("count")),
    @core.Span::dummy(),
  )
  let value = @core.Spanned::new(
    @ast.Expr::Integer(11L),
    @core.Span::dummy(),
  )
  let item : @ast.Item = @ast.LetBinding(
    @ast.LetBinding::new(pat, None, value),
  )
  let prog = @ast.Program::new([
    @core.Spanned::new(item, @core.Span::dummy()),
  ])
  match ev.eval_program(prog) {
    Ok(_) => ()
    Err(e) => abort("let binding should evaluate: " + e.message())
  }
  match ev.env().lookup("count") {
    Some(IntV(11L)) => ()
    _ => abort("expected count = 11 in the env after let")
  }
}

test "Evaluator binds scale def by name" {
  let ev = Evaluator::new()
  let def = @ast.ScaleDef::new(@ast.Ident::new("Mode"), None, [])
  let item : @ast.Item = @ast.ScaleDef(def)
  let prog = @ast.Program::new([
    @core.Spanned::new(item, @core.Span::dummy()),
  ])
  let _ = ev.eval_program(prog)
  match ev.env().lookup("Mode") {
    Some(ScaleV(_)) => ()
    _ => abort("expected Mode to be a ScaleV")
  }
}

test "Evaluator reports undefined identifier" {
  let ev = Evaluator::new()
  let expr_item : @ast.Item = @ast.ExprStmt(
    @core.Spanned::new(
      @ast.Expr::Ident(@ast.Ident::new("nope")),
      @core.Span::dummy(),
    ),
  )
  let prog = @ast.Program::new([
    @core.Spanned::new(expr_item, @core.Span::dummy()),
  ])
  match ev.eval_program(prog) {
    Ok(_) => abort("expected an UndefinedVariable error")
    Err(UndefinedVariable(name~, ..)) => assert_eq(name, "nope")
    Err(other) =>
      abort("expected UndefinedVariable, got " + other.message())
  }
}

test "EvalError::span is None for module-level errors" {
  let mn = ModuleNotFound(module_name="m", path="p", reason="r")
  assert_true(mn.span() == None)
  let cd = CircularModuleDependency(module_name="m")
  assert_true(cd.span() == None)
}

test "EvalError::message renders WrongArity verbatim" {
  let err = WrongArity(expected=2, got=3, span=@core.Span::dummy())
  assert_eq(err.message(), "wrong number of arguments: expected 2, got 3")
}
