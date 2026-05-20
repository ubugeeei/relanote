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
