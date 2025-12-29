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
      link: https://ubugeeei.github.io/relanote/playground/
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
  --vp-home-hero-name-color: #292524;
  --vp-home-hero-image-background-image: linear-gradient(135deg, rgba(180, 83, 9, 0.15) 20%, rgba(217, 119, 6, 0.15) 80%);
  --vp-home-hero-image-filter: blur(44px);
}

.dark {
  --vp-home-hero-name-color: #faf6f1;
  --vp-home-hero-image-background-image: linear-gradient(135deg, rgba(180, 83, 9, 0.25) 20%, rgba(217, 119, 6, 0.25) 80%);
}
</style>

## Quick Example

```rela
; Define a major scale using relative intervals
scale Major = { R, M2, M3, P4, P5, M6, M7 }

; Rhythm is relative: 4 notes = quarter notes
let fast = | <1> <3> <5> <3> |

; 2 notes in same duration = half notes
let slow = | <1> <5> |

; Compose and transform
let melody = fast ++ slow
melody |> transpose(P5) |> repeat(2)
```
