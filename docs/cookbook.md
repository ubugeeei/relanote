# Cookbook

Short recipes for things that come up a lot. Each one is a single
copy-pasteable block of relanote source.

[[toc]]

## Pitch and harmony

### Transpose a melody to any key

```rela
let theme    = | <1> <3> <5> <3> |
let in_g     = theme |> transpose P5         ; up a fifth
let in_d_min = theme |> transpose M2 |> in_scale Minor
```

### Borrow a chord from the parallel minor

```rela
scale Major = { R, M2, M3, P4, P5, M6, M7 }
scale Minor = { R, M2, m3, P4, P5, m6, m7 }

; I → vi (borrowed) → IV → V → I
let progression = | <1>
                    <6> |> in_scale Minor
                    <4>
                    <5>
                    <1> |
```

### Quote a melody at a different pitch

```rela
let quote_at_fifth = \m -> m |> transpose P5

let theme  = | <1> <3> <5> <3> |
theme ++ quote_at_fifth theme
```

### Build a turnaround (ii-V-I)

```rela
scale Major = { R, M2, M3, P4, P5, M6, M7 }
chord Min7  = [ R, m3, P5, m7 ]
chord Dom7  = [ R, M3, P5, m7 ]
chord Maj7  = [ R, M3, P5, M7 ]

let turnaround = | Min7 on <2>  Dom7 on <5>  Maj7 on <1> |:4
```

### Modal interchange — same shape, different mood

```rela
let shape = | <1> <3> <5> <3> |

shape                            ; in scope: whatever scale you set
shape |> in_scale Minor          ; same shape, parallel minor
shape |> in_scale Dorian         ; same shape, dorian colour
shape |> in_scale Lydian         ; same shape, lydian colour
```

## Rhythm

### Apply swing or a groove

```rela
melody |> swing                  ; quick 8th-note swing
melody |> groove Swing67         ; named groove preset
melody |> groove Dilla           ; J Dilla feel
set groove = Shuffle             ; for the whole program from here
```

### Polyrhythm — 3 against 2

```rela
let three = | <1> <3> <5> |:3
let two   = | <1> <5> |:2

three over two
```

### Polyrhythm — 3 against 4 against 5

```rela
let three = | <1> <3> <5> |:3
let four  = | <1> <2> <3> <4> |:4
let five  = | <1> <3> <5> <8> <5> |:5

three over four over five    ; realigns every lcm(3,4,5) = 60 slots
```

### Hemiola inside a 4-bar phrase

```rela
| <1> <2> <3> |:2 |> repeat 4
```

Six triplets share eight beats — the classic 3-against-2 feel.

### Call and response

```rela
let call     = | <1> <3> <5> <3> - - - - |
let response = | - - - - <5> <4> <3> <2> |
layer [ call, response ]
```

## Microtones

### Just-intonation tour

```rela
set tuning = JustIntonation
scale Major = { R, M2, M3, P4, P5, M6, M7 }

| <1> <3> <5> |   ; M3 here is 13.7 cents flatter than 12-EDO
```

### Per-note cents bend

```rela
| <1> M3 -13.7c <5> P5 +1.96c <8> |     ; M3 just-tuned, P5 well-tuned
| <3 +5c> <5 -7c> |                      ; scale-degree refs with cents
| C4 +50c |                              ; quarter-tone shy of C#
```

### Bohlen-Pierce in one line

```rela
set tuning = BohlenPierce

| <1> <2> <3> <4> <5> <6> <7> <8> <9> <10> <11> <12> <13> |
```

### Microtonal blues thirds and sevenths

```rela
scale Blues = { R, m3, P4, A4, P5, m7 }

let bent = | <1> m3 +30c <4> P4+ <5> m7 -10c |
```

## Synthesis

### A subtractive lead in three lines

```rela
synth MyLead = {
  osc: Saw(voices: 3),
  detune: 14,
  env: { A: 0.01, D: 0.2, S: 0.7, R: 0.3 },
  filter: LowPass(2500, 0.4)
}

melody |> voice MyLead
```

### FM electric piano

```rela
synth FMEPiano = {
  osc: FM(op1: Sine, op2: Sine, op2_ratio: 1.0, op2_level: 0.45, feedback: 0.12),
  env: { A: 0.005, D: 0.8, S: 0.3, R: 0.7 },
  filter: LowPass(5500, 0.15),
  tremolo: { rate: 5.5, depth: 0.2 }
}
```

### Wavetable pad that breathes

```rela
synth Breath = {
  osc: Wavetable(table: "drift", voices: 5),
  wave_pos: 0.5,
  detune: 16,
  env: { A: 2.0, D: 1.0, S: 1.0, R: 4.0 },
  filter: LowPass(4500, 0.25),
  mod: [
    lfo(target: wave_pos,      rate: 0.10, depth: 0.5, shape: Sine),
    lfo(target: filter.cutoff, rate: 0.08, depth: 1500, shape: Sine)
  ]
}
```

### Granular vocal cloud

```rela
synth VocalCloud = {
  osc: Granular(source: "vocal", grain_size: 0.04, density: 50, spray: 0.6, pitch_jitter: 40),
  env: { A: 0.3, D: 0.7, S: 0.8, R: 1.5 },
  filter: BandPass(1500, 0.5)
}
```

### Drum hit with pitch envelope

```rela
synth Kick = {
  osc: Sine + Triangle(level: 0.35),
  pitch_env: { from: 220, to: 55, time: 0.06 },
  env: { A: 0.001, D: 0.18, S: 0.0, R: 0.18 },
  filter: LowPass(2200, 0.2)
}
```

## Mixing

### Sidechain bass under the kick

```rela
mix {
  sidechain track "kick" -> track "bass" 0.65
}
```

### Shared reverb across multiple tracks

```rela
mix {
  bus Verb = effect PlateLarge
  track "lead"  |> send Verb 0.35
  track "keys"  |> send Verb 0.45
  track "snare" |> send Verb 0.25
}
```

### Parallel "New York" drum compression

```rela
mix {
  bus Smash = effect ParallelSmash
  track "snare" |> send Smash 0.50
  track "kick"  |> send Smash 0.40
}
```

### Dub-style send-heavy mix

```rela
mix {
  bus Verb = effect PlateLarge
  bus Echo = effect TapeEcho

  ; The stab is mostly sends — almost no dry signal.
  track "stab" |> send Verb 0.85 |> send Echo 0.60 |> volume 0.25
}
```

### Master glue + light limiting

```rela
mix {
  master = effect MasterChain      ; ships glue compressor + EQ + limiter
}
```

## Structure

### Verse / chorus / bridge

```rela
let verse  = section "Verse"  { part "Lead" { ... } |> voice MyLead
                                 part "Bass" { ... } |> voice BassMoog }
let chorus = section "Chorus" { part "Lead" { ... } |> voice MyLead |> volume 0.9
                                 part "Bass" { ... } |> voice BassMoog
                                 part "Pad"  { ... } |> voice FloatingBloom |> volume 0.5 }
let bridge = section "Bridge" with key: G, scale: Dorian, groove: Swing67 {
  part "Lead" { ... } |> voice Rhodes
}

verse |> repeat 2 ++ chorus ++ verse ++ chorus ++ bridge ++ chorus
```

### Variations on a theme by transformation

```rela
let theme = | <1> <3> <5> <3> <1>~ - - - |

theme
  ++ theme |> reverse
  ++ theme |> transpose P5
  ++ theme |> double_time |> repeat 2
```

### Layered harmony from one melody

```rela
let melody = | <1> <2> <3> <4> |

layer [
  melody,
  melody |> transpose M3 |> volume 0.7,
  melody |> transpose P5 |> volume 0.6,
  melody |> transpose P8 |> volume 0.5
]
```
