//! Lowering from AST to HIR

use crate::hir::TypedProgram;
use relanote_ast::Program;

/// Lower AST to HIR
pub fn lower_program(_program: &Program) -> TypedProgram {
    // Placeholder implementation
    TypedProgram { items: vec![] }
}
