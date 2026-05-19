test "Env::new is empty" {
  let env = Env::new()
  assert_true(env.lookup("x") == None)
}

test "Env::bind / lookup" {
  let env = Env::new()
  env.bind("x", IntV(42L))
  assert_true(env.lookup("x") == Some(IntV(42L)))
}

test "Env::with_parent falls back to parent scope" {
  let outer = Env::new()
  outer.bind("x", IntV(1L))
  let inner = Env::with_parent(outer)
  assert_true(inner.lookup("x") == Some(IntV(1L)))
  inner.bind("x", IntV(2L))
  assert_true(inner.lookup("x") == Some(IntV(2L)))
}

test "Evaluator::eval_program returns UnitV in the skeleton" {
  let ev = Evaluator::new()
  let prog = @ast.Program::empty()
  match ev.eval_program(prog) {
    Ok(UnitV) => ()
    Ok(_) => abort("expected UnitV from the skeleton")
    Err(_) => abort("skeleton should not fail")
  }
}

test "EvalError::span is None for module-level errors" {
  let mn = ModuleNotFound(module="m", path="p", reason="r")
  assert_true(mn.span() == None)
  let cd = CircularModuleDependency(module="m")
  assert_true(cd.span() == None)
}

test "EvalError::message renders WrongArity verbatim" {
  let err = WrongArity(expected=2, got=3, span=@core.Span::dummy())
  assert_eq(err.message(), "wrong number of arguments: expected 2, got 3")
}
