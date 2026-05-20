///|
/// Lower an AST `Program` to HIR. The pass walks every top-level item
/// and dispatches to a per-variant lowering helper; expressions are
/// recursively lowered through `lower_expr`.
///
/// The lowering pass shares the type checker's context so each lowered
/// expression carries a real `@types.Type`. Constructs the lowering
/// doesn't yet model (`Match`, `With`, `Field`, `InScale`, `Over`, and
/// music structures) fall through to `Placeholder` with a fresh type
/// variable — matching how the evaluator treats them today.
pub fn lower_program(program : @ast.Program) -> TypedProgram {
  let checker = @types.TypeChecker::new()
  let _ = checker.check_program(program)
  let ctx = checker.context()
  let items : Array[TypedItem] = []
  for spanned in program.items() {
    items.push(lower_item(spanned.node(), ctx))
  }
  TypedProgram::new(items)
}

///|
fn lower_item(item : @ast.Item, ctx : @types.TypeContext) -> TypedItem {
  match item {
    ScaleDef(def) => TScaleDef(def.name().name(), @types.Type::Scale)
    ChordDef(def) => TChordDef(def.name().name(), @types.Type::Chord)
    SynthDef(def) => TSynthDef(def.name().name(), @types.Type::Synth)
    LetBinding(binding) => {
      let value = lower_expr(binding.value(), ctx)
      match binding.pattern().node() {
        Ident(ident) => TLetBinding(ident.name(), value)
        _ => TLetBinding("<destructure>", value)
      }
    }
    SetBinding(binding) =>
      TSetBinding(binding.name().name(), lower_expr(binding.value(), ctx))
    FunctionDef(def) => {
      let params : Array[@core.InternedStr] = []
      for p in def.params() {
        match p.node() {
          Ident(ident) => params.push(ident.name())
          _ => params.push("<destructure>")
        }
      }
      let body = lower_expr(def.body(), ctx)
      let fn_ty = match ctx.lookup(def.name().name()) {
        Some(scheme) => scheme.ty()
        None => ctx.fresh_var()
      }
      let lambda = TypedExpr::with_span(
        TLambda(params, body),
        fn_ty,
        def.body().span(),
      )
      TFunctionDef(def.name().name(), lambda)
    }
    ExprStmt(expr) => TExprStmt(lower_expr(expr, ctx))
    // Items the lowering pass doesn't model yet.
    TuningDef(_) | GrooveDef(_) | EffectDef(_) | MixDef(_) => TNoop
    Import(_) | Export(_) | Mod(_) | Use(_) => TNoop
  }
}

///|
/// Lower an expression. The walker piggybacks on the type checker's
/// `infer_expr` to attach a `@types.Type` to every node; if inference
/// fails the node falls through to `TError` so downstream phases can
/// still produce output (matching the AST's `Error` recovery node).
fn lower_expr(
  expr : @core.Spanned[@ast.Expr],
  ctx : @types.TypeContext,
) -> TypedExpr {
  let ty = match ctx.infer_expr(expr) {
    Ok(t) => ctx.apply(t)
    Err(_) => @types.Type::ErrorTy
  }
  let span = expr.span()
  match expr.node() {
    Integer(n) => TypedExpr::with_span(TInteger(n), ty, span)
    Float(f) => TypedExpr::with_span(TFloat(f), ty, span)
    StringLit(s) => TypedExpr::with_span(TString(s), ty, span)
    BoolLit(b) => TypedExpr::with_span(TBool(b), ty, span)
    UnitLit => TypedExpr::with_span(TUnit, ty, span)
    Ident(ident) => TypedExpr::with_span(TIdent(ident.name()), ty, span)
    Application(app) => {
      let func = lower_expr(app.func(), ctx)
      let args : Array[TypedExpr] = []
      for a in app.args() {
        args.push(lower_expr(a, ctx))
      }
      TypedExpr::with_span(TApp(func, args), ty, span)
    }
    Lambda(lambda) => {
      let params : Array[@core.InternedStr] = []
      for p in lambda.params() {
        match p.node() {
          Ident(ident) => params.push(ident.name())
          _ => params.push("<destructure>")
        }
      }
      let body = lower_expr(lambda.body(), ctx)
      TypedExpr::with_span(TLambda(params, body), ty, span)
    }
    Let(let_expr) => {
      let value = lower_expr(let_expr.value(), ctx)
      let body = lower_expr(let_expr.body(), ctx)
      let name = match let_expr.pattern().node() {
        Ident(ident) => ident.name()
        _ => "<destructure>"
      }
      TypedExpr::with_span(TLet(name, value, body), ty, span)
    }
    Pipe(pipe) => {
      let left = lower_expr(pipe.left(), ctx)
      let right = lower_expr(pipe.right(), ctx)
      TypedExpr::with_span(TPipe(left, right), ty, span)
    }
    If(if_expr) => {
      let cond = lower_expr(if_expr.condition(), ctx)
      let then_b = lower_expr(if_expr.then_branch(), ctx)
      let else_b = match if_expr.else_branch() {
        Some(e) => lower_expr(e, ctx)
        None => TypedExpr::with_span(TUnit, @types.Type::Unit, span)
      }
      TypedExpr::with_span(TIf(cond, then_b, else_b), ty, span)
    }
    Paren(inner) => lower_expr(inner, ctx)
    Annotated(inner, _) => lower_expr(inner, ctx)
    Error => TypedExpr::with_span(TError, ty, span)
    _ => TypedExpr::with_span(Placeholder, ty, span)
  }
}
