use crate::context::TypeContext;
use crate::error::TypeError;
use crate::types::{TyVar, Type};
use relanote_core::Span;

impl TypeContext {
    /// Unify two types
    pub fn unify(&mut self, t1: &Type, t2: &Type, span: Span) -> Result<(), TypeError> {
        let t1 = self.apply(t1);
        let t2 = self.apply(t2);

        match (&t1, &t2) {
            // Same type variables
            (Type::Var(v1), Type::Var(v2)) if v1 == v2 => Ok(()),

            // Type variable with any type
            (Type::Var(v), t) | (t, Type::Var(v)) => {
                if self.occurs_in(*v, t) {
                    Err(TypeError::OccursCheck { span })
                } else {
                    self.add_substitution(*v, t.clone());
                    Ok(())
                }
            }

            // Function types
            (Type::Function(a1, r1), Type::Function(a2, r2)) => {
                self.unify(a1, a2, span)?;
                self.unify(r1, r2, span)
            }

            // Tuple types
            (Type::Tuple(e1), Type::Tuple(e2)) if e1.len() == e2.len() => {
                for (a, b) in e1.iter().zip(e2.iter()) {
                    self.unify(a, b, span)?;
                }
                Ok(())
            }

            // Array types
            (Type::Array(e1), Type::Array(e2)) => self.unify(e1, e2, span),

            // Same primitive types
            (t1, t2) if t1 == t2 => Ok(()),

            // Error type unifies with anything
            (Type::Error, _) | (_, Type::Error) => Ok(()),

            // Type mismatch
            _ => Err(TypeError::UnificationError(t1, t2, span)),
        }
    }

    /// Check if a type variable occurs in a type (for occurs check)
    pub fn occurs_in(&self, var: TyVar, ty: &Type) -> bool {
        let ty = self.apply(ty);
        match &ty {
            Type::Var(v) => *v == var,
            Type::Function(a, b) => self.occurs_in(var, a) || self.occurs_in(var, b),
            Type::Tuple(elems) => elems.iter().any(|e| self.occurs_in(var, e)),
            Type::Array(elem) => self.occurs_in(var, elem),
            _ => false,
        }
    }
}
