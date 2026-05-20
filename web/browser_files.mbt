///|
pub fn download_text(name : String, text : String) -> Unit {
  let parts = @js.new_array()
  parts._call("push", [@js.any(text)]) |> ignore
  download_blob(name, @js.new(g()["Blob"], [parts, blob_options("text/plain")]))
}

///|
pub fn download_bytes(name : String, bytes : Array[Byte]) -> Unit {
  let raw = @js.new(g()["Uint8Array"], [@js.any(bytes)])
  let parts = @js.new_array()
  parts._call("push", [raw]) |> ignore
  download_blob(name, @js.new(g()["Blob"], [parts, blob_options("audio/midi")]))
}

///|
fn blob_options(type_ : String) -> @js.Any {
  let opts = @js.new_object()
  opts["type"] = @js.any(type_)
  opts
}

///|
fn download_blob(name : String, blob : @js.Any) -> Unit {
  let url = g()["URL"]._call("createObjectURL", [blob])
  let a = g()["document"]._call("createElement", [@js.any("a")])
  a["href"] = url
  a["download"] = @js.any(name)
  a._call("click", []) |> ignore
  g()["URL"]._call("revokeObjectURL", [url]) |> ignore
}

///|
pub fn download_project(
  names : Array[String],
  active : String,
  source : String,
) -> Unit {
  save_file(active, source)
  let files = @js.new_array()
  for name in names {
    let item = @js.new_object()
    item["name"] = @js.any(name)
    item["content"] = @js.any(load_file(name, ""))
    files._call("push", [item]) |> ignore
  }
  let project = @js.new_object()
  project["active"] = @js.any(active)
  project["files"] = files
  download_text("relanote-project.json", @js.json_stringify(project))
}

///|
pub fn import_rela(on_load : (String, String) -> Unit) -> Unit {
  let input = g()["document"]._call("createElement", [@js.any("input")])
  input["type"] = @js.any("file")
  input["accept"] = @js.any(".rela,.txt")
  input["onchange"] = @js.from_fn0(fn() {
    let file = input["files"]._get_by_index(0)
    if !@js.is_nullish(file) {
      file
      ._call("text", [])
      ._call("then", [
        @js.from_fn1(fn(text : @js.Any) {
          on_load(file["name"].cast(), text.cast())
        }),
      ])
      |> ignore
    }
  })
  input._call("click", []) |> ignore
}
