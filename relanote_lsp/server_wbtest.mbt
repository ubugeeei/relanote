///|
test "diagnose feeds the parser and reports its diagnostics" {
  let s = RelanoteLanguageServer::new()
  // Clean source produces no diagnostics now that the parser is real.
  let clean = s.diagnose("file.rela", "let x = 1")
  assert_false(clean.has_errors())
  assert_eq(clean.error_count(), 0)
  // Malformed source is surfaced as diagnostics on the same channel.
  let broken = s.diagnose("file.rela", "let x 1")
  assert_true(broken.has_errors())
}

///|
test "format runs the printer on the parsed program" {
  let s = RelanoteLanguageServer::new()
  let out = s.format("file.rela", "let x = 1")
  assert_eq(out, "let x = 1\n")
}

///|
test "handle_body replies with an encoded initialize frame" {
  let s = RelanoteLanguageServer::new()
  let body = "{\"jsonrpc\":\"2.0\",\"id\":1,\"method\":\"initialize\",\"params\":{}}"
  match s.handle_body(body) {
    Some(frame) =>
      match read_frame(frame) {
        Some(decoded) => {
          let response = @json.parse(decoded.body())
          match json_value(response, "result") {
            Some(result) =>
              match json_value(result, "capabilities") {
                Some(_) => ()
                None => abort("expected capabilities in result")
              }
            None => abort("expected a result field")
          }
        }
        None => abort("expected an encoded response frame")
      }
    None => abort("initialize should produce a response")
  }
}

// ----------------------------------------------------------------------
// JSON-RPC framing
// ----------------------------------------------------------------------

///|
test "encode_frame prefixes the body with Content-Length" {
  let framed = encode_frame("{\"jsonrpc\":\"2.0\"}")
  assert_true(framed.has_prefix("Content-Length: 17\r\n\r\n"))
  assert_true(framed.contains("{\"jsonrpc\":\"2.0\"}"))
}

///|
test "read_frame parses a complete frame" {
  let raw = encode_frame("{\"id\":1}")
  match read_frame(raw) {
    Some(f) => {
      assert_eq(f.body(), "{\"id\":1}")
      assert_eq(f.consumed(), raw.length())
    }
    None => abort("expected a complete frame")
  }
}

///|
test "read_frame returns None when the buffer is incomplete" {
  // Header alone, no body yet.
  let partial = "Content-Length: 42\r\n\r\n"
  match read_frame(partial) {
    None => ()
    Some(_) => abort("partial buffer should not yield a frame")
  }
}

// ----------------------------------------------------------------------
// JSON-RPC dispatch
// ----------------------------------------------------------------------

///|
test "initialize returns ServerCapabilities" {
  let s = RelanoteLanguageServer::new()
  let request = @json.parse(
    "{\"jsonrpc\":\"2.0\",\"id\":1,\"method\":\"initialize\",\"params\":{}}",
  )
  match s.handle_request(request) {
    Some(response) =>
      match json_value(response, "result") {
        Some(result) =>
          match json_value(result, "capabilities") {
            Some(_) => ()
            None => abort("expected capabilities in result")
          }
        None => abort("expected a result field")
      }
    None => abort("initialize should produce a response")
  }
}

///|
test "shutdown returns null result" {
  let s = RelanoteLanguageServer::new()
  let request = @json.parse(
    "{\"jsonrpc\":\"2.0\",\"id\":2,\"method\":\"shutdown\"}",
  )
  match s.handle_request(request) {
    Some(response) =>
      match json_value(response, "result") {
        Some(Null) => ()
        Some(_) => abort("expected null result")
        None => abort("expected a result field")
      }
    None => abort("shutdown should produce a response")
  }
}

///|
test "initialized is a notification (no response)" {
  let s = RelanoteLanguageServer::new()
  let request = @json.parse("{\"jsonrpc\":\"2.0\",\"method\":\"initialized\"}")
  match s.handle_request(request) {
    None => ()
    Some(_) => abort("notifications should not produce a response")
  }
}

///|
test "unknown method returns MethodNotFound (-32601)" {
  let s = RelanoteLanguageServer::new()
  let request = @json.parse(
    "{\"jsonrpc\":\"2.0\",\"id\":3,\"method\":\"telepathy/sense\"}",
  )
  match s.handle_request(request) {
    Some(response) =>
      match json_value(response, "error") {
        Some(err) =>
          match json_value(err, "code") {
            Some(Number(-32601.0, ..)) => ()
            _ => abort("expected code -32601")
          }
        None => abort("expected an error field")
      }
    None => abort("unknown method should produce an error response")
  }
}

///|
test "textDocument/diagnostic returns full-kind report" {
  let s = RelanoteLanguageServer::new()
  let request = @json.parse(
    "{\"jsonrpc\":\"2.0\",\"id\":4,\"method\":\"textDocument/diagnostic\",\"params\":{\"textDocument\":{\"uri\":\"file:///x.rela\",\"text\":\"let x 1\"}}}",
  )
  match s.handle_request(request) {
    Some(response) =>
      match json_value(response, "result") {
        Some(result) =>
          match json_value(result, "kind") {
            Some(String("full")) => ()
            _ => abort("expected kind=full")
          }
        None => abort("expected a result field")
      }
    None => abort("diagnostic should produce a response")
  }
}

///|
test "didOpen stores text and publishes diagnostics" {
  let s = RelanoteLanguageServer::new()
  let request = @json.parse(
    "{\"jsonrpc\":\"2.0\",\"method\":\"textDocument/didOpen\",\"params\":{\"textDocument\":{\"uri\":\"file:///x.rela\",\"text\":\"let x 1\"}}}",
  )
  match s.handle_request(request) {
    Some(response) =>
      match json_value(response, "method") {
        Some(String("textDocument/publishDiagnostics")) => ()
        _ => abort("expected publishDiagnostics notification")
      }
    None => abort("didOpen should publish diagnostics")
  }
  match s.document("file:///x.rela") {
    Some("let x 1") => ()
    _ => abort("document text should be stored")
  }
}

///|
test "didChange updates text for later formatting request" {
  let s = RelanoteLanguageServer::new()
  let open = @json.parse(
    "{\"jsonrpc\":\"2.0\",\"method\":\"textDocument/didOpen\",\"params\":{\"textDocument\":{\"uri\":\"file:///x.rela\",\"text\":\"let x=1\"}}}",
  )
  ignore(s.handle_request(open))
  let change = @json.parse(
    "{\"jsonrpc\":\"2.0\",\"method\":\"textDocument/didChange\",\"params\":{\"textDocument\":{\"uri\":\"file:///x.rela\"},\"contentChanges\":[{\"text\":\"let x = 2\"}]}}",
  )
  ignore(s.handle_request(change))
  let fmt = @json.parse(
    "{\"jsonrpc\":\"2.0\",\"id\":9,\"method\":\"textDocument/formatting\",\"params\":{\"textDocument\":{\"uri\":\"file:///x.rela\"}}}",
  )
  match s.handle_request(fmt) {
    Some(response) =>
      match json_value(response, "result") {
        Some(Array(edits)) => assert_true(edits.length() > 0)
        _ => abort("expected formatting edits")
      }
    None => abort("formatting should return edits")
  }
}

///|
test "handle_body returns parse error frame for invalid json" {
  let s = RelanoteLanguageServer::new()
  match s.handle_body("{") {
    Some(frame) =>
      match read_frame(frame) {
        Some(decoded) => assert_true(decoded.body().contains("-32700"))
        None => abort("expected parse error frame")
      }
    None => abort("invalid json should produce a response")
  }
}
