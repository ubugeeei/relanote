///|
/// Pretty printer for the relanote AST. Walks a `Program` and writes
/// canonical source into the formatter's buffer.
///
/// This is a *real* walker — every common construct (let bindings,
/// scale / chord / synth declarations, expressions, blocks, pitches,
/// patterns, type annotations) round-trips through it. A handful of
/// the new sound-design declarations (`tuning`, `groove`, `effect`,
/// `mix`) emit a TODO comment because their concrete syntax is still
/// settling — they parse but don't yet have a stable printed form.
pub struct Formatter {
  config : FormatConfig
  output : StringBuilder
  mut indent_level : Int
}

///|
pub fn Formatter::new(config : FormatConfig) -> Formatter {
  { config, output: StringBuilder::new(), indent_level: 0 }
}

///|
pub fn Formatter::config(self : Formatter) -> FormatConfig {
  self.config
}

///|
pub fn Formatter::format_program(
  self : Formatter,
  program : @ast.Program,
) -> String {
  let items = program.items()
  let mut i = 0
  while i < items.length() {
    if i > 0 {
      self.write("\n")
    }
    self.format_item(items[i].node())
    self.write("\n")
    i += 1
  }
  self.output.to_string()
}

// ============================================================
// Buffer helpers
// ============================================================

///|
fn Formatter::write(self : Formatter, s : String) -> Unit {
  self.output.write_string(s)
}

///|
fn Formatter::write_indent(self : Formatter) -> Unit {
  let mut i = 0
  let spaces = self.config.indent_size()
  while i < self.indent_level * spaces {
    self.output.write_char(' ')
    i += 1
  }
}

// ============================================================
// Item — top-level declarations
// ============================================================

///|
fn Formatter::format_item(self : Formatter, item : @ast.Item) -> Unit {
  match item {
    @ast.ScaleDef(s) => self.format_scale_def(s)
    @ast.ChordDef(c) => self.format_chord_def(c)
    @ast.SynthDef(s) => self.format_synth_def(s)
    @ast.LetBinding(b) => self.format_let_binding(b)
    @ast.SetBinding(s) => self.format_set_binding(s)
    @ast.FunctionDef(f) => self.format_function_def(f)
    @ast.Import(decl) => self.format_import(decl)
    @ast.Export(_) => self.write("; <export omitted by formatter>\n")
    @ast.Mod(m) => {
      self.write("mod ")
      self.write(m.name().name())
    }
    @ast.Use(_) => self.write("; <use omitted by formatter>\n")
    @ast.ExprStmt(e) => self.format_expr(e.node())
    @ast.TuningDef(_) => self.write("; <tuning declaration — see guide/microtones>")
    @ast.GrooveDef(_) => self.write("; <groove declaration — see guide/rhythm>")
    @ast.EffectDef(_) => self.write("; <effect declaration — see guide/mixing>")
    @ast.MixDef(_) => self.write("; <mix block — see guide/mixing>")
  }
}

///|
fn Formatter::format_scale_def(self : Formatter, s : @ast.ScaleDef) -> Unit {
  self.write("scale ")
  self.write(s.name().name())
  self.write(" = { ")
  let intervals = s.intervals()
  let mut i = 0
  while i < intervals.length() {
    if i > 0 {
      self.write(", ")
    }
    self.format_interval(intervals[i].node())
    i += 1
  }
  self.write(" }")
}

///|
fn Formatter::format_chord_def(self : Formatter, c : @ast.ChordDef) -> Unit {
  self.write("chord ")
  self.write(c.name().name())
  self.write(" = [ ")
  let intervals = c.intervals()
  let mut i = 0
  while i < intervals.length() {
    if i > 0 {
      self.write(", ")
    }
    self.format_interval(intervals[i].node())
    i += 1
  }
  self.write(" ]")
}

///|
fn Formatter::format_synth_def(self : Formatter, s : @ast.SynthDef) -> Unit {
  self.write("synth ")
  self.write(s.name().name())
  self.write(" = { ")
  // The body of a synth is a list of `SynthProperty` values; their
  // printable form is whatever's inside the spanned `Expr`. We delegate
  // to `format_expr` for each so the formatter doesn't need to know the
  // synth's surface in detail.
  let props = s.properties()
  let mut i = 0
  while i < props.length() {
    if i > 0 {
      self.write(", ")
    }
    match props[i].node() {
      @ast.Oscillator(e) => {
        self.write("osc: ")
        self.format_expr(e.node())
      }
      @ast.Envelope(e) => {
        self.write("env: ")
        self.format_expr(e.node())
      }
      @ast.Filter(e) => {
        self.write("filter: ")
        self.format_expr(e.node())
      }
      @ast.Detune(e) => {
        self.write("detune: ")
        self.format_expr(e.node())
      }
      @ast.PitchEnvelope(e) => {
        self.write("pitch_env: ")
        self.format_expr(e.node())
      }
    }
    i += 1
  }
  self.write(" }")
}

///|
fn Formatter::format_let_binding(
  self : Formatter,
  b : @ast.LetBinding,
) -> Unit {
  self.write("let ")
  self.format_pattern(b.pattern().node())
  match b.type_ann() {
    Some(t) => {
      self.write(" : ")
      self.format_type(t)
    }
    None => ()
  }
  self.write(" = ")
  self.format_expr(b.value().node())
}

///|
fn Formatter::format_set_binding(
  self : Formatter,
  s : @ast.SetBinding,
) -> Unit {
  self.write("set ")
  self.write(s.name().name())
  self.write(" = ")
  self.format_expr(s.value().node())
}

///|
/// Format an `import` declaration so it round-trips through the parser.
///
/// - A single named/aliased item or wildcard renders bare:
///   `import foo from "m"`, `import foo as f from "m"`,
///   `import * from "m"`, `import * as M from "m"`.
/// - Multiple named/aliased items render as a brace-group:
///   `import { a, b as bb } from "m"`. This differs from the Rust
///   crate's implementation, which emits `a, b` without braces — that
///   form is rejected by both parsers, so we use the brace shape that
///   actually round-trips.
fn Formatter::format_import(
  self : Formatter,
  decl : @ast.ImportDecl,
) -> Unit {
  let items = decl.items()
  self.write("import ")
  let write_item = fn (item : @ast.ImportItem) {
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
fn Formatter::format_expr(self : Formatter, expr : @ast.Expr) -> Unit {
  match expr {
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
fn Formatter::format_interval(
  self : Formatter,
  iv : @ast.IntervalLit,
) -> Unit {
  let q = match iv.quality() {
    @lexer.Major => "M"
    @lexer.Minor => "m"
    @lexer.Perfect => "P"
    @lexer.Diminished => "d"
    @lexer.Augmented => "A"
  }
  self.write(q)
  self.write(iv.degree().to_string())
  for a in iv.accidentals() {
    self.write(
      match a {
        @lexer.Sharp => "+"
        @lexer.Flat => "-"
      },
    )
  }
}

///|
fn Formatter::format_absolute_pitch(
  self : Formatter,
  ap : @ast.AbsolutePitchLit,
) -> Unit {
  self.write(ap.note().to_string())
  if ap.accidental() > 0 {
    self.write("#")
  } else if ap.accidental() < 0 {
    self.write("b")
  }
  self.write(ap.octave().to_string())
}

///|
fn Formatter::format_pitch(self : Formatter, p : @ast.Pitch) -> Unit {
  match p {
    @ast.Interval(iv) => self.format_interval(iv)
    @ast.ScaleIndex(n) => {
      self.write("<")
      self.write(n.to_string())
      self.write(">")
    }
    @ast.ScaleIndexMod(n, acc) => {
      self.write("<")
      self.write(n.to_string())
      for a in acc {
        self.write(
          match a {
            @lexer.Sharp => "+"
            @lexer.Flat => "-"
          },
        )
      }
      self.write(">")
    }
    @ast.Microtone(cents) => {
      let sign = if cents >= 0.0 { "+" } else { "" }
      self.write(sign)
      self.write(cents.to_string())
      self.write("c")
    }
    @ast.MicrotonalInterval(iv, cents) => {
      self.format_interval(iv)
      self.write(" ")
      let sign = if cents >= 0.0 { "+" } else { "" }
      self.write(sign)
      self.write(cents.to_string())
      self.write("c")
    }
    @ast.ScaleIndexCents(n, cents) => {
      self.write("<")
      self.write(n.to_string())
      self.write(" ")
      let sign = if cents >= 0.0 { "+" } else { "" }
      self.write(sign)
      self.write(cents.to_string())
      self.write("c>")
    }
    @ast.Root => self.write("R")
  }
}

///|
fn Formatter::format_slot(self : Formatter, slot : @ast.Slot) -> Unit {
  match slot {
    @ast.Note(pitch~, articulations~, duration~) => {
      self.format_pitch(pitch.node())
      for a in articulations {
        self.write(
          match a {
            @ast.Staccato => "*"
            @ast.Accent => "^"
            @ast.Portamento => "~"
          },
        )
      }
      match duration {
        Some(d) => {
          self.write(":")
          self.write(d.to_string())
        }
        None => ()
      }
    }
    @ast.Rest(duration~) => {
      self.write("-")
      match duration {
        Some(d) => {
          self.write(":")
          self.write(d.to_string())
        }
        None => ()
      }
    }
    @ast.Chord(pitches~, articulations~, duration~) => {
      self.write("[")
      let mut i = 0
      while i < pitches.length() {
        if i > 0 {
          self.write(" ")
        }
        self.format_pitch(pitches[i].node())
        i += 1
      }
      self.write("]")
      for a in articulations {
        self.write(
          match a {
            @ast.Staccato => "*"
            @ast.Accent => "^"
            @ast.Portamento => "~"
          },
        )
      }
      match duration {
        Some(d) => {
          self.write(":")
          self.write(d.to_string())
        }
        None => ()
      }
    }
    @ast.Tuplet(t) => self.format_tuplet(t)
  }
}

///|
fn Formatter::format_block(self : Formatter, b : @ast.Block) -> Unit {
  self.write("| ")
  let mut i = 0
  while i < b.slots().length() {
    if i > 0 {
      self.write(" ")
    }
    self.format_slot(b.slots()[i].node())
    i += 1
  }
  self.write(" |")
  match b.beats() {
    Some(beats) => {
      self.write(":")
      self.write(beats.to_string())
    }
    None => ()
  }
}

///|
fn Formatter::format_tuplet(self : Formatter, t : @ast.Tuplet) -> Unit {
  self.write("{ ")
  let mut i = 0
  while i < t.contents().length() {
    if i > 0 {
      self.write(" ")
    }
    self.format_slot(t.contents()[i].node())
    i += 1
  }
  self.write(" }:")
  self.format_expr(t.target_beats().node())
}

///|
fn Formatter::format_envelope(
  self : Formatter,
  e : @ast.EnvelopeLit,
) -> Unit {
  self.write("env(")
  self.format_expr(e.from().node())
  self.write(", ")
  self.format_expr(e.to().node())
  self.write(", ")
  self.format_expr(e.duration().node())
  self.write(")")
}

// ============================================================
// Part / Section / Layer
// ============================================================

///|
fn Formatter::format_part(self : Formatter, p : @ast.PartExpr) -> Unit {
  self.write("part ")
  self.format_expr(p.instrument().node())
  match p.body() {
    Some(b) => {
      self.write(" { ")
      self.format_expr(b.node())
      self.write(" }")
    }
    None => ()
  }
}

///|
fn Formatter::format_section(
  self : Formatter,
  s : @ast.SectionExpr,
) -> Unit {
  self.write("section ")
  self.format_expr(s.name().node())
  self.write(" { ")
  self.format_expr(s.body().node())
  self.write(" }")
}

///|
fn Formatter::format_layer(self : Formatter, l : @ast.LayerExpr) -> Unit {
  self.write("layer [")
  let mut i = 0
  while i < l.parts().length() {
    if i > 0 {
      self.write(", ")
    }
    self.format_expr(l.parts()[i].node())
    i += 1
  }
  self.write("]")
}

// ============================================================
// Pattern
// ============================================================

///|
fn Formatter::format_pattern(
  self : Formatter,
  p : @ast.Pattern,
) -> Unit {
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
fn Formatter::format_type(
  self : Formatter,
  t : @ast.TypeAnnotation,
) -> Unit {
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
/// `relanote_format::format` in the Rust crate.
pub fn format(program : @ast.Program, config : FormatConfig) -> String {
  Formatter::new(config).format_program(program)
}
