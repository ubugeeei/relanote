use std::fmt;

use crate::span::Span;

/// Severity of a diagnostic
#[derive(Clone, Copy, Debug, PartialEq, Eq, Hash)]
pub enum DiagnosticKind {
    Error,
    Warning,
    Info,
    Hint,
}

impl DiagnosticKind {
    pub fn is_error(&self) -> bool {
        matches!(self, DiagnosticKind::Error)
    }
}

impl fmt::Display for DiagnosticKind {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        match self {
            DiagnosticKind::Error => write!(f, "error"),
            DiagnosticKind::Warning => write!(f, "warning"),
            DiagnosticKind::Info => write!(f, "info"),
            DiagnosticKind::Hint => write!(f, "hint"),
        }
    }
}

/// A secondary label for a diagnostic
#[derive(Clone, Debug)]
pub struct Label {
    pub span: Span,
    pub message: String,
}

impl Label {
    pub fn new(span: Span, message: impl Into<String>) -> Self {
        Self {
            span,
            message: message.into(),
        }
    }
}

/// A diagnostic message
#[derive(Clone, Debug)]
pub struct Diagnostic {
    pub kind: DiagnosticKind,
    pub message: String,
    pub span: Span,
    pub labels: Vec<Label>,
    pub notes: Vec<String>,
}

impl Diagnostic {
    pub fn error(message: impl Into<String>, span: Span) -> Self {
        Self {
            kind: DiagnosticKind::Error,
            message: message.into(),
            span,
            labels: Vec::new(),
            notes: Vec::new(),
        }
    }

    pub fn warning(message: impl Into<String>, span: Span) -> Self {
        Self {
            kind: DiagnosticKind::Warning,
            message: message.into(),
            span,
            labels: Vec::new(),
            notes: Vec::new(),
        }
    }

    pub fn with_label(mut self, span: Span, message: impl Into<String>) -> Self {
        self.labels.push(Label::new(span, message));
        self
    }

    pub fn with_note(mut self, note: impl Into<String>) -> Self {
        self.notes.push(note.into());
        self
    }

    pub fn is_error(&self) -> bool {
        self.kind.is_error()
    }
}

/// Collection of diagnostics
#[derive(Clone, Debug, Default)]
pub struct Diagnostics {
    diagnostics: Vec<Diagnostic>,
}

impl Diagnostics {
    pub fn new() -> Self {
        Self::default()
    }

    pub fn add(&mut self, diagnostic: Diagnostic) {
        self.diagnostics.push(diagnostic);
    }

    pub fn error(&mut self, message: impl Into<String>, span: Span) {
        self.add(Diagnostic::error(message, span));
    }

    pub fn warning(&mut self, message: impl Into<String>, span: Span) {
        self.add(Diagnostic::warning(message, span));
    }

    pub fn has_errors(&self) -> bool {
        self.diagnostics.iter().any(|d| d.is_error())
    }

    pub fn is_empty(&self) -> bool {
        self.diagnostics.is_empty()
    }

    pub fn len(&self) -> usize {
        self.diagnostics.len()
    }

    pub fn iter(&self) -> impl Iterator<Item = &Diagnostic> {
        self.diagnostics.iter()
    }

    pub fn errors(&self) -> impl Iterator<Item = &Diagnostic> {
        self.diagnostics.iter().filter(|d| d.is_error())
    }

    pub fn error_count(&self) -> usize {
        self.diagnostics.iter().filter(|d| d.is_error()).count()
    }

    pub fn merge(&mut self, other: Diagnostics) {
        self.diagnostics.extend(other.diagnostics);
    }
}

impl IntoIterator for Diagnostics {
    type Item = Diagnostic;
    type IntoIter = std::vec::IntoIter<Diagnostic>;

    fn into_iter(self) -> Self::IntoIter {
        self.diagnostics.into_iter()
    }
}

impl<'a> IntoIterator for &'a Diagnostics {
    type Item = &'a Diagnostic;
    type IntoIter = std::slice::Iter<'a, Diagnostic>;

    fn into_iter(self) -> Self::IntoIter {
        self.diagnostics.iter()
    }
}

impl Extend<Diagnostic> for Diagnostics {
    fn extend<T: IntoIterator<Item = Diagnostic>>(&mut self, iter: T) {
        self.diagnostics.extend(iter);
    }
}
