///|
fn RelanoteLanguageServer::did_open(
  self : RelanoteLanguageServer,
  params : Json?,
) -> Json? {
  self.store_document(params)
  self.publish_diagnostics(params)
}

///|
fn RelanoteLanguageServer::did_change(
  self : RelanoteLanguageServer,
  params : Json?,
) -> Json? {
  match (extract_uri(params), extract_change_text(params)) {
    (Some(uri), Some(text)) => self.open_document(uri, text)
    _ => ()
  }
  self.publish_diagnostics(params)
}

///|
fn RelanoteLanguageServer::store_document(
  self : RelanoteLanguageServer,
  params : Json?,
) -> Unit {
  match extract_uri_and_text(params) {
    Some((uri, text)) => self.open_document(uri, text)
    None => ()
  }
}

///|
fn RelanoteLanguageServer::resolve_uri_and_text(
  self : RelanoteLanguageServer,
  params : Json?,
) -> (String, String)? {
  match extract_uri_and_text(params) {
    Some(found) => Some(found)
    None =>
      match extract_uri(params) {
        Some(uri) =>
          match self.document(uri) {
            Some(text) => Some((uri, text))
            None => None
          }
        None => None
      }
  }
}

///|
fn RelanoteLanguageServer::publish_diagnostics(
  self : RelanoteLanguageServer,
  params : Json?,
) -> Json? {
  match self.resolve_uri_and_text(params) {
    None => None
    Some((uri, text)) => {
      let items : Array[Json] = []
      for d in self.diagnose(uri, text).items() {
        items.push(diagnostic_to_json(d))
      }
      let payload : Map[String, Json] = {
        "uri": Json::string(uri),
        "diagnostics": Json::array(items),
      }
      let envelope : Map[String, Json] = {
        "jsonrpc": Json::string("2.0"),
        "method": Json::string("textDocument/publishDiagnostics"),
        "params": Json::object(payload),
      }
      Some(Json::object(envelope))
    }
  }
}

///|
fn extract_uri(params : Json?) -> String? {
  match params {
    Some(p) =>
      match json_value(p, "textDocument") {
        Some(d) =>
          match json_value(d, "uri") {
            Some(u) => json_string(u)
            None => None
          }
        None => None
      }
    None => None
  }
}

///|
fn extract_change_text(params : Json?) -> String? {
  match params {
    Some(p) =>
      match json_value(p, "contentChanges") {
        Some(Array(changes)) =>
          if changes.length() == 0 {
            None
          } else {
            match json_value(changes[changes.length() - 1], "text") {
              Some(text) => json_string(text)
              None => None
            }
          }
        _ => None
      }
    None => None
  }
}
