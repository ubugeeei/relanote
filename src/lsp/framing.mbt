///|
/// JSON-RPC frame parser / encoder. LSP messages over stdio are
/// prefixed with one or more headers (`Content-Length: N\r\n`,
/// optionally `Content-Type: application/vscode-jsonrpc;charset=utf-8`),
/// terminated by a blank line, followed by `N` bytes of JSON body.
///
/// `read_frame` consumes a complete frame from the supplied buffer and
/// returns the JSON body plus the number of bytes consumed (so callers
/// can shift the buffer). `encode_frame` produces the framed bytes for
/// a JSON body, ready to push onto stdout.
///
/// Both helpers operate on pure byte buffers so the same logic backs
/// the real stdio loop (once MoonBit grows host stdin support) and the
/// in-memory tests.

///|
pub struct Frame {
  body : String
  consumed : Int
}

///|
pub fn Frame::new(body : String, consumed : Int) -> Frame {
  { body, consumed }
}

///|
pub fn Frame::body(self : Frame) -> String {
  self.body
}

///|
pub fn Frame::consumed(self : Frame) -> Int {
  self.consumed
}

///|
/// Read a single LSP frame from `buffer`, starting at the beginning.
/// Returns `None` when the buffer doesn't yet contain a full frame
/// (the caller should read more data and retry).
pub fn read_frame(buffer : String) -> Frame? {
  // Find the `\r\n\r\n` that terminates the header block.
  let mut header_end : Int? = None
  let mut i = 0
  while i + 3 < buffer.length() {
    let a = buffer.unsafe_get(i) == '\r'
    let b = buffer.unsafe_get(i + 1) == '\n'
    let c = buffer.unsafe_get(i + 2) == '\r'
    let d = buffer.unsafe_get(i + 3) == '\n'
    if a && b && c && d {
      header_end = Some(i)
      break
    }
    i += 1
  }
  match header_end {
    None => None
    Some(end) => {
      let header = buffer[0:end].to_owned()
      let content_length = parse_content_length(header)
      let body_start = end + 4
      if body_start + content_length > buffer.length() {
        None
      } else {
        let body = buffer[body_start:body_start + content_length].to_owned()
        Some(Frame::new(body, body_start + content_length))
      }
    }
  }
}

///|
/// Encode a JSON body as a complete LSP frame, ready to push onto
/// stdout.
pub fn encode_frame(body : String) -> String {
  let buf = StringBuilder::new()
  buf.write_string("Content-Length: ")
  buf.write_string(body.length().to_string())
  buf.write_string("\r\n\r\n")
  buf.write_string(body)
  buf.to_string()
}

///|
/// Pick the `Content-Length: N` header out of the headers block.
/// Returns 0 when the header is missing or malformed; callers can
/// short-circuit those frames as invalid before parsing the body.
pub fn parse_content_length(header : String) -> Int {
  // Headers are separated by `\r\n`; split manually so we don't pull
  // in the regex dependency.
  let lines : Array[String] = []
  let mut start = 0
  let mut i = 0
  while i + 1 < header.length() {
    let cr = header.unsafe_get(i) == '\r'
    let lf = header.unsafe_get(i + 1) == '\n'
    if cr && lf {
      lines.push(header[start:i].to_owned())
      start = i + 2
      i += 2
    } else {
      i += 1
    }
  }
  if start < header.length() {
    lines.push(header[start:header.length()].to_owned())
  }
  for line in lines {
    if line.has_prefix("Content-Length:") || line.has_prefix("Content-Length :") {
      let colon = find_char(line, ':')
      if colon < 0 {
        return 0
      }
      let value = trim(line[colon + 1:line.length()].to_owned())
      let parsed : Result[Int, _] = try? @string.parse_int(value)
      match parsed {
        Ok(n) => return n
        Err(_) => return 0
      }
    }
  }
  0
}

///|
fn find_char(s : String, c : Char) -> Int {
  let target = c.to_int()
  let mut i = 0
  while i < s.length() {
    if s.unsafe_get(i).to_int() == target {
      return i
    }
    i += 1
  }
  -1
}

///|
fn trim(s : String) -> String {
  let mut start = 0
  let mut end = s.length()
  while start < end {
    let c = s.unsafe_get(start)
    if c == ' ' || c == '\t' {
      start += 1
    } else {
      break
    }
  }
  while end > start {
    let c = s.unsafe_get(end - 1)
    if c == ' ' || c == '\t' || c == '\r' || c == '\n' {
      end -= 1
    } else {
      break
    }
  }
  s[start:end].to_owned()
}
