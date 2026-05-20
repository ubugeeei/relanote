///|
/// Evaluation environment — a chained scope mapping names to runtime
/// values. The legacy implementation threads parents through `Rc<RefCell<…>>`;
/// MoonBit's shared mutability lets us just hold an `Env?` directly.
pub struct Env {
  bindings : @hashmap.HashMap[@core.InternedStr, Value]
  parent : Env?
}

///|
pub fn Env::new() -> Env {
  { bindings: @hashmap.HashMap([]), parent: None }
}

///|
pub fn Env::with_parent(parent : Env) -> Env {
  { bindings: @hashmap.HashMap([]), parent: Some(parent) }
}

///|
pub fn Env::lookup(self : Env, name : @core.InternedStr) -> Value? {
  match self.bindings.get(name) {
    Some(v) => Some(v)
    None =>
      match self.parent {
        Some(p) => p.lookup(name)
        None => None
      }
  }
}

///|
pub fn Env::bind(self : Env, name : @core.InternedStr, value : Value) -> Unit {
  self.bindings.set(name, value)
}

///|
pub fn Env::all_bindings(self : Env) -> Array[(@core.InternedStr, Value)] {
  let out : Array[(@core.InternedStr, Value)] = []
  for k, v in self.bindings {
    out.push((k, v))
  }
  out
}
