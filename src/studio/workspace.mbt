///|
pub fn has_name(names : Array[String], name : String) -> Bool {
  for n in names {
    if n == name {
      return true
    }
  }
  false
}

///|
pub fn ensure_name(names : Array[String], name : String) -> Array[String] {
  let out : Array[String] = []
  for n in names {
    out.push(n)
  }
  if !has_name(out, name) {
    out.push(name)
  }
  out
}

///|
pub fn remove_name(names : Array[String], name : String) -> Array[String] {
  let out : Array[String] = []
  for n in names {
    if n != name {
      out.push(n)
    }
  }
  out
}

///|
pub fn first_name(names : Array[String]) -> String {
  if names.length() == 0 {
    "main.rela"
  } else {
    names[0]
  }
}

///|
pub fn join_lines(lines : Array[String]) -> String {
  let mut out = ""
  for line in lines {
    out = if out.is_empty() { line } else { out + "\n" + line }
  }
  out
}
