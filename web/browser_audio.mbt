///|
pub fn play_sequence(json : String, tempo : Int) -> Unit {
  stop_audio()
  let audio = if @js.is_nullish(g()["AudioContext"]) {
    g()["webkitAudioContext"]
  } else {
    g()["AudioContext"]
  }
  if @js.is_nullish(audio) {
    return
  }
  let ctx = @js.new(audio, [])
  let nodes = @js.new_array()
  let notes = @js.json_parse(json)
  let len : Int = notes["length"].cast()
  let base : Double = ctx["currentTime"].cast() + 0.04
  let bps = tempo.to_double() / 60.0
  for i = 0; i < len; i = i + 1 {
    schedule_note(ctx, nodes, notes._get_by_index(i), base, bps)
  }
  g()["__relanoteNodes"] = nodes
  g()["__relanoteContext"] = ctx
}

///|
fn schedule_note(
  ctx : @js.Any,
  nodes : @js.Any,
  note : @js.Any,
  base : Double,
  bps : Double,
) -> Unit {
  let osc = ctx._call("createOscillator", [])
  let gain = ctx._call("createGain", [])
  let pitch : Int = note["pitch"].cast()
  let start : Double = note["start"].cast()
  let duration : Double = note["duration"].cast()
  let hz = 440.0 *
    g()["Math"]
    ._call("pow", [@js.any(2.0), @js.any((pitch - 69).to_double() / 12.0)])
    .cast()
  let t0 = base + start / bps
  let t1 = t0 + duration / bps
  osc["type"] = @js.any("triangle")
  osc["frequency"]["value"] = @js.any(hz)
  gain["gain"]._call("setValueAtTime", [@js.any(0.0001), @js.any(t0)]) |> ignore
  gain["gain"]._call("exponentialRampToValueAtTime", [
    @js.any(0.18),
    @js.any(t0 + 0.01),
  ])
  |> ignore
  gain["gain"]._call("exponentialRampToValueAtTime", [
    @js.any(0.0001),
    @js.any(t1),
  ])
  |> ignore
  osc._call("connect", [gain])._call("connect", [ctx["destination"]]) |> ignore
  osc._call("start", [@js.any(t0)]) |> ignore
  osc._call("stop", [@js.any(t1 + 0.03)]) |> ignore
  nodes._call("push", [osc]) |> ignore
}

///|
pub fn stop_audio() -> Unit {
  let nodes = g()["__relanoteNodes"]
  if !@js.is_nullish(nodes) {
    let len : Int = nodes["length"].cast()
    for i = 0; i < len; i = i + 1 {
      nodes._get_by_index(i)._call("stop", []) |> ignore
    }
  }
  let ctx = g()["__relanoteContext"]
  if !@js.is_nullish(ctx) {
    ctx._call("close", []) |> ignore
  }
}
