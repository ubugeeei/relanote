///|
fn Formatter::format_import(self : Formatter, decl : @ast.ImportDecl) -> Unit {
  let items = decl.items()
  self.write("import ")
  let write_item = fn(item : @ast.ImportItem) {
    match item {
      @ast.Named(id) => self.write(id.name())
      @ast.Aliased(name~, as_name~) => {
        self.write(name.name())
        self.write(" as ")
        self.write(as_name.name())
      }
      @ast.All => self.write("*")
      @ast.AllAliased(as_ident) => {
        self.write("* as ")
        self.write(as_ident.name())
      }
    }
  }
  if items.length() == 1 {
    write_item(items[0])
  } else {
    self.write("{ ")
    let mut i = 0
    while i < items.length() {
      if i > 0 {
        self.write(", ")
      }
      write_item(items[i])
      i += 1
    }
    self.write(" }")
  }
  self.write(" from \"")
  self.write(decl.from())
  self.write("\"")
}

///|
/// Format an `export` declaration. Three shapes:
/// - `export name1, name2` (a `Named` list).
/// - `export <inner-item>` (an inline definition).
/// - `export { name1, name2 } from "module"` (a re-export).
fn Formatter::format_export(self : Formatter, decl : @ast.ExportDecl) -> Unit {
  self.write("export ")
  match decl {
    @ast.Named(items) => {
      let mut i = 0
      while i < items.length() {
        if i > 0 {
          self.write(", ")
        }
        self.write(items[i].name())
        i += 1
      }
    }
    @ast.Definition(item) => self.format_item(item)
    @ast.ReExport(items~, from~) => {
      self.write("{ ")
      let mut i = 0
      while i < items.length() {
        if i > 0 {
          self.write(", ")
        }
        self.write(items[i].name())
        i += 1
      }
      self.write(" } from \"")
      self.write(from)
      self.write("\"")
    }
  }
}

///|
/// Format a `use` declaration. Three shapes per the AST's `UseKind`:
/// - `use a::b::c` (Simple).
/// - `use a::b::*` (Glob).
/// - `use a::b::{ c, d as e }` (Group).
fn Formatter::format_use(self : Formatter, decl : @ast.UseDecl) -> Unit {
  let path = decl.path()
  self.write("use ")
  let segments = path.segments()
  let mut i = 0
  while i < segments.length() {
    if i > 0 {
      self.write("::")
    }
    self.write(segments[i].name())
    i += 1
  }
  match path.kind() {
    @ast.Simple => ()
    @ast.Glob => self.write("::*")
    @ast.Group(items) => {
      self.write("::{ ")
      let mut k = 0
      while k < items.length() {
        if k > 0 {
          self.write(", ")
        }
        self.write(items[k].name().name())
        match items[k].as_name() {
          Some(import_alias) => {
            self.write(" as ")
            self.write(import_alias.name())
          }
          None => ()
        }
        k += 1
      }
      self.write(" }")
    }
  }
}

///|
fn Formatter::format_function_def(
  self : Formatter,
  f : @ast.FunctionDef,
) -> Unit {
  self.write("let ")
  self.write(f.name().name())
  for p in f.params() {
    self.write(" ")
    self.format_pattern(p.node())
  }
  match f.return_type() {
    Some(t) => {
      self.write(" : ")
      self.format_type(t)
    }
    None => ()
  }
  self.write(" = ")
  self.format_expr(f.body().node())
}

// ============================================================
// Expr
// ============================================================

///|
