///|
/// A source file. The `line_starts` table is precomputed so `location` is
/// `O(log n)` for a byte offset.
pub struct Source {
  id : SourceId
  name : String
  content : String
  line_starts : Array[Int]
}

///|
/// Compute the table of line-start offsets for `content`.
fn compute_line_starts(content : String) -> Array[Int] {
  let starts = [0]
  let len = content.length()
  let mut i = 0
  while i < len {
    if content.unsafe_get(i) == '\n' {
      starts.push(i + 1)
    }
    i += 1
  }
  starts
}

///|
pub fn Source::new(id : SourceId, name : String, content : String) -> Source {
  let line_starts = compute_line_starts(content)
  { id, name, content, line_starts }
}

///|
/// Convenience constructor for tests and the REPL — attaches a dummy source
/// id, which `Span` is happy to carry around.
pub fn Source::from_string(name : String, content : String) -> Source {
  Source::new(SourceId::dummy(), name, content)
}

///|
pub fn Source::id(self : Source) -> SourceId {
  self.id
}

///|
pub fn Source::name(self : Source) -> String {
  self.name
}

///|
pub fn Source::content(self : Source) -> String {
  self.content
}

///|
pub fn Source::line_count(self : Source) -> Int {
  self.line_starts.length()
}

///|
/// Return the 1-based line and column for a byte offset, matching the legacy
/// implementation's behaviour.
pub fn Source::location(self : Source, offset : Int) -> Location {
  // Binary search for the largest line index whose start <= offset.
  let mut lo = 0
  let mut hi = self.line_starts.length()
  while lo < hi {
    let mid = (lo + hi) / 2
    if self.line_starts[mid] <= offset {
      lo = mid + 1
    } else {
      hi = mid
    }
  }
  let line_idx = if lo == 0 { 0 } else { lo - 1 }
  let line_start = self.line_starts[line_idx]
  let column = offset - line_start + 1
  Location::new(line_idx + 1, column)
}

///|
/// Return the content of a specific (1-based) line, trimmed of its trailing
/// newline. Returns `None` when the line is out of range.
pub fn Source::line(self : Source, line : Int) -> String? {
  if line <= 0 || line > self.line_starts.length() {
    return None
  }
  let start = self.line_starts[line - 1]
  let end = if line < self.line_starts.length() {
    self.line_starts[line]
  } else {
    self.content.length()
  }
  let slice = self.content[start:end].to_owned()
  // Trim a single trailing '\n' if present, like the previous version does.
  let n = slice.length()
  if n > 0 && slice.unsafe_get(n - 1) == '\n' {
    Some(slice[0:n - 1].to_owned())
  } else {
    Some(slice)
  }
}
