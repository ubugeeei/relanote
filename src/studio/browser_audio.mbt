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
    schedule_note(ctx, nodes, notes._get_by_index(i), base, bps, i)
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
  lane : Int,
) -> Unit {
  let osc = ctx._call("createOscillator", [])
  let sub = ctx._call("createOscillator", [])
  let filter = ctx._call("createBiquadFilter", [])
  let gain = ctx._call("createGain", [])
  let pitch : Int = note["pitch"].cast()
  let start : Double = note["start"].cast()
  let duration : Double = note["duration"].cast()
  let voice = if @js.is_nullish(note["voice"]) { "" } else { note["voice"].cast() }
  let family = voice_family(voice)
  let hz = 440.0 *
    g()["Math"]
    ._call("pow", [@js.any(2.0), @js.any((pitch - 69).to_double() / 12.0)])
    .cast()
  let t0 = base + start / bps
  let t1 = t0 + duration / bps
  osc["type"] = @js.any(osc_type(family, lane))
  sub["type"] = @js.any(sub_type(family))
  osc["frequency"]["value"] = @js.any(hz)
  sub["frequency"]["value"] = @js.any(hz / 2.0)
  osc["detune"]["value"] = @js.any(detune_for(family, lane))
  filter["type"] = @js.any(filter_type(family))
  filter["frequency"]["value"] = @js.any(cutoff_for(family) + (pitch - 60).to_double() * 28.0)
  filter["Q"]["value"] = @js.any(q_for(family))
  gain["gain"]._call("setValueAtTime", [@js.any(0.0001), @js.any(t0)]) |> ignore
  gain["gain"]._call("exponentialRampToValueAtTime", [
    @js.any(gain_for(family)),
    @js.any(t0 + attack_for(family)),
  ])
  |> ignore
  gain["gain"]._call("exponentialRampToValueAtTime", [
    @js.any(0.0001),
    @js.any(t1 + release_for(family)),
  ])
  |> ignore
  osc._call("connect", [filter]) |> ignore
  sub._call("connect", [filter]) |> ignore
  filter._call("connect", [gain])._call("connect", [ctx["destination"]]) |> ignore
  osc._call("start", [@js.any(t0)]) |> ignore
  sub._call("start", [@js.any(t0)]) |> ignore
  osc._call("stop", [@js.any(t1 + release_for(family) + 0.03)]) |> ignore
  sub._call("stop", [@js.any(t1 + release_for(family) + 0.03)]) |> ignore
  nodes._call("push", [osc]) |> ignore
  nodes._call("push", [sub]) |> ignore
}

///|
fn voice_family(voice : String) -> Int {
  if voice.contains("Bass") || voice.contains("Acid") || voice.contains("Moog") {
    1
  } else if voice.contains("Pad") || voice.contains("Bloom") ||
            voice.contains("Glass") || voice.contains("Drift") {
    2
  } else if voice.contains("FM") || voice.contains("Bell") ||
            voice.contains("Rhodes") || voice.contains("Kalimba") {
    3
  } else if voice.contains("Wave") {
    4
  } else if voice.contains("Grain") {
    5
  } else if voice.contains("Chip") || voice.contains("NES") ||
            voice.contains("GameBoy") {
    6
  } else if voice.contains("Kick") || voice.contains("Snare") ||
            voice.contains("Hat") {
    7
  } else {
    0
  }
}

///|
fn osc_type(family : Int, lane : Int) -> String {
  match family {
    1 | 2 | 4 => "sawtooth"
    3 => "sine"
    6 | 7 => "square"
    _ => if lane % 2 == 0 { "sawtooth" } else { "triangle" }
  }
}

///|
fn sub_type(family : Int) -> String {
  match family { 2 | 3 | 7 => "triangle"; 4 | 6 => "square"; _ => "sine" }
}

///|
fn filter_type(family : Int) -> String {
  match family { 4 | 5 => "bandpass"; 7 => "highpass"; _ => "lowpass" }
}

///|
fn cutoff_for(family : Int) -> Double {
  match family { 1 => 820.0; 2 => 2400.0; 3 => 9400.0; 4 => 3600.0; 5 => 2100.0; 6 => 7200.0; 7 => 3600.0; _ => 5200.0 }
}

///|
fn q_for(family : Int) -> Double {
  match family { 1 => 11.0; 4 => 8.0; 5 => 10.0; 7 => 7.0; _ => 4.0 }
}

///|
fn gain_for(family : Int) -> Double {
  match family { 1 => 0.18; 2 => 0.105; 3 => 0.13; 5 => 0.12; _ => 0.15 }
}

///|
fn attack_for(family : Int) -> Double {
  match family { 2 => 0.16; 5 => 0.05; 3 => 0.003; 6 | 7 => 0.002; _ => 0.018 }
}

///|
fn release_for(family : Int) -> Double {
  match family { 2 => 0.42; 3 => 0.32; 5 => 0.28; 6 | 7 => 0.04; _ => 0.08 }
}

///|
fn detune_for(family : Int, lane : Int) -> Double {
  match family { 2 | 4 => 7.0; 5 => if lane % 2 == 0 { -11.0 } else { 17.0 }; _ => 0.0 }
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
