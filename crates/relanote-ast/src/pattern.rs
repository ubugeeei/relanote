use relanote_core::Spanned;

use crate::expr::Ident;
use crate::types::TypeAnnotation;

/// Pattern for pattern matching and bindings
#[derive(Clone, Debug)]
pub enum Pattern {
    /// Wildcard pattern: _
    Wildcard,

    /// Variable binding: x
    Ident(Ident),

    /// Literal pattern
    Literal(LiteralPattern),

    /// Tuple pattern: (a, b, c)
    Tuple(Vec<Spanned<Pattern>>),

    /// Array pattern: [a, b, c] or [head, ...tail]
    Array(ArrayPattern),

    /// Constructor pattern: Some(x) or Interval(quality, degree)
    Constructor {
        name: Ident,
        args: Vec<Spanned<Pattern>>,
    },

    /// Or pattern: p1 | p2
    Or(Box<Spanned<Pattern>>, Box<Spanned<Pattern>>),

    /// Pattern with type annotation: p : Type
    Annotated(Box<Spanned<Pattern>>, TypeAnnotation),
}

/// Literal patterns
#[derive(Clone, Debug)]
pub enum LiteralPattern {
    Integer(i64),
    Float(f64),
    String(String),
    Bool(bool),
    Unit,
}

/// Array pattern with optional rest
#[derive(Clone, Debug)]
pub struct ArrayPattern {
    pub elements: Vec<Spanned<Pattern>>,
    pub rest: Option<Box<Spanned<Pattern>>>,
}

impl Pattern {
    /// Check if this pattern is irrefutable (always matches)
    pub fn is_irrefutable(&self) -> bool {
        match self {
            Pattern::Wildcard => true,
            Pattern::Ident(_) => true,
            Pattern::Tuple(patterns) => patterns.iter().all(|p| p.node.is_irrefutable()),
            Pattern::Annotated(p, _) => p.node.is_irrefutable(),
            _ => false,
        }
    }

    /// Get all bound identifiers in this pattern
    pub fn bindings(&self) -> Vec<&Ident> {
        match self {
            Pattern::Wildcard => vec![],
            Pattern::Ident(id) => vec![id],
            Pattern::Literal(_) => vec![],
            Pattern::Tuple(patterns) => {
                patterns.iter().flat_map(|p| p.node.bindings()).collect()
            }
            Pattern::Array(arr) => {
                let mut bindings: Vec<_> =
                    arr.elements.iter().flat_map(|p| p.node.bindings()).collect();
                if let Some(rest) = &arr.rest {
                    bindings.extend(rest.node.bindings());
                }
                bindings
            }
            Pattern::Constructor { args, .. } => {
                args.iter().flat_map(|p| p.node.bindings()).collect()
            }
            Pattern::Or(p1, _p2) => {
                // Both branches should have the same bindings
                p1.node.bindings()
            }
            Pattern::Annotated(p, _) => p.node.bindings(),
        }
    }
}
