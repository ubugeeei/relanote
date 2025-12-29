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
        params.into_iter().rev().fold(ret, |acc, param| {
            Type::function(param, acc)
        })
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
