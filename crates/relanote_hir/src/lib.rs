//! High-level Intermediate Representation for relanote
//!
//! HIR is the type-annotated AST used for evaluation and code generation.

pub mod hir;
pub mod lower;

pub use hir::*;
