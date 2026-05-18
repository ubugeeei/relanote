---
layout: home

hero:
  name: relanote
  text: Music as a function.
  tagline: A pure functional, statically-typed language that describes music by what it relates to — not by where it sits on a staff.
  image:
    light: /logo.svg
    dark: /logo-dark.svg
    alt: Relanote
  actions:
    - theme: brand
      text: Read the guide
      link: /guide/introduction
    - theme: alt
      text: Open playground
      link: https://ubugeeei.github.io/relanote/playground/
    - theme: alt
      text: GitHub
      link: https://github.com/ubugeeei/relanote

features:
  - title: Everything is relative
    details: Write <code>&lt;1&gt; &lt;3&gt; &lt;5&gt;</code> and the melody works in any key, any scale, any time. Transpose, modulate and reshape without rewriting a single note.
  - title: Pure, typed, total
    details: Immutable values, first-class functions, Hindley-Milner inference. Music is data; transformations are functions. The type checker catches the rest at compile time.
  - title: Pipes for composition
    details: <code>theme |> transpose P5 |> repeat 2 |> reverb 0.3</code>. Build entire pieces by composing small functions — the same way you build software.
  - title: MIDI out, web in
    details: Render straight to a standard MIDI file, or drive the live playground directly in the browser. No DAW round-trips.
---

## A two-line example

```rela
scale Major = { R, M2, M3, P4, P5, M6, M7 }

let theme = | <1> <3> <5> <3> <1> |
theme |> transpose P5 |> repeat 2
```

The block `| <1> <3> <5> <3> <1> |` reads as five scale-degree references
played in the same time slot. `<1>` is the root, `<3>` is the third
degree of whatever scale is in scope. Change the scale and the same
expression resolves differently — that's *relative*.

## Why "relative"?

Notes on a staff are absolute: middle C is middle C is middle C. Code on
a staff doesn't compose well — to transpose a melody you rewrite every
pitch. relanote describes music the other way around. A line is the
*relationship between its notes*, not the notes themselves. Everything
downstream — chords, sections, layers, parts — is built out of these
relationships.

The shape doesn't change when the key does. That's the point.
