///|
/// Severity of a diagnostic.
pub(all) enum DiagnosticKind {
  Error
  Warning
  Info
  Hint
} derive(Eq)

///|
pub fn DiagnosticKind::is_error(self : DiagnosticKind) -> Bool {
  match self {
    Error => true
    _ => false
  }
}

///|
pub fn DiagnosticKind::to_display_string(self : DiagnosticKind) -> String {
  match self {
    Error => "error"
    Warning => "warning"
    Info => "info"
    Hint => "hint"
  }
}

///|
/// Secondary label hanging off a `Diagnostic`.
pub struct Label {
  span : Span
  message : String
}

///|
pub fn Label::new(span : Span, message : String) -> Label {
  { span, message }
}

///|
pub fn Label::span(self : Label) -> Span {
  self.span
}

///|
pub fn Label::message(self : Label) -> String {
  self.message
}

///|
/// A single diagnostic message — kind + span + free-form message + any
/// number of `Label`s and free-form notes.
pub struct Diagnostic {
  kind : DiagnosticKind
  message : String
  span : Span
  labels : Array[Label]
  notes : Array[String]
}

///|
pub fn Diagnostic::error(message : String, span : Span) -> Diagnostic {
  { kind: Error, message, span, labels: [], notes: [] }
}

///|
pub fn Diagnostic::warning(message : String, span : Span) -> Diagnostic {
  { kind: Warning, message, span, labels: [], notes: [] }
}

///|
pub fn Diagnostic::with_label(
  self : Diagnostic,
  span : Span,
  message : String,
) -> Diagnostic {
  self.labels.push(Label::new(span, message))
  self
}

///|
pub fn Diagnostic::with_note(self : Diagnostic, note : String) -> Diagnostic {
  self.notes.push(note)
  self
}

///|
pub fn Diagnostic::kind(self : Diagnostic) -> DiagnosticKind {
  self.kind
}

///|
pub fn Diagnostic::message(self : Diagnostic) -> String {
  self.message
}

///|
pub fn Diagnostic::span(self : Diagnostic) -> Span {
  self.span
}

///|
pub fn Diagnostic::labels(self : Diagnostic) -> Array[Label] {
  self.labels
}

///|
pub fn Diagnostic::notes(self : Diagnostic) -> Array[String] {
  self.notes
}

///|
pub fn Diagnostic::is_error(self : Diagnostic) -> Bool {
  self.kind.is_error()
}

///|
/// A growing collection of diagnostics — the parser, type checker, etc.
/// all hand back one of these so the caller can decide how to render.
pub struct Diagnostics {
  items : Array[Diagnostic]
}

///|
pub fn Diagnostics::new() -> Diagnostics {
  { items: [] }
}

///|
pub fn Diagnostics::add(self : Diagnostics, diagnostic : Diagnostic) -> Unit {
  self.items.push(diagnostic)
}

///|
pub fn Diagnostics::error(
  self : Diagnostics,
  message : String,
  span : Span,
) -> Unit {
  self.add(Diagnostic::error(message, span))
}

///|
pub fn Diagnostics::warning(
  self : Diagnostics,
  message : String,
  span : Span,
) -> Unit {
  self.add(Diagnostic::warning(message, span))
}

///|
pub fn Diagnostics::has_errors(self : Diagnostics) -> Bool {
  for d in self.items {
    if d.is_error() {
      return true
    }
  }
  false
}

///|
pub fn Diagnostics::is_empty(self : Diagnostics) -> Bool {
  self.items.length() == 0
}

///|
pub fn Diagnostics::length(self : Diagnostics) -> Int {
  self.items.length()
}

///|
pub fn Diagnostics::items(self : Diagnostics) -> Array[Diagnostic] {
  self.items
}

///|
pub fn Diagnostics::error_count(self : Diagnostics) -> Int {
  let mut count = 0
  for d in self.items {
    if d.is_error() {
      count += 1
    }
  }
  count
}

///|
pub fn Diagnostics::merge(self : Diagnostics, other : Diagnostics) -> Unit {
  for d in other.items {
    self.items.push(d)
  }
}
