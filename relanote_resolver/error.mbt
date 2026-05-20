///|
/// Errors produced by module resolution. Mirrors
/// `relanote_resolver::error::ResolveError`. `IoError` carries a plain
/// `String` instead of `std::io::Error` because MoonBit's stdlib has no
/// uniform IO error type that lives across every target.
pub(all) enum ResolveError {
  ModuleNotFound(path~ : String)
  CircularDependency(path~ : String)
  IoError(path~ : String, message~ : String)
  ParseError(path~ : String)
}

///|
pub fn ResolveError::message(self : ResolveError) -> String {
  match self {
    ModuleNotFound(path~) => "module not found: " + path
    CircularDependency(path~) => "circular dependency detected: " + path
    IoError(path~, message~) =>
      "failed to read file: " + path + " (" + message + ")"
    ParseError(path~) => "parse error in module: " + path
  }
}
