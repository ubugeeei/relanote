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
