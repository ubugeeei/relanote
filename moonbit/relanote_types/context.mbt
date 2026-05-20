///|
/// Type-checking context — runs a fresh-var counter, an environment of
/// name→scheme bindings, a substitution map of TyVar→Type, and a scope
/// stack so `push_scope`/`pop_scope` mirror the legacy implementation behaviour.
pub struct TypeContext {
  mut next_var : UInt
  env : @hashmap.HashMap[@core.InternedStr, TypeScheme]
  substitutions : @hashmap.HashMap[TyVar, Type]
  scopes : Array[@hashmap.HashMap[@core.InternedStr, TypeScheme]]
}

///|
pub fn TypeContext::new() -> TypeContext {
  {
    next_var: 0,
    env: @hashmap.HashMap([]),
    substitutions: @hashmap.HashMap([]),
    scopes: [],
  }
}

///|
/// Hand out a fresh type variable for inference.
pub fn TypeContext::fresh_var(self : TypeContext) -> Type {
  let tv = TyVar::new(self.next_var)
  self.next_var += 1
  Var(tv)
}

///|
/// Enter a new scope so subsequent bindings can be unwound by
/// `pop_scope`.
pub fn TypeContext::push_scope(self : TypeContext) -> Unit {
  self.scopes.push(@hashmap.HashMap([]))
}

///|
/// Drop the current scope and remove every binding it introduced.
pub fn TypeContext::pop_scope(self : TypeContext) -> Unit {
  match self.scopes.pop() {
    Some(scope) =>
      for name, _ in scope {
        self.env.remove(name)
      }
    None => ()
  }
}

///|
/// Bind a name to a type scheme. The scheme is also recorded in the
/// current scope so `pop_scope` can undo it.
pub fn TypeContext::bind(
  self : TypeContext,
  name : @core.InternedStr,
  scheme : TypeScheme,
) -> Unit {
  match self.scopes.last() {
    Some(scope) => scope.set(name, scheme)
    None => ()
  }
  self.env.set(name, scheme)
}

///|
/// Shorthand for `bind(name, TypeScheme::mono(ty))`.
pub fn TypeContext::bind_mono(
  self : TypeContext,
  name : @core.InternedStr,
  ty : Type,
) -> Unit {
  self.bind(name, TypeScheme::mono(ty))
}

///|
/// Look up a name in the current environment.
pub fn TypeContext::lookup(
  self : TypeContext,
  name : @core.InternedStr,
) -> TypeScheme? {
  self.env.get(name)
}

///|
/// Record `tv := ty` in the substitution table.
pub fn TypeContext::add_substitution(
  self : TypeContext,
  tv : TyVar,
  ty : Type,
) -> Unit {
  self.substitutions.set(tv, ty)
}

///|
/// Apply all known substitutions to `ty` until a fixed point is reached.
pub fn TypeContext::apply(self : TypeContext, ty : Type) -> Type {
  match ty {
    Var(v) =>
      match self.substitutions.get(v) {
        Some(t) => self.apply(t)
        None => ty
      }
    Function(a, b) => Function(self.apply(a), self.apply(b))
    Tuple(elems) => {
      let mapped : Array[Type] = []
      for e in elems {
        mapped.push(self.apply(e))
      }
      Tuple(mapped)
    }
    ArrayTy(elem) => ArrayTy(self.apply(elem))
    _ => ty
  }
}

///|
/// Instantiate a polymorphic `scheme` by replacing each quantifier with
/// a fresh type variable.
pub fn TypeContext::instantiate(
  self : TypeContext,
  scheme : TypeScheme,
) -> Type {
  let subst : @hashmap.HashMap[TyVar, Type] = @hashmap.HashMap([])
  for v in scheme.quantifiers() {
    let fresh = self.fresh_var()
    subst.set(v, fresh)
  }
  substitute(scheme.ty(), subst)
}

///|
fn substitute(ty : Type, subst : @hashmap.HashMap[TyVar, Type]) -> Type {
  match ty {
    Var(v) =>
      match subst.get(v) {
        Some(t) => t
        None => ty
      }
    Function(a, b) => Function(substitute(a, subst), substitute(b, subst))
    Tuple(elems) => {
      let mapped : Array[Type] = []
      for e in elems {
        mapped.push(substitute(e, subst))
      }
      Tuple(mapped)
    }
    ArrayTy(elem) => ArrayTy(substitute(elem, subst))
    _ => ty
  }
}

///|
/// Generalize a type to a scheme by quantifying every free variable that
/// is not also free in the surrounding environment.
pub fn TypeContext::generalize(self : TypeContext, ty : Type) -> TypeScheme {
  let applied = self.apply(ty)
  let free_in_env : @hashset.HashSet[TyVar] = @hashset.HashSet([])
  for _, scheme in self.env {
    for v in scheme.ty().free_vars() {
      free_in_env.add(v)
    }
  }
  let quantifiers : Array[TyVar] = []
  for v in applied.free_vars() {
    if !free_in_env.contains(v) {
      quantifiers.push(v)
    }
  }
  TypeScheme::poly(quantifiers, applied)
}
