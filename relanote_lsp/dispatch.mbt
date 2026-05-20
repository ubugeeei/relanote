///|
/// LSP method dispatcher. Dispatch is intentionally synchronous and
/// operates over a parsed `Json` request body.
///
/// `handle_request` takes a parsed JSON-RPC envelope and returns the
/// JSON body of the response — or `None` for notifications, which
/// don't get a reply.
///
/// Supported methods:
///   - `initialize` → returns minimal `ServerCapabilities`
///   - `initialized` (notification) → no-op
///   - `shutdown` → returns `null`
///   - `exit` (notification) → no-op
///   - `textDocument/diagnostic` → runs the parser, returns
///     `{ kind: "full", items: [...] }`
///   - `textDocument/formatting` → formats the document, returns a
///     single full-document edit
///
/// Unknown methods return the JSON-RPC error `MethodNotFound`
/// (-32601).

///|
pub fn RelanoteLanguageServer::handle_request(
  self : RelanoteLanguageServer,
  request : Json,
) -> Json? {
  let id = json_value(request, "id")
  let method_name = match json_value(request, "method") {
    Some(m) => json_string(m)
    None => None
  }
  let params = json_value(request, "params")
  match method_name {
    Some("initialize") => Some(initialize_response(id))
    Some("initialized") => None
    Some("shutdown") => Some(shutdown_response(id))
    Some("exit") => None
    Some("textDocument/diagnostic") =>
      Some(self.diagnostic_response(id, params))
    Some("textDocument/formatting") =>
      Some(self.formatting_response(id, params))
    Some(m) => Some(method_not_found_response(id, m))
    None => None
  }
}

///|
fn initialize_response(id : Json?) -> Json {
  // Server capabilities: pull-model diagnostics + full-document formatting.
  let caps : Map[String, Json] = {
    "textDocumentSync": Json::number(1.0),
    "diagnosticProvider": Json::object({
      "interFileDependencies": Json::boolean(false),
      "workspaceDiagnostics": Json::boolean(false),
    }),
    "documentFormattingProvider": Json::boolean(true),
  }
  let server_info : Map[String, Json] = {
    "name": Json::string("relanote-lsp"),
    "version": Json::string("0.1.0"),
  }
  let result : Map[String, Json] = {
    "capabilities": Json::object(caps),
    "serverInfo": Json::object(server_info),
  }
  wrap_response(id, Json::object(result))
}

///|
fn shutdown_response(id : Json?) -> Json {
  wrap_response(id, Json::null())
}

///|
fn json_value(json : Json, key : String) -> Json? {
  if json is Object(obj) {
    obj.get(key)
  } else {
    None
  }
}

///|
fn json_string(json : Json) -> String? {
  if json is String(s) {
    Some(s)
  } else {
    None
  }
}

///|
fn RelanoteLanguageServer::diagnostic_response(
  self : RelanoteLanguageServer,
  id : Json?,
  params : Json?,
) -> Json {
  let uri_content = extract_uri_and_text(params)
  let diagnostics = match uri_content {
    Some((uri, text)) => self.diagnose(uri, text)
    None => @core.Diagnostics::new()
  }
  let items : Array[Json] = []
  for d in diagnostics.items() {
    items.push(diagnostic_to_json(d))
  }
  let result : Map[String, Json] = {
    "kind": Json::string("full"),
    "items": Json::array(items),
  }
  wrap_response(id, Json::object(result))
}

///|
fn RelanoteLanguageServer::formatting_response(
  self : RelanoteLanguageServer,
  id : Json?,
  params : Json?,
) -> Json {
  let uri_content = extract_uri_and_text(params)
  let formatted = match uri_content {
    Some((uri, text)) => self.format(uri, text)
    None => ""
  }
  // A single edit replacing the whole document with the formatted body.
  let range : Map[String, Json] = {
    "start": Json::object({
      "line": Json::number(0.0),
      "character": Json::number(0.0),
    }),
    // The LSP spec lets servers send a huge end line/character to
    // mean "until end of file"; pick the largest 32-bit value the
    // client can round-trip through f64 without precision loss.
    "end": Json::object({
      "line": Json::number(2147483647.0),
      "character": Json::number(2147483647.0),
    }),
  }
  let edit : Map[String, Json] = {
    "range": Json::object(range),
    "newText": Json::string(formatted),
  }
  wrap_response(id, Json::array([Json::object(edit)]))
}

///|
fn method_not_found_response(id : Json?, method_name : String) -> Json {
  let error : Map[String, Json] = {
    "code": Json::number(-32601.0),
    "message": Json::string("method not found: " + method_name),
  }
  let envelope : Map[String, Json] = {
    "jsonrpc": Json::string("2.0"),
    "id": id.unwrap_or(Json::null()),
    "error": Json::object(error),
  }
  Json::object(envelope)
}

///|
fn wrap_response(id : Json?, result : Json) -> Json {
  let envelope : Map[String, Json] = {
    "jsonrpc": Json::string("2.0"),
    "id": id.unwrap_or(Json::null()),
    "result": result,
  }
  Json::object(envelope)
}

///|
fn extract_uri_and_text(params : Json?) -> (String, String)? {
  match params {
    None => None
    Some(p) => {
      let td = json_value(p, "textDocument")
      let uri = match td {
        Some(d) =>
          match json_value(d, "uri") {
            Some(u) => json_string(u)
            None => None
          }
        None => None
      }
      let text = match td {
        Some(d) =>
          match json_value(d, "text") {
            Some(t) => json_string(t)
            None => None
          }
        None => None
      }
      match (uri, text) {
        (Some(u), Some(t)) => Some((u, t))
        _ => None
      }
    }
  }
}

///|
/// Lower a `@core.Diagnostic` to the LSP `Diagnostic` JSON shape.
fn diagnostic_to_json(d : @core.Diagnostic) -> Json {
  let severity = match d.kind() {
    @core.Error => 1.0
    @core.Warning => 2.0
    @core.Info => 3.0
    @core.Hint => 4.0
  }
  // LSP Position is 0-based; our spans are byte offsets without line
  // info attached, so we emit a placeholder line/character of 0. The
  // ariadne-style reporter is the source of truth for human-readable
  // output; this JSON shape is what tooling (editors) consume.
  let range : Map[String, Json] = {
    "start": Json::object({
      "line": Json::number(0.0),
      "character": Json::number(d.span().start().to_double()),
    }),
    "end": Json::object({
      "line": Json::number(0.0),
      "character": Json::number(d.span().end().to_double()),
    }),
  }
  let obj : Map[String, Json] = {
    "range": Json::object(range),
    "severity": Json::number(severity),
    "message": Json::string(d.message()),
    "source": Json::string("relanote"),
  }
  Json::object(obj)
}
