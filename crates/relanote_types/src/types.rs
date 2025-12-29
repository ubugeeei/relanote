use std::fmt;
use std::sync::Arc;

/// Unique type variable identifier
#[derive(Clone, Copy, Debug, PartialEq, Eq, Hash)]
pub struct TyVar(pub u32);

impl TyVar {
    pub fn new(id: u32) -> Self {
        Self(id)
    }
}

/// Core type representation
#[derive(Clone, Debug, PartialEq, Eq)]
pub enum Type {
    // Primitives
    Unit,
    Bool,
    Int,
    Float,
    String,

    // Music primitives
    Interval,
    Scale,
    Chord,
    Block,
    Part,
    Section,
    Song,
    Articulation,
    Envelope,
    Duration,
    Dynamic,

    // Synth primitives
    Synth,
    Oscillator,
    Filter,

    // Compound types
    Function(Arc<Type>, Arc<Type>),
    Tuple(Vec<Type>),
    Array(Arc<Type>),

    // Type variable (for inference)
    Var(TyVar),

    // Error type (for recovery)
    Error,
}

impl Type {
    /// Create a function type
    pub fn function(param: Type, ret: Type) -> Self {
        Type::Function(Arc::new(param), Arc::new(ret))
    }

    /// Create a multi-parameter function type
    pub fn function_n(params: Vec<Type>, ret: Type) -> Self {
        params
            .into_iter()
            .rev()
            .fold(ret, |acc, param| Type::function(param, acc))
    }

    /// Create an array type
    pub fn array(elem: Type) -> Self {
        Type::Array(Arc::new(elem))
    }

    /// Check if this type contains any type variables
    pub fn has_vars(&self) -> bool {
        match self {
            Type::Var(_) => true,
            Type::Function(a, b) => a.has_vars() || b.has_vars(),
            Type::Tuple(elems) => elems.iter().any(|e| e.has_vars()),
            Type::Array(elem) => elem.has_vars(),
            _ => false,
        }
    }

    /// Get all free type variables
    pub fn free_vars(&self) -> Vec<TyVar> {
        match self {
            Type::Var(v) => vec![*v],
            Type::Function(a, b) => {
                let mut vars = a.free_vars();
                vars.extend(b.free_vars());
                vars
            }
            Type::Tuple(elems) => elems.iter().flat_map(|e| e.free_vars()).collect(),
            Type::Array(elem) => elem.free_vars(),
            _ => vec![],
        }
    }
}

impl fmt::Display for Type {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        match self {
            Type::Unit => write!(f, "()"),
            Type::Bool => write!(f, "Bool"),
            Type::Int => write!(f, "Int"),
            Type::Float => write!(f, "Float"),
            Type::String => write!(f, "String"),
            Type::Interval => write!(f, "Interval"),
            Type::Scale => write!(f, "Scale"),
            Type::Chord => write!(f, "Chord"),
            Type::Block => write!(f, "Block"),
            Type::Part => write!(f, "Part"),
            Type::Section => write!(f, "Section"),
            Type::Song => write!(f, "Song"),
            Type::Articulation => write!(f, "Articulation"),
            Type::Envelope => write!(f, "Envelope"),
            Type::Duration => write!(f, "Duration"),
            Type::Dynamic => write!(f, "Dynamic"),
            Type::Synth => write!(f, "Synth"),
            Type::Oscillator => write!(f, "Oscillator"),
            Type::Filter => write!(f, "Filter"),
            Type::Function(param, ret) => {
                // Handle nested functions for curried display
                match param.as_ref() {
                    Type::Function(_, _) => write!(f, "({}) -> {}", param, ret),
                    _ => write!(f, "{} -> {}", param, ret),
                }
            }
            Type::Tuple(elems) => {
                write!(f, "(")?;
                for (i, elem) in elems.iter().enumerate() {
                    if i > 0 {
                        write!(f, ", ")?;
                    }
                    write!(f, "{}", elem)?;
                }
                write!(f, ")")
            }
            Type::Array(elem) => write!(f, "[{}]", elem),
            Type::Var(v) => write!(f, "t{}", v.0),
            Type::Error => write!(f, "Error"),
        }
    }
}

/// Type scheme for polymorphism: forall a b. Type
#[derive(Clone, Debug)]
pub struct TypeScheme {
    pub quantifiers: Vec<TyVar>,
    pub ty: Type,
}

impl TypeScheme {
    /// Create a monomorphic type scheme (no quantifiers)
    pub fn mono(ty: Type) -> Self {
        Self {
            quantifiers: vec![],
            ty,
        }
    }

    /// Create a polymorphic type scheme
    pub fn poly(quantifiers: Vec<TyVar>, ty: Type) -> Self {
        Self { quantifiers, ty }
    }
}
