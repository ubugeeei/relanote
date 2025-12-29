//! Evaluation errors

use relanote_core::Span;
use thiserror::Error;

#[derive(Debug, Error, Clone)]
pub enum EvalError {
    #[error("undefined variable: {name}")]
    UndefinedVariable { name: String, span: Span },

    #[error("type error: expected {expected}, found {found}")]
    TypeError {
        expected: String,
        found: String,
        span: Span,
    },

    #[error("division by zero")]
    DivisionByZero { span: Span },

    #[error("index out of bounds: {index} in array of length {len}")]
    IndexOutOfBounds { index: i64, len: usize, span: Span },

    #[error("not a function")]
    NotAFunction { span: Span },

    #[error("wrong number of arguments: expected {expected}, got {got}")]
    WrongArity {
        expected: usize,
        got: usize,
        span: Span,
    },

    #[error("module not found: {module} at {path}: {reason}")]
    ModuleNotFound {
        module: String,
        path: String,
        reason: String,
    },

    #[error("circular module dependency: {module}")]
    CircularModuleDependency { module: String },

    #[error("{message}")]
    Custom { message: String, span: Span },
}

impl EvalError {
    pub fn span(&self) -> Option<Span> {
        match self {
            EvalError::UndefinedVariable { span, .. } => Some(*span),
            EvalError::TypeError { span, .. } => Some(*span),
            EvalError::DivisionByZero { span } => Some(*span),
            EvalError::IndexOutOfBounds { span, .. } => Some(*span),
            EvalError::NotAFunction { span } => Some(*span),
            EvalError::WrongArity { span, .. } => Some(*span),
            EvalError::ModuleNotFound { .. } => None,
            EvalError::CircularModuleDependency { .. } => None,
            EvalError::Custom { span, .. } => Some(*span),
        }
    }
}
