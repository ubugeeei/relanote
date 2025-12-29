pub mod expr;
pub mod item;
pub mod music;
pub mod pattern;
pub mod types;
pub mod visitor;

use relanote_core::Spanned;

pub use expr::*;
pub use item::*;
pub use music::*;
pub use pattern::*;
pub use types::*;
pub use visitor::*;

/// Unique identifier for AST nodes (for HIR mapping and analysis)
#[derive(Clone, Copy, Debug, PartialEq, Eq, Hash, Default)]
pub struct NodeId(u32);

impl NodeId {
    pub fn new(id: u32) -> Self {
        Self(id)
    }

    pub fn dummy() -> Self {
        Self(u32::MAX)
    }

    pub fn is_dummy(&self) -> bool {
        self.0 == u32::MAX
    }
}

/// A comment with its position
#[derive(Clone, Debug)]
pub struct Comment {
    pub text: String,
    pub span: relanote_core::Span,
}

/// A complete relanote program
#[derive(Clone, Debug)]
pub struct Program {
    pub items: Vec<Spanned<Item>>,
    pub comments: Vec<Comment>,
}

impl Program {
    pub fn new(items: Vec<Spanned<Item>>) -> Self {
        Self {
            items,
            comments: Vec::new(),
        }
    }

    pub fn with_comments(items: Vec<Spanned<Item>>, comments: Vec<Comment>) -> Self {
        Self { items, comments }
    }

    pub fn empty() -> Self {
        Self {
            items: Vec::new(),
            comments: Vec::new(),
        }
    }
}
