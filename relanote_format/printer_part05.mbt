///|
fn Formatter::format_pattern(self : Formatter, p : @ast.Pattern) -> Unit {
  match p {
    @ast.Wildcard => self.write("_")
    @ast.Ident(id) => self.write(id.name())
    @ast.Literal(lit) =>
      match lit {
        @ast.Integer(n) => self.write(n.to_string())
        @ast.Float(f) => self.write(f.to_string())
        @ast.StringLit(s) => {
          self.write("\"")
          self.write(s)
          self.write("\"")
        }
        @ast.BoolLit(b) =>
          if b {
            self.write("true")
          } else {
            self.write("false")
          }
        @ast.UnitLit => self.write("()")
      }
    @ast.Tuple(elems) => {
      self.write("(")
      let mut i = 0
      while i < elems.length() {
        if i > 0 {
          self.write(", ")
        }
        self.format_pattern(elems[i].node())
        i += 1
      }
      self.write(")")
    }
    @ast.Array(ap) => {
      self.write("[")
      let mut i = 0
      while i < ap.elements().length() {
        if i > 0 {
          self.write(", ")
        }
        self.format_pattern(ap.elements()[i].node())
        i += 1
      }
      match ap.rest() {
        Some(r) => {
          if ap.elements().length() > 0 {
            self.write(", ")
          }
          self.write("...")
          self.format_pattern(r.node())
        }
        None => ()
      }
      self.write("]")
    }
    @ast.Constructor(name~, args~) => {
      self.write(name.name())
      if args.length() > 0 {
        self.write("(")
        let mut i = 0
        while i < args.length() {
          if i > 0 {
            self.write(", ")
          }
          self.format_pattern(args[i].node())
          i += 1
        }
        self.write(")")
      }
    }
    @ast.Or(a, b) => {
      self.format_pattern(a.node())
      self.write(" | ")
      self.format_pattern(b.node())
    }
    @ast.Annotated(inner, ty) => {
      self.format_pattern(inner.node())
      self.write(" : ")
      self.format_type(ty)
    }
  }
}

// ============================================================
// TypeAnnotation
// ============================================================

///|
fn Formatter::format_type(self : Formatter, t : @ast.TypeAnnotation) -> Unit {
  match t {
    @ast.Named(id) => self.write(id.name())
    @ast.Generic(name, args) => {
      self.write(name.name())
      self.write("<")
      let mut i = 0
      while i < args.length() {
        if i > 0 {
          self.write(", ")
        }
        self.format_type(args[i])
        i += 1
      }
      self.write(">")
    }
    @ast.Function(a, b) => {
      self.format_type(a)
      self.write(" -> ")
      self.format_type(b)
    }
    @ast.Tuple(elems) => {
      self.write("(")
      let mut i = 0
      while i < elems.length() {
        if i > 0 {
          self.write(", ")
        }
        self.format_type(elems[i])
        i += 1
      }
      self.write(")")
    }
    @ast.Array(elem) => {
      self.write("[")
      self.format_type(elem)
      self.write("]")
    }
    @ast.Unit => self.write("()")
    @ast.Var(id) => {
      self.write("'")
      self.write(id.name())
    }
  }
}

// ============================================================
// Top-level convenience
// ============================================================

///|
/// Format an entire program into a string. Mirrors
/// `relanote_format::format` in the legacy implementation.
pub fn format(program : @ast.Program, config : FormatConfig) -> String {
  Formatter::new(config).format_program(program)
}

///|
/// Format a single spanned top-level item — useful for incremental
/// printing in the LSP. The item's own span is discarded; only its
/// inner node is rendered.
pub fn format_spanned_item(
  item : @core.Spanned[@ast.Item],
  config : FormatConfig,
) -> String {
  let f = Formatter::new(config)
  f.format_item(item.node())
  f.output.to_string()
}
