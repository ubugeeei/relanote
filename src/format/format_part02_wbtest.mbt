///|
test "import wildcard" {
  let decl = @ast.ImportDecl::new([@ast.All], "m")
  let item : @ast.Item = @ast.Import(decl)
  let prog = @ast.Program::new([spanned(item)])
  assert_eq(format(prog, cfg), "import * from \"m\"\n")
}

///|
test "import wildcard with alias" {
  let decl = @ast.ImportDecl::new([@ast.AllAliased(@ast.Ident::new("M"))], "m")
  let item : @ast.Item = @ast.Import(decl)
  let prog = @ast.Program::new([spanned(item)])
  assert_eq(format(prog, cfg), "import * as M from \"m\"\n")
}

///|
test "export of named symbols renders comma-separated" {
  let decl : @ast.ExportDecl = @ast.Named([
    @ast.Ident::new("foo"),
    @ast.Ident::new("bar"),
  ])
  let item : @ast.Item = @ast.Export(decl)
  let prog = @ast.Program::new([spanned(item)])
  assert_eq(format(prog, cfg), "export foo, bar\n")
}

///|
test "export re-export renders with braces and a `from` clause" {
  let decl : @ast.ExportDecl = @ast.ReExport(
    items=[@ast.Ident::new("a"), @ast.Ident::new("b")],
    from="m",
  )
  let item : @ast.Item = @ast.Export(decl)
  let prog = @ast.Program::new([spanned(item)])
  assert_eq(format(prog, cfg), "export { a, b } from \"m\"\n")
}

///|
test "use simple path joins segments with `::`" {
  let path = @ast.UsePath::new(
    [@ast.Ident::new("foo"), @ast.Ident::new("bar")],
    @ast.Simple,
  )
  let item : @ast.Item = @ast.Use(@ast.UseDecl::new(path))
  let prog = @ast.Program::new([spanned(item)])
  assert_eq(format(prog, cfg), "use foo::bar\n")
}

///|
test "use glob ends with `::*`" {
  let path = @ast.UsePath::new([@ast.Ident::new("foo")], @ast.Glob)
  let item : @ast.Item = @ast.Use(@ast.UseDecl::new(path))
  let prog = @ast.Program::new([spanned(item)])
  assert_eq(format(prog, cfg), "use foo::*\n")
}

///|
test "use group renders inside braces with optional alias" {
  let items : Array[@ast.UseItem] = [
    @ast.UseItem::new(@ast.Ident::new("a"), None),
    @ast.UseItem::new(@ast.Ident::new("b"), Some(@ast.Ident::new("bb"))),
  ]
  let path = @ast.UsePath::new([@ast.Ident::new("m")], @ast.Group(items))
  let item : @ast.Item = @ast.Use(@ast.UseDecl::new(path))
  let prog = @ast.Program::new([spanned(item)])
  assert_eq(format(prog, cfg), "use m::{ a, b as bb }\n")
}

///|
test "array pattern with rest formats in let binding" {
  let pat : @ast.Pattern = @ast.Array(
    @ast.ArrayPattern::new(
      [
        spanned(@ast.Pattern::Ident(@ast.Ident::new("head"))),
        spanned(@ast.Pattern::Literal(@ast.LiteralPattern::Integer(1L))),
      ],
      Some(spanned(@ast.Pattern::Ident(@ast.Ident::new("tail")))),
    ),
  )
  let b = @ast.LetBinding::new(spanned(pat), None, spanned(@ast.Expr::Ident(@ast.Ident::new("xs"))))
  let prog = @ast.Program::new([spanned(@ast.Item::LetBinding(b))])
  assert_eq(format(prog, cfg), "let [head, 1, ...tail] = xs\n")
}

///|
test "constructor and tuple patterns format recursively" {
  let inner : @ast.Pattern = @ast.Tuple([
    spanned(@ast.Pattern::Ident(@ast.Ident::new("x"))),
    spanned(@ast.Pattern::Literal(@ast.LiteralPattern::BoolLit(true))),
  ])
  let pat : @ast.Pattern = @ast.Constructor(
    name=@ast.Ident::new("Some"),
    args=[spanned(inner)],
  )
  let b = @ast.LetBinding::new(spanned(pat), None, spanned(@ast.Expr::Integer(1L)))
  let prog = @ast.Program::new([spanned(@ast.Item::LetBinding(b))])
  assert_eq(format(prog, cfg), "let Some((x, true)) = 1\n")
}

///|
test "composite type annotation formats on let binding" {
  let ty : @ast.TypeAnnotation = @ast.Function(
    @ast.Generic(@ast.Ident::new("List"), [
      @ast.Tuple([
        @ast.Named(@ast.Ident::new("Int")),
        @ast.Array(@ast.Var(@ast.Ident::new("a"))),
      ]),
    ]),
    @ast.Unit,
  )
  let b = @ast.LetBinding::new(
    spanned(@ast.Pattern::Ident(@ast.Ident::new("f"))),
    Some(ty),
    spanned(@ast.Expr::UnitLit),
  )
  let prog = @ast.Program::new([spanned(@ast.Item::LetBinding(b))])
  assert_eq(format(prog, cfg), "let f : List<(Int, ['a])> -> () = ()\n")
}
