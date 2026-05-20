///|
/// A module that has been resolved — its program, the diagnostics from
/// parsing it, and the list of paths it depends on.
pub struct ResolvedModule {
  source : @core.Source
  program : @ast.Program
  diagnostics : @core.Diagnostics
  dependencies : Array[String]
}

///|
pub fn ResolvedModule::source(self : ResolvedModule) -> @core.Source {
  self.source
}

///|
pub fn ResolvedModule::program(self : ResolvedModule) -> @ast.Program {
  self.program
}

///|
pub fn ResolvedModule::diagnostics(self : ResolvedModule) -> @core.Diagnostics {
  self.diagnostics
}

///|
pub fn ResolvedModule::dependencies(self : ResolvedModule) -> Array[String] {
  self.dependencies
}

///|
/// Module resolver for handling imports and dependencies. Mirrors
/// `resolver::resolver::ModuleResolver`.
pub struct ModuleResolver {
  loader : ModuleLoader
  modules : @hashmap.HashMap[String, ResolvedModule]
  // Insertion order of `modules`. The legacy implementation uses `IndexMap` so
  // `modules()` iterates in dependency-discovery order; `@hashmap.HashMap`
  // does not preserve insertion order, so we track it separately.
  order : Array[String]
  resolving : @hashset.HashSet[String]
}

///|
pub fn ModuleResolver::new(root : String) -> ModuleResolver {
  {
    loader: ModuleLoader::new(root),
    modules: @hashmap.HashMap([]),
    order: [],
    resolving: @hashset.HashSet([]),
  }
}

///|
pub fn ModuleResolver::loader(self : ModuleResolver) -> ModuleLoader {
  self.loader
}

///|
/// Resolve a module and (recursively) its dependencies. Mirrors the legacy
/// `resolve` method's algorithm: circular-dependency check → cache check
/// → loader → parse → recurse on `Item::Import.from` entries.
pub fn ModuleResolver::resolve(
  self : ModuleResolver,
  module_path : String,
) -> Result[ResolvedModule, ResolveError] {
  if self.resolving.contains(module_path) {
    return Err(CircularDependency(path=module_path))
  }
  match self.modules.get(module_path) {
    Some(m) => return Ok(m)
    None => ()
  }
  let path = match self.loader.resolve_path(module_path) {
    Some(p) => p
    None => return Err(ModuleNotFound(path=module_path))
  }
  let source = match self.loader.load(path) {
    Ok(s) => s
    Err(err) => return Err(err)
  }
  let (program, diagnostics) = @parser.parse_source(source)
  self.resolving.add(module_path)
  let dependencies : Array[String] = []
  for item_spanned in program.items() {
    match item_spanned.node() {
      @ast.Import(import_decl) => dependencies.push(import_decl.from())
      _ => ()
    }
  }
  for dep in dependencies {
    match self.resolve(dep) {
      Ok(_) => ()
      Err(err) => return Err(err)
    }
  }
  self.resolving.remove(module_path)
  let resolved = ResolvedModule::{ source, program, diagnostics, dependencies }
  self.modules.set(module_path, resolved)
  self.order.push(module_path)
  Ok(resolved)
}

///|
/// Iterate all resolved modules in dependency-discovery order. Mirrors
/// `IndexMap`-backed iteration on the previous implementation.
pub fn ModuleResolver::modules(self : ModuleResolver) -> Array[ResolvedModule] {
  let out : Array[ResolvedModule] = []
  for path in self.order {
    match self.modules.get(path) {
      Some(m) => out.push(m)
      None => ()
    }
  }
  out
}
