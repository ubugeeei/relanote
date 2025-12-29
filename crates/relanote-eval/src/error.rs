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

    #[error("{message}")]
    Custom { message: String, span: Span },
}

impl EvalError {
    pub fn span(&self) -> Span {
        match self {
            EvalError::UndefinedVariable { span, .. } => *span,
            EvalError::TypeError { span, .. } => *span,
            EvalError::DivisionByZero { span } => *span,
            EvalError::IndexOutOfBounds { span, .. } => *span,
            EvalError::NotAFunction { span } => *span,
            EvalError::WrongArity { span, .. } => *span,
            EvalError::Custom { span, .. } => *span,
        }
    }
}
