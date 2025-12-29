use relanote_core::{InternedStr, Spanned};

use crate::music::{Articulation, Block, EnvelopeLit, IntervalLit, LayerExpr, PartExpr, SectionExpr, Tuplet};
use crate::pattern::Pattern;
use crate::types::TypeAnnotation;
use crate::NodeId;

/// An identifier
#[derive(Clone, Debug, PartialEq, Eq, Hash)]
pub struct Ident {
    pub name: InternedStr,
    pub id: NodeId,
}

impl Ident {
    pub fn new(name: InternedStr) -> Self {
        Self {
            name,
            id: NodeId::dummy(),
        }
    }

    pub fn with_id(name: InternedStr, id: NodeId) -> Self {
        Self { name, id }
    }
}

/// Expression AST node
#[derive(Clone, Debug)]
pub enum Expr {
    // ===== Literals =====
    /// Integer literal
    Integer(i64),

    /// Float literal
    Float(f64),

    /// String literal
    String(String),

    /// Boolean literal
    Bool(bool),

    /// Unit value ()
    Unit,

    // ===== Identifiers =====
    /// Variable reference
    Ident(Ident),

    // ===== Music Primitives =====
    /// Interval literal (M3, P5+, etc.)
    Interval(IntervalLit),

    /// Root/Rest marker (R)
    Root,

    /// Articulation marker (*, ^, ~)
    Articulation(Articulation),

    /// Block expression | ... |
    Block(Block),

    /// Tuplet { ... }:n
    Tuplet(Tuplet),

    /// Envelope env(from, to, duration)
    Envelope(EnvelopeLit),

    // ===== Higher-level Music Structures =====
    /// Part expression
    Part(PartExpr),

    /// Section expression
    Section(Box<SectionExpr>),

    /// Layer expression
    Layer(LayerExpr),

    // ===== Functions =====
    /// Lambda expression: \x -> body
    Lambda(Lambda),

    /// Function application: f(x, y)
    Application(Application),

    /// Pipe application: x |> f
    Pipe(Pipe),

    // ===== Collections =====
    /// Array literal [a, b, c]
    Array(Vec<Spanned<Expr>>),

    /// Tuple literal (a, b, c)
    Tuple(Vec<Spanned<Expr>>),

    // ===== Operators =====
    /// Binary operation
    Binary(Binary),

    /// Unary operation
    Unary(Unary),

    /// Index access: arr[i] or scale[3]
    Index(Index),

    /// Field access: expr.field
    Field(Field),

    // ===== Control Flow =====
    /// If expression
    If(Box<IfExpr>),

    /// Match expression
    Match(Box<MatchExpr>),

    /// Let binding (expression form): let x = e1 in e2
    Let(Box<LetExpr>),

    // ===== Special =====
    /// Scale/Chord modification: Major with { P4+ }
    With(Box<WithExpr>),

    /// Type annotation: expr : Type
    Annotated(Box<Spanned<Expr>>, TypeAnnotation),

    /// Parenthesized expression
    Paren(Box<Spanned<Expr>>),

    /// Error node (for error recovery)
    Error,
}

/// Lambda expression
#[derive(Clone, Debug)]
pub struct Lambda {
    pub params: Vec<Spanned<Pattern>>,
    pub body: Box<Spanned<Expr>>,
}

/// Function application
#[derive(Clone, Debug)]
pub struct Application {
    pub func: Box<Spanned<Expr>>,
    pub args: Vec<Spanned<Expr>>,
}

/// Pipe expression: left |> right
#[derive(Clone, Debug)]
pub struct Pipe {
    pub left: Box<Spanned<Expr>>,
    pub right: Box<Spanned<Expr>>,
}

/// Binary operation
#[derive(Clone, Debug)]
pub struct Binary {
    pub op: BinaryOp,
    pub left: Box<Spanned<Expr>>,
    pub right: Box<Spanned<Expr>>,
}

/// Binary operators
#[derive(Clone, Copy, Debug, PartialEq, Eq)]
pub enum BinaryOp {
    // Arithmetic
    Add,
    Sub,
    Mul,
    Div,
    Mod,

    // Comparison
    Eq,
    Ne,
    Lt,
    Le,
    Gt,
    Ge,

    // Logical
    And,
    Or,

    // Music-specific
    Concat, // ++
}

/// Unary operation
#[derive(Clone, Debug)]
pub struct Unary {
    pub op: UnaryOp,
    pub operand: Box<Spanned<Expr>>,
}

/// Unary operators
#[derive(Clone, Copy, Debug, PartialEq, Eq)]
pub enum UnaryOp {
    Neg,
    Not,
}

/// Index expression: base[index]
#[derive(Clone, Debug)]
pub struct Index {
    pub base: Box<Spanned<Expr>>,
    pub index: Box<Spanned<Expr>>,
}

/// Field access: base.field
#[derive(Clone, Debug)]
pub struct Field {
    pub base: Box<Spanned<Expr>>,
    pub field: Ident,
}

/// If expression
#[derive(Clone, Debug)]
pub struct IfExpr {
    pub condition: Spanned<Expr>,
    pub then_branch: Spanned<Expr>,
    pub else_branch: Option<Spanned<Expr>>,
}

/// Match expression
#[derive(Clone, Debug)]
pub struct MatchExpr {
    pub scrutinee: Spanned<Expr>,
    pub arms: Vec<MatchArm>,
}

/// Match arm
#[derive(Clone, Debug)]
pub struct MatchArm {
    pub pattern: Spanned<Pattern>,
    pub guard: Option<Spanned<Expr>>,
    pub body: Spanned<Expr>,
}

/// Let expression (expression form)
#[derive(Clone, Debug)]
pub struct LetExpr {
    pub pattern: Spanned<Pattern>,
    pub type_ann: Option<TypeAnnotation>,
    pub value: Spanned<Expr>,
    pub body: Spanned<Expr>,
}

/// With expression for scale/chord modification
#[derive(Clone, Debug)]
pub struct WithExpr {
    pub base: Spanned<Expr>,
    pub modifications: Vec<Spanned<Expr>>,
}

impl Expr {
    /// Check if this expression is a simple value (no side effects, can be duplicated)
    pub fn is_simple(&self) -> bool {
        matches!(
            self,
            Expr::Integer(_)
                | Expr::Float(_)
                | Expr::String(_)
                | Expr::Bool(_)
                | Expr::Unit
                | Expr::Ident(_)
                | Expr::Root
        )
    }

    /// Check if this is an error node
    pub fn is_error(&self) -> bool {
        matches!(self, Expr::Error)
    }
}
