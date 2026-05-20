///|
const KEY_FILES : String = "relanote.files"

///|
const KEY_ACTIVE : String = "relanote.active"

///|
fn g() -> @js.Any {
  @js.global_this()
}

///|
fn storage_get(key : String) -> String? {
  let store = g()["localStorage"]
  if @js.is_nullish(store) {
    None
  } else {
    @js.identity_option(store._call("getItem", [@js.any(key)]))
  }
}

///|
fn storage_set(key : String, value : String) -> Unit {
  let store = g()["localStorage"]
  if !@js.is_nullish(store) {
    store._call("setItem", [@js.any(key), @js.any(value)]) |> ignore
  }
}

///|
pub fn load_file_names() -> Array[String] {
  match storage_get(KEY_FILES) {
    Some(text) => @js.json_parse(text).cast()
    None => ["main.rela"]
  }
}

///|
pub fn save_file_names(names : Array[String]) -> Unit {
  storage_set(KEY_FILES, @js.json_stringify(@js.any(names)))
}

///|
pub fn load_active_name() -> String {
  storage_get(KEY_ACTIVE).unwrap_or("main.rela")
}

///|
pub fn save_active_name(name : String) -> Unit {
  storage_set(KEY_ACTIVE, name)
}

///|
fn file_key(name : String) -> String {
  "relanote.file." + name
}

///|
pub fn load_file(name : String, fallback : String) -> String {
  storage_get(file_key(name)).unwrap_or(fallback)
}

///|
pub fn save_file(name : String, source : String) -> Unit {
  storage_set(file_key(name), source)
}

///|
pub fn delete_file(name : String) -> Unit {
  let store = g()["localStorage"]
  if !@js.is_nullish(store) {
    store._call("removeItem", [@js.any(file_key(name))]) |> ignore
  }
}

///|
pub fn prompt_text(label : String, fallback : String) -> String? {
  let prompt = g()["prompt"]
  if @js.is_nullish(prompt) {
    None
  } else {
    @js.identity_option(prompt._invoke([@js.any(label), @js.any(fallback)]))
  }
}

///|
pub fn read_shared_code() -> String? {
  let loc = g()["location"]
  if @js.is_nullish(loc) {
    return None
  }
  let search = loc["search"]
  let params = @js.new(g()["URLSearchParams"], [search])
  let raw : String? = @js.identity_option(
    params._call("get", [@js.any("code")]),
  )
  match raw {
    Some(code) =>
      Some(
        g()
        ._call("decodeURIComponent", [g()._call("atob", [@js.any(code)])])
        .cast(),
      )
    None => None
  }
}

///|
pub fn share_code(source : String) -> String {
  let code : String = g()
    ._call("btoa", [g()._call("encodeURIComponent", [@js.any(source)])])
    .cast()
  let loc = g()["location"]
  let url : String = loc["origin"].cast() +
    loc["pathname"].cast() +
    "?code=" +
    code
  g()["history"]._call("replaceState", [
    @js.null(),
    @js.any(""),
    @js.any("?code=" + code),
  ])
  |> ignore
  let clip = g()["navigator"]["clipboard"]
  if !@js.is_nullish(clip) {
    clip._call("writeText", [@js.any(url)]) |> ignore
  }
  url
}
