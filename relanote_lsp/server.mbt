///|
/// Relanote LSP server. The server owns the parser / formatter facade
/// and JSON-RPC request handling shared by editor integrations.
///
/// Tracked in #12.
pub struct RelanoteLanguageServer {
  version : Int
  documents : @hashmap.HashMap[String, String]
}

///|
pub fn RelanoteLanguageServer::new() -> RelanoteLanguageServer {
  { version: 0, documents: @hashmap.HashMap([]) }
}

///|
pub fn RelanoteLanguageServer::version(self : RelanoteLanguageServer) -> Int {
  self.version
}

///|
pub fn RelanoteLanguageServer::open_document(
  self : RelanoteLanguageServer,
  uri : String,
  content : String,
) -> Unit {
  self.documents.set(uri, content)
}

///|
pub fn RelanoteLanguageServer::document(
  self : RelanoteLanguageServer,
  uri : String,
) -> String? {
  self.documents.get(uri)
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
/// Start the native stdio LSP server.
pub async fn run_server() -> Unit {
  let server = RelanoteLanguageServer::new()
  server_stdio(server)
}

///|
async fn server_stdio(server : RelanoteLanguageServer) -> Unit {
  match read_stdio_body() {
    None => return
    Some(body) => {
      match server.handle_body(body) {
        Some(frame) => @stdio.stdout.write(frame)
        None => ()
      }
      if should_exit(body) {
        return
      }
      server_stdio(server)
    }
  }
}

///|
async fn read_stdio_body() -> String? {
  match @stdio.stdin.read_until("\r\n\r\n") {
    None => None
    Some(header) => {
      let len = parse_content_length(header)
      if len <= 0 {
        return Some("")
      }
      let bytes = @stdio.stdin.read_exactly(len) catch {
        _ => return None
      }
      Some(@utf8.decode(bytes))
    }
  }
}

///|
fn should_exit(body : String) -> Bool {
  let parsed : Result[Json, @json.ParseError] = try? @json.parse(body)
  match parsed {
    Ok(request) =>
      match json_value(request, "method") {
        Some(String("exit")) => true
        _ => false
      }
    Err(_) => false
  }
}
