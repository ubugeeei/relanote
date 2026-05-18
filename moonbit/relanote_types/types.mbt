///|
/// Unique type variable identifier — index into the inference engine's
/// variable table.
pub struct TyVar {
  id : UInt
} derive(Eq, Hash)

///|
pub fn TyVar::new(id : UInt) -> TyVar {
  { id, }
}

///|
pub fn TyVar::id(self : TyVar) -> UInt {
  self.id
}

///|
/// Core type representation — primitive types, music-specific primitives,
/// compound types and the `Var` / `Error` recovery cases.
///
/// Mirrors `crates/relanote_types::types::Type` one-to-one.
pub(all) enum Type {
  // Primitives
  Unit
  BoolTy
  IntTy
  FloatTy
  StringTy
  // Music primitives
  Interval
  Scale
  Chord
  Block
  Part
  Section
  Song
  Articulation
  Envelope
  Duration
  Dynamic
  // Synth primitives
  Synth
  Oscillator
  Filter
  // Effect primitives
  DistortionType
  // Compound types
  Function(Type, Type)
  Tuple(Array[Type])
  ArrayTy(Type)
  // Type variable, for inference
  Var(TyVar)
  // Error recovery
  ErrorTy
} derive(Eq)

///|
/// Curry two types into a function type — `param -> ret`.
pub fn Type::function(param : Type, ret : Type) -> Type {
  Function(param, ret)
}

///|
/// Curry a parameter list into a function type — `a -> b -> c`.
pub fn Type::function_n(params : Array[Type], ret : Type) -> Type {
  let mut acc = ret
  let mut i = params.length() - 1
  while i >= 0 {
    acc = Function(params[i], acc)
    i -= 1
  }
  acc
}

///|
/// `[T]` array type constructor.
pub fn Type::array(elem : Type) -> Type {
  ArrayTy(elem)
}

///|
/// `true` if `self` mentions any type variables anywhere.
pub fn Type::has_vars(self : Type) -> Bool {
  match self {
    Var(_) => true
    Function(a, b) => a.has_vars() || b.has_vars()
    Tuple(elems) => {
      for e in elems {
        if e.has_vars() {
          return true
        }
      }
      false
    }
    ArrayTy(elem) => elem.has_vars()
    _ => false
  }
}

///|
/// Collect every type variable mentioned in `self`. Duplicates are kept so
/// the caller can count occurrences if needed.
pub fn Type::free_vars(self : Type) -> Array[TyVar] {
  let acc : Array[TyVar] = []
  collect_free_vars(self, acc)
  acc
}

///|
fn collect_free_vars(ty : Type, acc : Array[TyVar]) -> Unit {
  match ty {
    Var(v) => acc.push(v)
    Function(a, b) => {
      collect_free_vars(a, acc)
      collect_free_vars(b, acc)
    }
    Tuple(elems) =>
      for e in elems {
        collect_free_vars(e, acc)
      }
    ArrayTy(elem) => collect_free_vars(elem, acc)
    _ => ()
  }
}

///|
/// Human-readable display string, matching `Display for Type` in the Rust
/// crate. Used for diagnostics.
pub fn Type::to_display_string(self : Type) -> String {
  match self {
    Unit => "()"
    BoolTy => "Bool"
    IntTy => "Int"
    FloatTy => "Float"
    StringTy => "String"
    Interval => "Interval"
    Scale => "Scale"
    Chord => "Chord"
    Block => "Block"
    Part => "Part"
    Section => "Section"
    Song => "Song"
    Articulation => "Articulation"
    Envelope => "Envelope"
    Duration => "Duration"
    Dynamic => "Dynamic"
    Synth => "Synth"
    Oscillator => "Oscillator"
    Filter => "Filter"
    DistortionType => "DistortionType"
    Function(param, ret) =>
      match param {
        Function(_, _) =>
          "(" + param.to_display_string() + ") -> " + ret.to_display_string()
        _ => param.to_display_string() + " -> " + ret.to_display_string()
      }
    Tuple(elems) => {
      let buf = StringBuilder::new()
      buf.write_string("(")
      let mut i = 0
      while i < elems.length() {
        if i > 0 {
          buf.write_string(", ")
        }
        buf.write_string(elems[i].to_display_string())
        i += 1
      }
      buf.write_string(")")
      buf.to_string()
    }
    ArrayTy(elem) => "[" + elem.to_display_string() + "]"
    Var(v) => "t" + v.id().to_string()
    ErrorTy => "Error"
  }
}

///|
/// Type scheme — `forall qs. ty` — used to support let-polymorphism.
pub struct TypeScheme {
  quantifiers : Array[TyVar]
  ty : Type
}

///|
/// Monomorphic type scheme (no quantifiers).
pub fn TypeScheme::mono(ty : Type) -> TypeScheme {
  { quantifiers: [], ty }
}

///|
/// Polymorphic type scheme.
pub fn TypeScheme::poly(quantifiers : Array[TyVar], ty : Type) -> TypeScheme {
  { quantifiers, ty }
}

///|
pub fn TypeScheme::quantifiers(self : TypeScheme) -> Array[TyVar] {
  self.quantifiers
}

///|
pub fn TypeScheme::ty(self : TypeScheme) -> Type {
  self.ty
}
