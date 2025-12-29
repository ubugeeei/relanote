use std::collections::HashMap;

use relanote_core::InternedStr;

use crate::types::{TyVar, Type, TypeScheme};

/// Type checking context
pub struct TypeContext {
    /// Next type variable ID
    next_var: u32,

    /// Type environment: name -> TypeScheme
    env: HashMap<InternedStr, TypeScheme>,

    /// Substitution map: TyVar -> Type
    substitutions: HashMap<TyVar, Type>,

    /// Scope stack for nested contexts
    scopes: Vec<HashMap<InternedStr, TypeScheme>>,
}

impl Default for TypeContext {
    fn default() -> Self {
        Self::new()
    }
}

impl TypeContext {
    pub fn new() -> Self {
        Self {
            next_var: 0,
            env: HashMap::new(),
            substitutions: HashMap::new(),
            scopes: Vec::new(),
        }
    }

    /// Generate a fresh type variable
    pub fn fresh_var(&mut self) -> Type {
        let var = TyVar::new(self.next_var);
        self.next_var += 1;
        Type::Var(var)
    }

    /// Enter a new scope
    pub fn push_scope(&mut self) {
        self.scopes.push(HashMap::new());
    }

    /// Exit the current scope
    pub fn pop_scope(&mut self) {
        if let Some(scope) = self.scopes.pop() {
            for name in scope.keys() {
                self.env.remove(name);
            }
        }
    }

    /// Bind a name to a type scheme
    pub fn bind(&mut self, name: InternedStr, scheme: TypeScheme) {
        if let Some(scope) = self.scopes.last_mut() {
            scope.insert(name, scheme.clone());
        }
        self.env.insert(name, scheme);
    }

    /// Bind a name to a monomorphic type
    pub fn bind_mono(&mut self, name: InternedStr, ty: Type) {
        self.bind(name, TypeScheme::mono(ty));
    }

    /// Look up a name in the environment
    pub fn lookup(&self, name: &InternedStr) -> Option<&TypeScheme> {
        self.env.get(name)
    }

    /// Add a substitution
    pub fn add_substitution(&mut self, var: TyVar, ty: Type) {
        self.substitutions.insert(var, ty);
    }

    /// Apply all substitutions to a type
    pub fn apply(&self, ty: &Type) -> Type {
        match ty {
            Type::Var(v) => {
                if let Some(t) = self.substitutions.get(v) {
                    self.apply(t)
                } else {
                    ty.clone()
                }
            }
            Type::Function(a, b) => Type::function(self.apply(a), self.apply(b)),
            Type::Tuple(elems) => Type::Tuple(elems.iter().map(|e| self.apply(e)).collect()),
            Type::Array(elem) => Type::array(self.apply(elem)),
            _ => ty.clone(),
        }
    }

    /// Instantiate a type scheme with fresh variables
    pub fn instantiate(&mut self, scheme: &TypeScheme) -> Type {
        let mut subst = HashMap::new();
        for &v in &scheme.quantifiers {
            let fresh = self.fresh_var();
            if let Type::Var(fv) = fresh {
                subst.insert(v, Type::Var(fv));
            }
        }

        fn substitute(ty: &Type, subst: &HashMap<TyVar, Type>) -> Type {
            match ty {
                Type::Var(v) => subst.get(v).cloned().unwrap_or_else(|| ty.clone()),
                Type::Function(a, b) => Type::function(substitute(a, subst), substitute(b, subst)),
                Type::Tuple(elems) => {
                    Type::Tuple(elems.iter().map(|e| substitute(e, subst)).collect())
                }
                Type::Array(elem) => Type::array(substitute(elem, subst)),
                _ => ty.clone(),
            }
        }

        substitute(&scheme.ty, &subst)
    }

    /// Generalize a type to a type scheme
    pub fn generalize(&self, ty: &Type) -> TypeScheme {
        let ty = self.apply(ty);
        let free_in_env: std::collections::HashSet<TyVar> =
            self.env.values().flat_map(|s| s.ty.free_vars()).collect();

        let quantifiers: Vec<TyVar> = ty
            .free_vars()
            .into_iter()
            .filter(|v| !free_in_env.contains(v))
            .collect();

        TypeScheme::poly(quantifiers, ty)
    }
}
