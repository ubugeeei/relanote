mod lexer;
pub mod token;

pub use lexer::{Lexer, LexerError};
pub use token::{Accidental, IntervalData, IntervalQuality, Token, TokenKind};
