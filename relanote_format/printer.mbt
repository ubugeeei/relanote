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
    @ast.Export(decl) => self.format_export(decl)
    @ast.Mod(m) => {
      self.write("mod ")
      self.write(m.name().name())
    }
    @ast.Use(decl) => self.format_use(decl)
    @ast.ExprStmt(e) => self.format_expr(e.node())
    @ast.TuningDef(_) =>
      self.write("; <tuning declaration — see guide/microtones>")
    @ast.GrooveDef(_) =>
      self.write("; <groove declaration — see guide/rhythm>")
    @ast.EffectDef(_) =>
      self.write("; <effect declaration — see guide/mixing>")
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
fn Formatter::format_let_binding(self : Formatter, b : @ast.LetBinding) -> Unit {
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
fn Formatter::format_set_binding(self : Formatter, s : @ast.SetBinding) -> Unit {
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
///   `import { a, b as bb } from "m"`. This differs from the legacy
///   crate's implementation, which emits `a, b` without braces — that
///   form is rejected by both parsers, so we use the brace shape that
///   actually round-trips.
