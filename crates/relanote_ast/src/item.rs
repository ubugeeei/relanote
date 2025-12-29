use relanote_core::Spanned;

use crate::expr::{Expr, Ident};
use crate::music::{ChordDef, ScaleDef, SynthDef};
use crate::pattern::Pattern;
use crate::types::TypeAnnotation;

/// Top-level item in a program
#[derive(Clone, Debug)]
pub enum Item {
    /// Scale definition: scale Major = { R, M2, ... }
    ScaleDef(ScaleDef),

    /// Chord definition: chord Tonic7 = [ R, M3, P5, M7 ]
    ChordDef(ChordDef),

    /// Synth definition: synth Lead = { osc: Saw, env: { ... } }
    SynthDef(SynthDef),

    /// Let binding: let x = expr
    LetBinding(LetBinding),

    /// Set binding: set key = C4 (for built-in configuration variables)
    SetBinding(SetBinding),

    /// Function definition: let f x y = expr (sugar for let f = \x -> \y -> expr)
    FunctionDef(FunctionDef),

    /// Import declaration (JavaScript-style)
    Import(ImportDecl),

    /// Export declaration (JavaScript-style)
    Export(ExportDecl),

    /// Module declaration (Rust-style): mod foo
    Mod(ModDecl),

    /// Use declaration (Rust-style): use foo::bar
    Use(UseDecl),

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

/// Set binding for built-in configuration variables (key, tempo)
#[derive(Clone, Debug)]
pub struct SetBinding {
    pub name: Ident,
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

/// Module declaration: mod foo
/// This declares a submodule that should be loaded from a file
#[derive(Clone, Debug)]
pub struct ModDecl {
    pub name: Ident,
}

/// Use declaration for importing from modules
/// Examples:
/// - use scales::Major
/// - use chords::{Maj7, Min7}
/// - use synth::*
/// - use mymod::func as myFunc
#[derive(Clone, Debug)]
pub struct UseDecl {
    pub path: UsePath,
}

/// Path in a use declaration
#[derive(Clone, Debug)]
pub struct UsePath {
    /// Path segments: ["scales", "Major"] for scales::Major
    pub segments: Vec<Ident>,
    /// What to import from the final path
    pub kind: UseKind,
}

/// What kind of import to perform at the end of a use path
#[derive(Clone, Debug)]
pub enum UseKind {
    /// Import the final segment as-is: use foo::bar
    Simple,
    /// Import everything: use foo::*
    Glob,
    /// Import multiple items: use foo::{bar, baz}
    Group(Vec<UseItem>),
}

/// An item in a use group
#[derive(Clone, Debug)]
pub struct UseItem {
    /// The name to import
    pub name: Ident,
    /// Optional alias: as newName
    pub alias: Option<Ident>,
}
