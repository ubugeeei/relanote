use relanote_core::Span;
use relanote_lexer::TokenKind;
use thiserror::Error;

/// Parser error type
#[derive(Debug, Error, Clone)]
pub enum ParseError {
    #[error("unexpected token: expected {expected}, found {found:?}")]
    UnexpectedToken {
        expected: String,
        found: TokenKind,
        span: Span,
    },

    #[error("unexpected end of file")]
    UnexpectedEof { span: Span },

    #[error("invalid interval: {message}")]
    InvalidInterval { message: String, span: Span },

    #[error("invalid scale index: {index}")]
    InvalidScaleIndex { index: u8, span: Span },

    #[error("unclosed delimiter: expected {expected}")]
    UnclosedDelimiter { expected: char, span: Span },

    #[error("invalid expression")]
    InvalidExpression { span: Span },

    #[error("{message}")]
    Custom { message: String, span: Span },
}

impl ParseError {
    pub fn span(&self) -> Span {
        match self {
            ParseError::UnexpectedToken { span, .. } => *span,
            ParseError::UnexpectedEof { span } => *span,
            ParseError::InvalidInterval { span, .. } => *span,
            ParseError::InvalidScaleIndex { span, .. } => *span,
            ParseError::UnclosedDelimiter { span, .. } => *span,
            ParseError::InvalidExpression { span } => *span,
            ParseError::Custom { span, .. } => *span,
        }
    }

    pub fn unexpected_token(expected: impl Into<String>, found: TokenKind, span: Span) -> Self {
        ParseError::UnexpectedToken {
            expected: expected.into(),
            found,
            span,
        }
    }

    pub fn custom(message: impl Into<String>, span: Span) -> Self {
        ParseError::Custom {
            message: message.into(),
            span,
        }
    }
}

/// Result type for parsing operations
pub type ParseResult<T> = Result<T, ParseError>;
