//! Lowering from AST to HIR

use relanote_ast::Program;
use crate::hir::TypedProgram;

/// Lower AST to HIR
pub fn lower_program(_program: &Program) -> TypedProgram {
    // Placeholder implementation
    TypedProgram { items: vec![] }
}
