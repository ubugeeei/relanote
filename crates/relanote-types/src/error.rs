use relanote_core::Span;
use thiserror::Error;

use crate::types::Type;

#[derive(Debug, Error, Clone)]
pub enum TypeError {
    #[error("type mismatch: expected {expected:?}, found {found:?}")]
    Mismatch {
        expected: Type,
        found: Type,
        span: Span,
    },

    #[error("cannot unify types: {0:?} and {1:?}")]
    UnificationError(Type, Type, Span),

    #[error("undefined variable: {name}")]
    UndefinedVariable { name: String, span: Span },

    #[error("undefined type: {name}")]
    UndefinedType { name: String, span: Span },

    #[error("occurs check failed: infinite type")]
    OccursCheck { span: Span },

    #[error("not a function type: {0:?}")]
    NotAFunction(Type, Span),

    #[error("not a scale type")]
    NotAScale { found: Type, span: Span },

    #[error("invalid scale index: {index}")]
    InvalidScaleIndex { index: u8, span: Span },

    #[error("time alignment mismatch in layer")]
    TimeAlignmentMismatch {
        expected_duration: String,
        found_duration: String,
        part_index: usize,
        span: Span,
    },
}

impl TypeError {
    pub fn span(&self) -> Span {
        match self {
            TypeError::Mismatch { span, .. } => *span,
            TypeError::UnificationError(_, _, span) => *span,
            TypeError::UndefinedVariable { span, .. } => *span,
            TypeError::UndefinedType { span, .. } => *span,
            TypeError::OccursCheck { span } => *span,
            TypeError::NotAFunction(_, span) => *span,
            TypeError::NotAScale { span, .. } => *span,
            TypeError::InvalidScaleIndex { span, .. } => *span,
            TypeError::TimeAlignmentMismatch { span, .. } => *span,
        }
    }
}
