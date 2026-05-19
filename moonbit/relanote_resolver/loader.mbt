///|
/// Module loader responsible for finding and loading source files.
///
/// The Rust crate uses `std::fs` directly; MoonBit packages targeting
/// `wasm-gc` (the default) cannot do filesystem IO unconditionally, so
/// this port exposes the same surface but `load` always raises
/// `ResolveError::IoError` until a per-target IO backend lands. Real
/// users of the resolver can plug their own loader by manually seeding
/// `add_source`.
pub struct ModuleLoader {
  root : String
  search_paths : Array[String]
  sources : @hashmap.HashMap[String, @core.Source]
}

///|
pub fn ModuleLoader::new(root : String) -> ModuleLoader {
  { root, search_paths: [root], sources: @hashmap.HashMap([]) }
}

///|
pub fn ModuleLoader::root(self : ModuleLoader) -> String {
  self.root
}

///|
pub fn ModuleLoader::add_search_path(
  self : ModuleLoader,
  path : String,
) -> Unit {
  self.search_paths.push(path)
}

///|
/// Manually register a source against a logical path. This is the
/// MoonBit-friendly equivalent of the Rust crate's `SourceDb::add_file`
/// — it works on every compile target since it doesn't touch the
/// filesystem.
pub fn ModuleLoader::add_source(
  self : ModuleLoader,
  path : String,
  source : @core.Source,
) -> Unit {
  self.sources.set(path, source)
}

///|
/// Look up a logical module path and return the path that backs it on
/// disk. Mirrors `ModuleLoader::resolve_path`.
pub fn ModuleLoader::resolve_path(
  self : ModuleLoader,
  module_path : String,
) -> String? {
  let file_name = module_path + ".rela"
  for sp in self.search_paths {
    let full_path = sp + "/" + file_name
    if self.sources.contains(full_path) {
      return Some(full_path)
    }
  }
  None
}

///|
/// Load the source at `path`. The skeleton returns the registered
/// `Source` if one was added via `add_source`; otherwise it raises
/// `IoError` (target-uniform).
pub fn ModuleLoader::load(
  self : ModuleLoader,
  path : String,
) -> Result[@core.Source, ResolveError] {
  match self.sources.get(path) {
    Some(s) => Ok(s)
    None => Err(IoError(path=path, message="filesystem IO not yet wired"))
  }
}
