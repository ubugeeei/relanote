// Skeleton tests for the resolver. The actual parser is still a stub so
// `resolve` returns an empty `Program` with the placeholder diagnostic
// from `relanote_parser`; the focus here is on the moving parts the
// resolver itself owns — caching, IO error reporting, circular-dependency
// detection.

test "load on an unknown path raises IoError" {
  let loader = ModuleLoader::new("/")
  match loader.load("/missing.rela") {
    Ok(_) => abort("expected IoError")
    Err(IoError(_)) => ()
    Err(_) => abort("expected IoError variant specifically")
  }
}

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

test "unknown module yields ModuleNotFound" {
  let r = ModuleResolver::new("/proj")
  match r.resolve("nope") {
    Ok(_) => abort("expected ModuleNotFound")
    Err(ModuleNotFound(_)) => ()
    Err(_) => abort("expected ModuleNotFound variant specifically")
  }
}
