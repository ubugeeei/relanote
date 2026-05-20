///|
fn Formatter::format_expr(self : Formatter, expr : @ast.Expr) -> Unit {
  match expr {
    @ast.Integer(n) => self.write(n.to_string())
    @ast.Float(f) => self.write(f.to_string())
    @ast.StringLit(s) => {
      self.write("\"")
      self.write(s)
      self.write("\"")
    }
    @ast.BoolLit(b) => if b { self.write("true") } else { self.write("false") }
    @ast.UnitLit => self.write("()")
    @ast.Ident(id) => self.write(id.name())
    @ast.Root => self.write("R")
    @ast.Interval(iv) => self.format_interval(iv)
    @ast.AbsolutePitch(ap) => self.format_absolute_pitch(ap)
    @ast.Articulation(a) =>
      self.write(
        match a {
          @ast.Staccato => "*"
          @ast.Accent => "^"
          @ast.Portamento => "~"
        },
      )
    @ast.Block(b) => self.format_block(b)
    @ast.Tuplet(t) => self.format_tuplet(t)
    @ast.Envelope(e) => self.format_envelope(e)
    @ast.Part(p) => self.format_part(p)
    @ast.Section(s) => self.format_section(s)
    @ast.Layer(l) => self.format_layer(l)
    @ast.Lambda(l) => self.format_lambda(l)
    @ast.Application(a) => self.format_application(a)
    @ast.Pipe(p) => {
      self.format_expr(p.left().node())
      self.write(" |> ")
      self.format_expr(p.right().node())
    }
    @ast.Array(xs) => {
      self.write("[")
      let mut i = 0
      while i < xs.length() {
        if i > 0 {
          self.write(", ")
        }
        self.format_expr(xs[i].node())
        i += 1
      }
      self.write("]")
    }
    @ast.Tuple(xs) => {
      self.write("(")
      let mut i = 0
      while i < xs.length() {
        if i > 0 {
          self.write(", ")
        }
        self.format_expr(xs[i].node())
        i += 1
      }
      self.write(")")
    }
    @ast.Binary(b) => self.format_binary(b)
    @ast.Unary(u) => self.format_unary(u)
    @ast.Index(idx) => {
      self.format_expr(idx.base().node())
      self.write("[")
      self.format_expr(idx.index().node())
      self.write("]")
    }
    @ast.Field(f) => {
      self.format_expr(f.base().node())
      self.write(".")
      self.write(f.field().name())
    }
    @ast.If(ie) => self.format_if(ie)
    @ast.Match(me) => self.format_match(me)
    @ast.Let(le) => {
      self.write("let ")
      self.format_pattern(le.pattern().node())
      self.write(" = ")
      self.format_expr(le.value().node())
      self.write(" in ")
      self.format_expr(le.body().node())
    }
    @ast.With(w) => {
      self.format_expr(w.base().node())
      self.write(" with { ")
      for m in w.modifications() {
        self.format_expr(m.node())
      }
      self.write(" }")
    }
    @ast.InScale(ise) => {
      self.write("in ")
      self.format_expr(ise.scale().node())
    }
    @ast.Annotated(inner, ty) => {
      self.format_expr(inner.node())
      self.write(" : ")
      self.format_type(ty)
    }
    @ast.Paren(inner) => {
      self.write("(")
      self.format_expr(inner.node())
      self.write(")")
    }
    @ast.Over(left, right) => {
      self.format_expr(left.node())
      self.write(" over ")
      self.format_expr(right.node())
    }
    @ast.Error => self.write("<error>")
  }
}

///|
fn Formatter::format_binary(self : Formatter, b : @ast.Binary) -> Unit {
  self.format_expr(b.left().node())
  let op = match b.op() {
    @ast.Add => "+"
    @ast.Sub => "-"
    @ast.Mul => "*"
    @ast.Div => "/"
    @ast.Mod => "%"
    @ast.EqOp => "=="
    @ast.NeOp => "!="
    @ast.Lt => "<"
    @ast.Le => "<="
    @ast.Gt => ">"
    @ast.Ge => ">="
    @ast.And => "and"
    @ast.Or => "or"
    @ast.Concat => "++"
    @ast.Compose => ">>"
  }
  self.write(" ")
  self.write(op)
  self.write(" ")
  self.format_expr(b.right().node())
}

///|
fn Formatter::format_unary(self : Formatter, u : @ast.Unary) -> Unit {
  let op = match u.op() {
    @ast.Neg => "-"
    @ast.Not => "not "
  }
  self.write(op)
  self.format_expr(u.operand().node())
}

///|
fn Formatter::format_application(
  self : Formatter,
  a : @ast.Application,
) -> Unit {
  self.format_expr(a.func().node())
  self.write("(")
  let mut i = 0
  while i < a.args().length() {
    if i > 0 {
      self.write(", ")
    }
    self.format_expr(a.args()[i].node())
    i += 1
  }
  self.write(")")
}

///|
fn Formatter::format_lambda(self : Formatter, l : @ast.Lambda) -> Unit {
  self.write("\\")
  let mut i = 0
  while i < l.params().length() {
    if i > 0 {
      self.write(" ")
    }
    self.format_pattern(l.params()[i].node())
    i += 1
  }
  self.write(" -> ")
  self.format_expr(l.body().node())
}

///|
fn Formatter::format_if(self : Formatter, ie : @ast.IfExpr) -> Unit {
  self.write("if ")
  self.format_expr(ie.condition().node())
  self.write(" then ")
  self.format_expr(ie.then_branch().node())
  match ie.else_branch() {
    Some(e) => {
      self.write(" else ")
      self.format_expr(e.node())
    }
    None => ()
  }
}

///|
fn Formatter::format_match(self : Formatter, me : @ast.MatchExpr) -> Unit {
  self.write("match ")
  self.format_expr(me.scrutinee().node())
  self.write(" {\n")
  self.indent_level += 1
  for arm in me.arms() {
    self.write_indent()
    self.format_pattern(arm.pattern().node())
    match arm.guard_expr() {
      Some(g) => {
        self.write(" if ")
        self.format_expr(g.node())
      }
      None => ()
    }
    self.write(" => ")
    self.format_expr(arm.body().node())
    self.write("\n")
  }
  self.indent_level -= 1
  self.write_indent()
  self.write("}")
}

// ============================================================
// Music primitives
// ============================================================

///|
