# Parts and sections

A **part** binds a block to an instrument. A **section** groups parts
that share the same musical context — key, scale, tempo, groove. The
two together are the structural backbone of any relanote piece
beyond a single melody.

## Parts

`part "Name" { body }` ties the body block to a named voice. Apply a
synth with `|> voice`:

```rela
scale Major = { R, M2, M3, P4, P5, M6, M7 }

part "Lead" {
  | <1> <3> <5> <3> <1> |
} |> voice ModularLead
```

Any instrument name is allowed — `"Piano"`, `"Trumpet"`, `"Guitar"`,
`"Drums"`. The name is a label the mixer uses to route, key
sidechains and apply effects:

```rela
mix {
  track "Lead" |> compress -10 4 |> send Verb 0.3
}
```

Parts compose with the same pipe machinery as everything else:

```rela
part "Lead" { | <1> <3> <5> <8> | }
  |> voice Lead
  |> volume 0.8
  |> reverb 0.3
```

## Sections

`section "Name" { ... }` groups parts that play together and share a
context block. Use it to mark up the form of a piece — Intro,
Verse, Chorus, Bridge — and to switch tonal centre or feel between
sections:

```rela
scale Major = { R, M2, M3, P4, P5, M6, M7 }
scale Minor = { R, M2, m3, P4, P5, m6, m7 }

let verse = section "Verse" {
  part "Lead" { | <1> <2> <3> <4> | } |> voice Lead
  part "Bass" { | <1> - <5> - |     } |> voice BassRound
} |> in_scale Major

let chorus = section "Chorus" {
  part "Lead" { | <5> <6> <7> <8> | } |> voice Lead
  part "Bass" { | <1> - <5> - |     } |> voice BassRound
} |> in_scale Minor

verse ++ chorus
```

## Context blocks

A section can override the active scale, key, tempo or groove for the
duration of its body:

```rela
section "Bridge" with key: G, scale: Dorian, tempo: 92, groove: Swing67 {
  part "Lead"  { | <1> <3> <5> <3> | } |> voice Rhodes
  part "Keys"  { | [<1> m3 P5]:2 |   } |> voice Wurly
}
```

Anything not overridden inherits from the surrounding scope.

## Combining parts and sections

Parts inside a section play *together*; sections concatenated with
`++` play *in sequence*:

```rela
let intro   = section "Intro"   { part "Lead" { ... } |> voice ... }
let verse   = section "Verse"   { part "Lead" { ... } |> voice ... }
let chorus  = section "Chorus"  { part "Lead" { ... }
                                  part "Bass" { ... } }
let outro   = section "Outro"   { part "Lead" { ... } }

intro ++ verse ++ chorus ++ verse ++ chorus ++ outro
```

For two parts to play **at the same time** within a section, just
declare them both — the parts inside a `section { ... }` are
implicitly concurrent. For more complex parallelism see
[Layers](./layers).

## A full song shape

```rela
scale Major = { R, M2, M3, P4, P5, M6, M7 }

let theme = | <1> <2> <3> <2> <1> <3> <5> <3> |

let intro = section "Intro" {
  part "Pad" { theme |> map (\n -> n + P8) } |> voice FloatingBloom |> volume 0.4
}

let verse = section "Verse" {
  part "Lead" { theme }                       |> voice ModularLead
  part "Bass" { | <1> - <5> - |:8 |> repeat 4 } |> voice BassMoog
}

let chorus = section "Chorus" {
  part "Lead" { theme |> transpose P5 }       |> voice ModularLead |> volume 0.85
  part "Bass" { | <1> <4> <5> <1> |:8 |> repeat 4 } |> voice BassMoog
  part "Pad"  { theme |> transpose P5 }       |> voice FloatingChoir |> volume 0.45
}

intro ++ verse ++ chorus ++ verse ++ chorus
```

## Rules of thumb

- **Name a part after the role, not the instrument.** `"Lead"`,
  `"Bass"`, `"Pad"` survive instrument changes; `"Trumpet"` doesn't.
- **Sections are the unit of structural change.** Switch scale or
  groove on a section boundary; avoid mid-section toggles.
- **Reach for the [mix](./mixing) block when routing gets hairy.**
  Per-part effects pipes are fine for single concerns; the
  `mix { ... }` block is where buses and sidechains live.

## Listen-through example

This reduces a section arrangement to audible blocks: intro, lead role,
bass role and chorus cadence in sequence.

```rela
scale Major = { R, M2, M3, P4, P5, M6, M7 }

let intro = | [R, M3, P5] - [P4, M6, R] - |:4
let lead  = | <1> <2> <3> <5> <6> <5> <3> <2> |:4
let bass  = | <1> - <5> <1> |:4
let hook  = | <5> <6> <7> <6> <5> <3> <1> <1> |:4

intro ++ lead ++ bass ++ hook
```
