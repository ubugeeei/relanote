use relanote_core::Spanned;

use crate::expr::{Expr, Ident};
use crate::music::{ChordDef, ScaleDef};
use crate::pattern::Pattern;
use crate::types::TypeAnnotation;

/// Top-level item in a program
#[derive(Clone, Debug)]
pub enum Item {
    /// Scale definition: scale Major = { R, M2, ... }
    ScaleDef(ScaleDef),

    /// Chord definition: chord Tonic7 = [ R, M3, P5, M7 ]
    ChordDef(ChordDef),

    /// Let binding: let x = expr
    LetBinding(LetBinding),

    /// Function definition: let f x y = expr (sugar for let f = \x -> \y -> expr)
    FunctionDef(FunctionDef),

    /// Import declaration
    Import(ImportDecl),

    /// Export declaration
    Export(ExportDecl),

    /// Expression statement (for top-level expressions like render(...))
    ExprStmt(Spanned<Expr>),
}

/// Let binding at the top level
#[derive(Clone, Debug)]
pub struct LetBinding {
    pub pattern: Spanned<Pattern>,
    pub type_ann: Option<TypeAnnotation>,
    pub value: Spanned<Expr>,
}

/// Function definition (desugared to LetBinding with Lambda)
#[derive(Clone, Debug)]
pub struct FunctionDef {
    pub name: Ident,
    pub params: Vec<Spanned<Pattern>>,
    pub return_type: Option<TypeAnnotation>,
    pub body: Spanned<Expr>,
}

/// Import declaration
#[derive(Clone, Debug)]
pub struct ImportDecl {
    pub items: Vec<ImportItem>,
    pub from: String,
}

/// Import item (what to import)
#[derive(Clone, Debug)]
pub enum ImportItem {
    /// Import a single name: import foo from "module"
    Named(Ident),
    /// Import with alias: import foo as bar from "module"
    Aliased { name: Ident, alias: Ident },
    /// Import all: import * from "module"
    All,
    /// Import all with alias: import * as M from "module"
    AllAliased(Ident),
}

/// Export declaration
#[derive(Clone, Debug)]
pub enum ExportDecl {
    /// Export a single item: export foo
    Named(Vec<Ident>),
    /// Export with definition: export let foo = ...
    Definition(Box<Item>),
    /// Re-export from another module: export { foo } from "module"
    ReExport { items: Vec<Ident>, from: String },
}
