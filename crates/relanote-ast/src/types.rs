use crate::expr::Ident;

/// Type annotation in source code
#[derive(Clone, Debug)]
pub enum TypeAnnotation {
    /// Named type: Int, String, Scale, Block
    Named(Ident),

    /// Generic type: List<Block>, Option<Int>
    Generic(Ident, Vec<TypeAnnotation>),

    /// Function type: a -> b
    Function(Box<TypeAnnotation>, Box<TypeAnnotation>),

    /// Tuple type: (Int, String, Bool)
    Tuple(Vec<TypeAnnotation>),

    /// Array type: [Int]
    Array(Box<TypeAnnotation>),

    /// Unit type: ()
    Unit,

    /// Type variable (for inference): 'a
    Var(Ident),
}

impl TypeAnnotation {
    /// Check if this type annotation mentions any type variables
    pub fn has_type_vars(&self) -> bool {
        match self {
            TypeAnnotation::Named(_) => false,
            TypeAnnotation::Generic(_, args) => args.iter().any(|a| a.has_type_vars()),
            TypeAnnotation::Function(a, b) => a.has_type_vars() || b.has_type_vars(),
            TypeAnnotation::Tuple(elems) => elems.iter().any(|e| e.has_type_vars()),
            TypeAnnotation::Array(elem) => elem.has_type_vars(),
            TypeAnnotation::Unit => false,
            TypeAnnotation::Var(_) => true,
        }
    }

    /// Create a function type: a -> b -> c
    pub fn function(params: Vec<TypeAnnotation>, ret: TypeAnnotation) -> TypeAnnotation {
        params.into_iter().rev().fold(ret, |acc, param| {
            TypeAnnotation::Function(Box::new(param), Box::new(acc))
        })
    }
}
