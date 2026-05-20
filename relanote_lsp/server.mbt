///|
/// Relanote LSP server. The server owns the parser / formatter facade
/// and JSON-RPC request handling shared by editor integrations.
///
/// Tracked in #12.
pub struct RelanoteLanguageServer {
  version : Int
}

///|
pub fn RelanoteLanguageServer::new() -> RelanoteLanguageServer {
  { version: 0 }
}

///|
pub fn RelanoteLanguageServer::version(self : RelanoteLanguageServer) -> Int {
  self.version
}

///|
/// Parse the document at `uri` and return any parser diagnostics.
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
/// Handle one JSON-RPC body. Notifications return `None`; requests
/// return an encoded LSP frame ready for stdout.
pub fn RelanoteLanguageServer::handle_body(
  self : RelanoteLanguageServer,
  body : String,
) -> String? {
  let parsed : Result[Json, @json.ParseError] = try? @json.parse(body)
  match parsed {
    Ok(request) =>
      match self.handle_request(request) {
        Some(response) => Some(encode_frame(response.stringify()))
        None => None
      }
    Err(_) => Some(encode_frame(parse_error_response().stringify()))
  }
}

///|
fn parse_error_response() -> Json {
  let error : Map[String, Json] = {
    "code": Json::number(-32700.0),
    "message": Json::string("parse error"),
  }
  let envelope : Map[String, Json] = {
    "jsonrpc": Json::string("2.0"),
    "id": Json::null(),
    "error": Json::object(error),
  }
  Json::object(envelope)
}

///|
/// Start the LSP server.
pub fn run_server() -> Unit {
  ()
}
