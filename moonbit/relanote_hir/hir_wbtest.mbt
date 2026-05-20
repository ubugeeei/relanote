// HIR lowering tests. The lowering pass shares the type checker's
// context so each typed expression carries a real `@types.Type`.

///|
test "TypedProgram::empty has zero items" {
  let p = TypedProgram::empty()
  assert_eq(p.items().length(), 0)
}

///|
test "TypedExpr::new keeps its kind and type" {
  let e = TypedExpr::new(Placeholder, @types.Unit)
  match e.kind() {
    Placeholder => ()
    _ => abort("expected Placeholder")
  }
  match e.ty() {
    @types.Unit => ()
    _ => abort("expected Unit type")
  }
}

///|
test "lower_program on an empty program is empty" {
  let prog = @ast.Program::empty()
  let lowered = lower_program(prog)
  assert_eq(lowered.items().length(), 0)
}

///|
test "lower_program annotates an integer expression statement with Int" {
  let item : @ast.Item = @ast.ExprStmt(
    @core.Spanned::new(@ast.Expr::Integer(42L), @core.Span::dummy()),
  )
  let prog = @ast.Program::new([@core.Spanned::new(item, @core.Span::dummy())])
  let lowered = lower_program(prog)
  assert_eq(lowered.items().length(), 1)
  match lowered.items()[0] {
    TExprStmt(e) => {
      match e.kind() {
        TInteger(42L) => ()
        _ => abort("expected TInteger(42)")
      }
      match e.ty() {
        @types.IntTy => ()
        _ => abort("expected Int type")
      }
    }
    _ => abort("expected TExprStmt")
  }
}

///|
test "lower_program lowers a scale definition to TScaleDef" {
  let def = @ast.ScaleDef::new(@ast.Ident::new("Major"), None, [])
  let item : @ast.Item = @ast.ScaleDef(def)
  let prog = @ast.Program::new([@core.Spanned::new(item, @core.Span::dummy())])
  let lowered = lower_program(prog)
  match lowered.items()[0] {
    TScaleDef(name, ty) => {
      assert_eq(name, "Major")
      match ty {
        @types.Scale => ()
        _ => abort("expected Scale type")
      }
    }
    _ => abort("expected TScaleDef")
  }
}

///|
test "lower_program lowers a let binding with the value's inferred type" {
  let pat = @core.Spanned::new(
    @ast.Pattern::Ident(@ast.Ident::new("x")),
    @core.Span::dummy(),
  )
  let value = @core.Spanned::new(@ast.Expr::BoolLit(true), @core.Span::dummy())
  let item : @ast.Item = @ast.LetBinding(@ast.LetBinding::new(pat, None, value))
  let prog = @ast.Program::new([@core.Spanned::new(item, @core.Span::dummy())])
  let lowered = lower_program(prog)
  match lowered.items()[0] {
    TLetBinding(name, expr) => {
      assert_eq(name, "x")
      match expr.kind() {
        TBool(true) => ()
        _ => abort("expected TBool(true)")
      }
      match expr.ty() {
        @types.BoolTy => ()
        _ => abort("expected Bool type")
      }
    }
    _ => abort("expected TLetBinding")
  }
}

///|
test "lower_program lowers an if expression with both branches typed" {
  let if_expr = @ast.IfExpr::new(
    @core.Spanned::new(@ast.Expr::BoolLit(true), @core.Span::dummy()),
    @core.Spanned::new(@ast.Expr::Integer(1L), @core.Span::dummy()),
    Some(@core.Spanned::new(@ast.Expr::Integer(2L), @core.Span::dummy())),
  )
  let stmt : @ast.Item = @ast.ExprStmt(
    @core.Spanned::new(@ast.Expr::If(if_expr), @core.Span::dummy()),
  )
  let prog = @ast.Program::new([@core.Spanned::new(stmt, @core.Span::dummy())])
  let lowered = lower_program(prog)
  match lowered.items()[0] {
    TExprStmt(e) =>
      match e.kind() {
        TIf(_, then_b, else_b) => {
          match then_b.ty() {
            @types.IntTy => ()
            _ => abort("expected Int in then branch")
          }
          match else_b.ty() {
            @types.IntTy => ()
            _ => abort("expected Int in else branch")
          }
        }
        _ => abort("expected TIf")
      }
    _ => abort("expected TExprStmt")
  }
}
