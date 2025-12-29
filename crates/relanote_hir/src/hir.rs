//! HIR node definitions

use relanote_types::Type;

/// HIR expression with type annotation
#[derive(Clone, Debug)]
pub struct TypedExpr {
    pub kind: TypedExprKind,
    pub ty: Type,
}

/// HIR expression kinds
#[derive(Clone, Debug)]
pub enum TypedExprKind {
    // Placeholder - to be implemented
    Placeholder,
}

/// HIR program
#[derive(Clone, Debug)]
pub struct TypedProgram {
    pub items: Vec<TypedItem>,
}

/// HIR item
#[derive(Clone, Debug)]
pub enum TypedItem {
    // Placeholder - to be implemented
    Placeholder,
}
