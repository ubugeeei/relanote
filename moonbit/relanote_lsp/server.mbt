///|
/// Relanote LSP server. The Rust crate is built on `tower-lsp` + `tokio`;
/// MoonBit has no standard async runtime today, so the eventual port
/// will be a hand-rolled JSON-RPC framing loop over sync stdio.
///
/// This skeleton lands the public surface so:
///
/// 1. Consumers (the VS Code extension, the CLI's `lsp` subcommand)
///    have something stable to depend on, and
/// 2. The follow-up port can land without churn on call sites.
///
/// Tracked in #12.
pub struct RelanoteLanguageServer {
  // Holds nothing today — the eventual server will own a document
  // workspace, a diagnostic cache and a request dispatcher.
  version : Int
}

///|
pub fn RelanoteLanguageServer::new() -> RelanoteLanguageServer {
  { version: 0 }
}

///|
pub fn RelanoteLanguageServer::version(
  self : RelanoteLanguageServer,
) -> Int {
  self.version
}

///|
/// Parse the document at `uri` and return any parser diagnostics.
/// Skeleton: just runs the parser-skeleton against the source so the
/// caller can verify wiring.
pub fn RelanoteLanguageServer::diagnose(
  self : RelanoteLanguageServer,
  uri : String,
  content : String,
) -> @core.Diagnostics {
  let _ = self
  let (_, diagnostics) = @parser.parse_string(uri, content)
  diagnostics
}

///|
/// Format the document at `uri` with the default formatter config.
/// Skeleton: delegates to `relanote_format::format`, which currently
/// returns the empty string.
pub fn RelanoteLanguageServer::format(
  self : RelanoteLanguageServer,
  uri : String,
  content : String,
) -> String {
  let _ = self
  let (program, _) = @parser.parse_string(uri, content)
  @format.format(program, @format.FormatConfig::default())
}

///|
/// Start the LSP server. The Rust crate's `run_server` is an `async fn`
/// driven by `tokio`; the MoonBit skeleton is a no-op — the real loop
/// will read JSON-RPC frames from stdin once the framing layer lands.
pub fn run_server() -> Unit {
  // TODO(#12): JSON-RPC framing + dispatch over sync stdio.
  ()
}
