# Glossary

A reference of every term the docs throw at you, in roughly the order
you meet them.

[[toc]]

## Pitch

### Interval
The relationship between two pitches. Written `<quality><degree>` —
`P5`, `M3`, `m7`. Independent of which key you're in.

### Scale
A named, ordered set of intervals starting from a root. `scale Major =
{ R, M2, M3, P4, P5, M6, M7 }`. Activates which intervals `<n>`
references resolve to.

### Scale degree
A reference into the active scale. `<1>` is the root, `<3>` is the
third degree, `<8>` is the root one octave up. The expression carries
no pitch information by itself; it resolves through the active scale.

### Chord
A set of intervals played simultaneously. `chord Maj7 = [ R, M3, P5,
M7 ]`. Like a scale, a chord is a *shape* — you root it on a degree
to get a concrete chord.

### Mode
A scale rotated to start on a different degree. Dorian is Major
rotated to start on the second degree; Mixolydian is Major rotated to
the fifth.

### Tuning
A pitch system — how a step in the scale maps to a frequency. The
default is 12-tone equal temperament (12-EDO). Override with `set
tuning = JustIntonation` etc. See [Microtones](./guide/microtones).

### Cents
1/100th of a semitone. Used for microtonal offsets: `M3 -13.7c`,
`<3 +5c>`, `C4 +50c`. Every interval also has a cents value (`M3` =
400 cents in 12-EDO).

### Microtone
Any pitch that doesn't fall on the 12-EDO grid. Reached via cents
offsets or by activating a non-12-EDO tuning.

## Rhythm

### Block
`| slot slot slot |` — a unit of time whose contents share its slot
equally. Default duration is one beat; override with `:n`.

### Slot
One position inside a block. Can be a note, rest, chord, or nested
tuplet.

### Beat
The unit of time the block measures itself in. `set tempo = 120` =
120 beats per minute.

### Tuplet
`{ ... }:n` — squeezes its contents into *n* beats regardless of
how many slots are inside. Triplets, septuplets and so on.

### Groove
A per-slot timing offset applied on top of an otherwise perfectly
equal block. `groove Dilla = offsets { ... }`, then `set groove =
Dilla` or `block |> groove Dilla`.

### Swing
A specific groove that pushes the offbeat eighth note. `groove
Swing67 = offsets { length: 2, steps: [0.0, 0.17] }`.

### Polyrhythm
Two lines playing simultaneously at independent periods.
`| a b c |:3 over | d e f g |:4` — three against four. Realigns
every lcm(3, 4) = 12 slots.

### Polymeter
Two lines with different *bar lengths* (rather than different
subdivisions of the same time). Same `over` operator — relanote
doesn't draw the syntactic distinction.

## Composition

### Pipe `|>`
"Then" — pass the value on the left into the function on the right:
`melody |> transpose P5 |> repeat 2`.

### Compose `>>`
Build a function out of other functions without applying it:
`let style = transpose P5 >> reverse`. Apply later with `|>`.

### Concat `++`
Glue two blocks into one, in sequence. Each side keeps its own
relative-rhythm density.

### Layer
Run multiple lines concurrently inside one expression: `layer [
melody, harmony ]`.

### Part
A named voice — `part "Lead" { ... } |> voice X`. The mixer addresses
tracks by part name.

### Section
A named group of concurrent parts that share a context (key, scale,
tempo, groove). The unit of "structural change" — switch scale on a
section boundary, not mid-section.

## Synthesis

### Synth
A record describing how a note becomes sound: oscillator, envelope,
filter, optional modulation, optional inline effects. Applied with
`block |> voice <SynthName>`.

### Oscillator
The sound source. Built-ins: `Sine`, `Square`, `Saw`, `Triangle`,
`Noise`, plus three richer forms: `FM(...)`, `Wavetable(...)`,
`Granular(...)`.

### FM
Frequency modulation — one oscillator (the modulator) modulates the
other (the carrier). `op2_ratio` and `op2_level` are the dials that
shape the result.

### Wavetable
A sequence of single-cycle waves the oscillator scans through.
`wave_pos` is the static position; modulate it to get movement.

### Granular
Chops a source sample into 5–100 ms grains and rearranges them.
Controls: `grain_size`, `density`, `spray`, `pitch_jitter`.

### Envelope
A four-stage shape (Attack / Decay / Sustain / Release) governing how
loudness — or any modulated parameter — evolves over a note's life.

### Filter
A frequency-selective gain. `LowPass(cutoff, q)`, `HighPass`,
`BandPass`.

### Modulation matrix
A list of source → destination routings inside a synth. Sources are
LFOs, envelopes, keytrack, velocity. Destinations are any
modulatable parameter (`filter.cutoff`, `pitch`, `wave_pos`, `amp`,
…).

## Mixing

### Track
A named part viewed from the mix block. `track "lead"`. Effects, sends
and sidechain links target tracks by name.

### Bus
A named, shared effect chain. `bus Verb = effect PlateLarge`. Tracks
route signal into a bus via `send`.

### Send
Route a fraction of a track's signal into a bus. `track "lead" |>
send Verb 0.35`.

### Sidechain
One track's amplitude envelope ducks another track's level.
`sidechain track "kick" -> track "bass" 0.6`.

### Master
The final effect chain applied to the summed mix. `master = effect
MasterChain`.

### Compressor / Saturator / Limiter
Standard mix processors. The stdlib ships presets (`BusGlue`,
`DrumBus`, `MasterChain`, `Drive`, …) in
[`effects_mix.rela`](https://github.com/ubugeeei/relanote/blob/main/moonbit/relanote_stdlib/prelude/effects_mix.rela).

## Language

### Pure function
A function whose output depends only on its inputs — no hidden state,
no surprise side effects. relanote's standard library is entirely
pure.

### Immutable
Values don't change after they're constructed. Transformations
return new values; the originals are untouched.

### Hindley-Milner
The type inference algorithm relanote's checker uses. Catches type
mismatches at compile time without requiring you to annotate every
binding.

### Let-in
`let x = e1 in e2` — a local binding scoped to one expression. As
opposed to a top-level `let x = e1` which exports the name.

### Lambda
An anonymous function — `\x -> body`. First-class value; you can pass
it around like any other expression.

### Pattern matching
`match expr { pattern => body  pattern => body }` — destructure a
value by shape. Cleaner than nested `if`s when there's more than two
cases.

### Annotation
An explicit type at a binding site, e.g. `let x : Interval = P5`.
Usually optional thanks to inference; useful for documenting intent
or pinning ambiguous types.
