///|
fn install_prelude(ctx : TypeContext) -> Unit {
  // reverse : Block -> Block
  ctx.bind_mono("reverse", Type::function(Block, Block))

  // transpose : Interval -> Block -> Block
  ctx.bind_mono("transpose", Type::function_n([Interval, Block], Block))

  // repeat : Int -> Block -> Block
  ctx.bind_mono("repeat", Type::function_n([IntTy, Block], Block))

  // metronome : Int -> Int -> Block
  ctx.bind_mono("metronome", Type::function_n([IntTy, IntTy], Block))

  // swing : Block -> Block
  ctx.bind_mono("swing", Type::function(Block, Block))

  // double_time : Block -> Block
  ctx.bind_mono("double_time", Type::function(Block, Block))

  // reverb : Float -> Block -> Part
  ctx.bind_mono("reverb", Type::function_n([FloatTy, Block], Part))

  // hall_reverb / room_reverb / plate_reverb : Block -> Part
  ctx.bind_mono("hall_reverb", Type::function(Block, Part))
  ctx.bind_mono("room_reverb", Type::function(Block, Part))
  ctx.bind_mono("plate_reverb", Type::function(Block, Part))

  // dry : Block -> Part
  ctx.bind_mono("dry", Type::function(Block, Part))

  // volume : Float -> Block -> Part
  ctx.bind_mono("volume", Type::function_n([FloatTy, Block], Part))

  // delay : Float -> Float -> Float -> Part -> Part
  ctx.bind_mono(
    "delay",
    Type::function_n([FloatTy, FloatTy, FloatTy, Part], Part),
  )

  // phaser : Float -> Float -> Float -> Part -> Part
  ctx.bind_mono(
    "phaser",
    Type::function_n([FloatTy, FloatTy, FloatTy, Part], Part),
  )

  // distortion : Float -> DistortionType -> Float -> Part -> Part
  ctx.bind_mono(
    "distortion",
    Type::function_n([FloatTy, DistortionType, FloatTy, Part], Part),
  )

  // Distortion type constructors : DistortionType
  for name in ["SoftClip", "HardClip", "Fuzz", "BitCrush"] {
    ctx.bind_mono(name, DistortionType)
  }

  // Delay presets : Part -> Part
  for
    name in [
      "slapback", "short_delay", "stereo_delay", "dotted_eighth_delay", "quarter_delay",
      "pingpong_delay", "tape_delay", "ambient_delay", "dub_delay", "shimmer_delay",
    ] {
    ctx.bind_mono(name, Type::function(Part, Part))
  }

  // Phaser presets : Part -> Part
  for
    name in [
      "subtle_phaser", "slow_phaser", "classic_phaser", "fast_phaser", "deep_phaser",
      "jet_phaser", "funk_phaser", "space_phaser", "wobble_phaser", "liquid_phaser",
    ] {
    ctx.bind_mono(name, Type::function(Part, Part))
  }

  // Distortion presets : Part -> Part
  for
    name in [
      "saturation", "light_overdrive", "warm_overdrive", "crunch", "classic_dist",
      "heavy_dist", "light_fuzz", "heavy_fuzz", "classic_fuzz", "lofi_crush", "bit8_crush",
      "extreme_crush",
    ] {
    ctx.bind_mono(name, Type::function(Part, Part))
  }

  // Additional reverb presets : Part -> Part
  for
    name in [
      "studio_reverb", "spring_reverb", "chamber_reverb", "ambient_reverb", "cathedral_reverb",
      "infinite_reverb",
    ] {
    ctx.bind_mono(name, Type::function(Part, Part))
  }

  // Synth functions
  // voice : Synth -> Block -> Part
  ctx.bind_mono("voice", Type::function_n([Synth, Block], Part))

  // cutoff : Float -> Part -> Part
  ctx.bind_mono("cutoff", Type::function_n([FloatTy, Part], Part))

  // resonance : Float -> Part -> Part
  ctx.bind_mono("resonance", Type::function_n([FloatTy, Part], Part))

  // detune : Float -> Part -> Part
  ctx.bind_mono("detune", Type::function_n([FloatTy, Part], Part))

  // adsr : Float -> Float -> Float -> Float -> Part -> Part
  ctx.bind_mono(
    "adsr",
    Type::function_n([FloatTy, FloatTy, FloatTy, FloatTy, Part], Part),
  )

  // Synth presets : Synth
  for
    name in [
      // 8-bit
      "Chiptune", "Chip8bit", "NES", "GameBoy",
      // classic
       "FatBass", "SoftPad", "Lead", "Pluck", "Strings", "Organ",
      // drums
       "Kick", "Snare", "HiHat", "OpenHat", "Tom", "Clap",
      // clap variants
       "HandClap", "TightClap", "RoomClap", "Clap808", "Clap909", "VintageClap",
      "SharpClap", "SoftClap", "StadiumClap", "FingerSnap",
      // additional
       "Piano", "EPiano", "WarmPad", "AcidBass",
    ] {
    ctx.bind_mono(name, Synth)
  }

  // map : (a -> b) -> [a] -> [b]
  let a = ctx.fresh_var()
  let b = ctx.fresh_var()
  let map_quantifiers : Array[TyVar] = []
  match a {
    Var(av) => map_quantifiers.push(av)
    _ => ()
  }
  match b {
    Var(bv) => map_quantifiers.push(bv)
    _ => ()
  }
  ctx.bind(
    "map",
    TypeScheme::poly(
      map_quantifiers,
      Type::function_n([Type::function(a, b), Type::array(a)], Type::array(b)),
    ),
  )

  // compose : [Section] -> Song
  ctx.bind_mono("compose", Type::function(Type::array(Section), Song))

  // play : Block -> Part -> Part
  ctx.bind_mono("play", Type::function_n([Block, Part], Part))

  // apply_env : Envelope -> Part -> Part
  ctx.bind_mono("apply_env", Type::function_n([Envelope, Part], Part))

  // render : Song -> () -> ()
  ctx.bind_mono("render", Type::function_n([Song, Unit], Unit))
}
