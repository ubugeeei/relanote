// White-box tests for the resolver. The parser currently doesn't parse
// `import` statements, so we cannot exercise recursive resolution
// end-to-end yet; instead we exercise each piece the resolver owns
// directly — caching, IO error reporting, insertion-order iteration,
// and circular-dependency detection (the last one via the `resolving`
// set since we cannot synthesise an `Item::Import` through the parser).

///|
test "load on an unknown path raises IoError" {
  let loader = ModuleLoader::new("/")
  match loader.load("/missing.rela") {
    Ok(_) => abort("expected IoError")
    Err(IoError(_)) => ()
    Err(_) => abort("expected IoError variant specifically")
  }
}

///|
test "registered sources resolve and load" {
  let loader = ModuleLoader::new("/proj")
  let source = @core.Source::from_string("a", "")
  loader.add_source("/proj/a.rela", source)
  assert_true(loader.resolve_path("a") == Some("/proj/a.rela"))
  match loader.load("/proj/a.rela") {
    Ok(_) => ()
    Err(_) => abort("registered source should load")
  }
}

///|
test "unknown module yields ModuleNotFound" {
  let r = ModuleResolver::new("/proj")
  match r.resolve("nope") {
    Ok(_) => abort("expected ModuleNotFound")
    Err(ModuleNotFound(_)) => ()
    Err(_) => abort("expected ModuleNotFound variant specifically")
  }
}

///|
test "resolve caches on the second call" {
  let r = ModuleResolver::new("/proj")
  r.loader.add_source("/proj/a.rela", @core.Source::from_string("a", ""))
  match r.resolve("a") {
    Ok(_) => ()
    Err(_) => abort("first resolve should succeed")
  }
  match r.resolve("a") {
    Ok(_) => ()
    Err(_) => abort("second resolve should hit the cache and succeed")
  }
  assert_eq(r.modules().length(), 1)
}

///|
test "modules() returns modules in resolution order" {
  let r = ModuleResolver::new("/proj")
  r.loader.add_source("/proj/a.rela", @core.Source::from_string("a", ""))
  r.loader.add_source("/proj/b.rela", @core.Source::from_string("b", ""))
  let _ = r.resolve("a")
  let _ = r.resolve("b")
  let mods = r.modules()
  assert_eq(mods.length(), 2)
  assert_eq(mods[0].source().name(), "a")
  assert_eq(mods[1].source().name(), "b")
}

///|
test "currently-resolving paths are reported as circular" {
  // Synthesise the mid-traversal state directly so the test exercises
  // the resolver's `resolving` set without depending on parser output.
  let r = ModuleResolver::new("/proj")
  r.loader.add_source("/proj/a.rela", @core.Source::from_string("a", ""))
  r.resolving.add("a")
  match r.resolve("a") {
    Ok(_) => abort("expected CircularDependency")
    Err(CircularDependency(_)) => ()
    Err(_) => abort("expected CircularDependency variant specifically")
  }
}

///|
test "resolve follows imports to dependencies" {
  let r = ModuleResolver::new("/proj")
  r.loader.add_source(
    "/proj/main.rela",
    @core.Source::from_string("main", "import foo from \"dep\"\n"),
  )
  r.loader.add_source("/proj/dep.rela", @core.Source::from_string("dep", ""))
  match r.resolve("main") {
    Ok(_) => ()
    Err(_) => abort("resolution should succeed end-to-end")
  }
  let mods = r.modules()
  assert_eq(mods.length(), 2)
  // The dependency is inserted before the importer, matching legacy's
  // `IndexMap`-backed iteration order.
  assert_eq(mods[0].source().name(), "dep")
  assert_eq(mods[1].source().name(), "main")
}

///|
test "two-module import cycle is reported as circular" {
  let r = ModuleResolver::new("/proj")
  r.loader.add_source(
    "/proj/a.rela",
    @core.Source::from_string("a", "import foo from \"b\"\n"),
  )
  r.loader.add_source(
    "/proj/b.rela",
    @core.Source::from_string("b", "import foo from \"a\"\n"),
  )
  match r.resolve("a") {
    Ok(_) => abort("expected CircularDependency for a → b → a")
    Err(CircularDependency(_)) => ()
    Err(_) => abort("expected CircularDependency variant specifically")
  }
}
