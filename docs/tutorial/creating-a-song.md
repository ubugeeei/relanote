# Creating a song

A relanote piece is just a graph of relative things played together. A
song is the same primitives — blocks, chords, transformations — at a
larger scale. There's no new syntax. You just keep composing.

## Material first, structure second

Write the smallest reusable phrases first. Don't think about the song
shape yet:

```rela
scale Major = { R, M2, M3, P4, P5, M6, M7 }

let melody = | <5> <6> <7> <8> <8> <7> <6> <5>  <5> <6> <7> <8> <8>:2 - - |
let bass   = | <1>:2 <5>:2 <4>:2 <1>:2  <1>:2 <5>:2 <1>:4 |
```

Each of those is a single value. They can be transposed, repeated,
reversed, concatenated, layered — anything you'd do with any other
relanote expression.

## Develop a theme by transforming it

A song that goes somewhere usually does so by transforming the same
seed:

```rela
scale Major = { R, M2, M3, P4, P5, M6, M7 }

let theme = | <1> <3> <5> <3> |

let answer    = theme |> transpose P5         ; harmonic answer up a fifth
let inversion = theme |> reverse              ; play the contour backwards
let echo      = theme |> repeat 2             ; double it

let development = theme ++ answer ++ inversion ++ echo
```

Reading the code is reading the structure: you can see at a glance that
the second half answers the first, then inverts, then echoes.

## Build the arrangement bottom-up

Once you have phrases, the song is the concatenation of the sections
that use them:

```rela
scale Major = { R, M2, M3, P4, P5, M6, M7 }

let main      = | <1> <2> <3> <4>  <5> <5> <4> <3>  <2> <1> <1>:2 |
let answer    = main |> transpose P5
let recap     = main

let song      = main ++ answer ++ recap

song
```

Stack the song with a `bass` line as a layer (covered in the
[Layers guide](/guide/layers)), or set up a `synth` so each part lands
on the right instrument.

## Render to MIDI

When you're ready:

```bash
relanote render song.rela -o song.mid
```

Drop the MIDI into any DAW for instrument choice, mix and master. The
relanote source is the durable copy — the MIDI is one render of it.

## A short checklist

- **Reuse before you write more.** A small theme transformed four ways
  is denser than four unrelated lines.
- **Move by intervals, not by pitches.** Transpose, don't rewrite.
- **Let density change the feel.** Switching from `| a b |` to
  `| a b c d |` doubles density without touching timing config.
- **Concat for structure, layer for texture.** `++` builds form across
  time; layers build form across instruments.

Continue with [Adding synth sounds](/tutorial/synth-sounds) when you want
something other than the default tone.
