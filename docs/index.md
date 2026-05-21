---
layout: home

hero:
  name: relanote
  text: Everything is relative.
  tagline: A pure functional, statically-typed language for music. Pitch is relative. Rhythm is relative. The shape doesn't change when the key does.
  image:
    light: /logo.svg
    dark: /logo-dark.svg
    alt: Relanote
  actions:
    - theme: brand
      text: Read the guide
      link: /guide/introduction
    - theme: alt
      text: Hear showcase
      link: /showcase
    - theme: alt
      text: GitHub
      link: https://github.com/ubugeeei/relanote

features:
  - title: Pitch is relative
    details: Write <code>&lt;1&gt; &lt;3&gt; &lt;5&gt;</code> once and the line works in every key, every mode, every scale. Transpose, modulate or reshape without rewriting a single note.
  - title: Rhythm is relative
    details: A block <code>| a b c d |</code> shares its slot equally among four notes; <code>| a b |</code> gives two notes the same slot at half the density. Tempo and meter don't change the shape.
  - title: Pure, typed, total
    details: Immutable values, first-class functions, Hindley-Milner inference. Music is data; transformations are functions. The type checker catches the rest at compile time.
  - title: Pipes for composition
    details: <code>theme |> transpose P5 |> repeat 2 |> reverb 0.3</code>. Build entire pieces by composing small functions — the same way you build software.
---

## Two lines that wouldn't fit on a staff

```rela
scale Major = { R, M2, M3, P4, P5, M6, M7 }

let theme = | <1> <3> <5> <3> <1> |
theme |> transpose P5 |> repeat 2
```

`| <1> <3> <5> <3> <1> |` is five **scale-degree references** sharing one
slot. `<1>` is whatever the current scale calls its root, `<3>` is its
third, `<5>` is its fifth. Swap the scale and the same five symbols play
a different melody. Change the tempo and the line stretches or shrinks
without a single edit.

That's the whole idea: a line is the **relationship between its notes**,
not the notes themselves.

## Relative all the way down

Chords are intervals over a root. Sections are blocks over a pulse.
Parts are sections over an instrument. Layers are parts over time.
Everything in the language is described by what it relates to — never by
where it absolutely sits.

The shape doesn't change when the key does. That's the point.
