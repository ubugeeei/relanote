///|
/// Type annotation as written in source code. Mirrors
/// `relanote_ast::types::TypeAnnotation` in the Rust crate.
pub(all) enum TypeAnnotation {
  /// Named type — `Int`, `String`, `Scale`, …
  Named(Ident)
  /// Generic type — `List<Block>`, `Option<Int>`.
  Generic(Ident, Array[TypeAnnotation])
  /// Function type — `a -> b`.
  Function(TypeAnnotation, TypeAnnotation)
  /// Tuple type — `(Int, String, Bool)`.
  Tuple(Array[TypeAnnotation])
  /// Array type — `[Int]`.
  Array(TypeAnnotation)
  /// Unit type — `()`.
  Unit
  /// Type variable — `'a`.
  Var(Ident)
}

///|
/// `true` if the annotation mentions any type variables anywhere.
pub fn TypeAnnotation::has_type_vars(self : TypeAnnotation) -> Bool {
  match self {
    Named(_) => false
    Generic(_, args) => {
      for a in args {
        if a.has_type_vars() {
          return true
        }
      }
      false
    }
    Function(a, b) => a.has_type_vars() || b.has_type_vars()
    Tuple(elems) => {
      for e in elems {
        if e.has_type_vars() {
          return true
        }
      }
      false
    }
    Array(elem) => elem.has_type_vars()
    Unit => false
    Var(_) => true
  }
}

///|
/// Build a curried function type — `a -> b -> c` — from a parameter list
/// and a return type, matching `TypeAnnotation::function` on the Rust side.
pub fn TypeAnnotation::function(
  params : Array[TypeAnnotation],
  ret : TypeAnnotation,
) -> TypeAnnotation {
  let mut acc = ret
  let mut i = params.length() - 1
  while i >= 0 {
    acc = Function(params[i], acc)
    i -= 1
  }
  acc
}
