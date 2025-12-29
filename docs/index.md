---
layout: home

hero:
  name: Relanote
  text: Functional Music Notation
  tagline: A pure functional, statically-typed language for describing music through relative intervals
  image:
    src: /logo.svg
    alt: Relanote
  actions:
    - theme: brand
      text: Get Started
      link: /guide/introduction
    - theme: alt
      text: Try Playground
      link: https://relanote.dev/playground
    - theme: alt
      text: GitHub
      link: https://github.com/ubugeeei/relanote

features:
  - icon: 🎵
    title: Relative Intervals
    details: Describe melodies using intervals (M3, P5, m7) instead of absolute pitches. Transpose effortlessly.
  - icon: λ
    title: Pure Functional
    details: Immutable values, first-class functions, and composable operations. Music as data transformations.
  - icon: 🔒
    title: Static Typing
    details: Catch errors at compile time with Hindley-Milner type inference. No runtime surprises.
  - icon: 🎼
    title: Compositional
    details: Build complex pieces from simple building blocks using pipes, layers, and sections.
  - icon: 🎹
    title: MIDI Export
    details: Render your compositions to standard MIDI files for playback in any DAW.
  - icon: 🌐
    title: Web Playground
    details: Try Relanote in your browser with live staff notation and audio preview.
---

<style>
:root {
  --vp-home-hero-name-color: transparent;
  --vp-home-hero-name-background: linear-gradient(135deg, #6366f1 0%, #a855f7 100%);
  --vp-home-hero-image-background-image: linear-gradient(135deg, #6366f1 20%, #a855f7 80%);
  --vp-home-hero-image-filter: blur(44px);
}
</style>

## Quick Example

```rela
// Define a major scale using intervals
let Major = scale [P1, M2, M3, P4, P5, M6, M7]

// Create a melody using scale degrees
let melody = Major |> [<1>, <3>, <5>, <3>, <1>]

// Add rhythm and dynamics
let phrase = melody
  |> withDuration 4bars
  |> withDynamic mf

// Compose a simple song
render
  section "Main"
    part "Piano"
      phrase
```
