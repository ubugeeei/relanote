# Parts & Sections

Relanote provides **parts** and **sections** to organize multi-voice compositions. Parts represent individual instruments or voices, while sections group musical phrases with shared context like key and tempo.

## Parts

A **part** wraps musical content with an instrument designation:

```rela
scale Major = { R, M2, M3, P4, P5, M6, M7 }

let melody = | <1> <3> <5> <3> <1> |

part "Piano" melody
```

### Built-in Instrument Names

Parts can use any string as an instrument name. Common examples:

- `"Piano"`, `"Guitar"`, `"Bass"`
- `"Violin"`, `"Cello"`, `"Viola"`
- `"Trumpet"`, `"Saxophone"`, `"Flute"`
- `"Drums"`, `"Percussion"`
- `"Synth"`, `"Lead"`, `"Pad"`

### Part with Effects

Parts can be chained with effects using pipes:

```rela
scale Major = { R, M2, M3, P4, P5, M6, M7 }

let melody = | <1> <3> <5> <8> |

; Add reverb and set volume
melody |> room_reverb |> volume 0.8
```

## Sections

A **section** groups content with a name and optional context:

```rela
scale Major = { R, M2, M3, P4, P5, M6, M7 }

let verse = | <1> <2> <3> <4> |
let chorus = | <5> <6> <7> <8> |

section "Verse" verse
section "Chorus" chorus
```

### Section Context

Sections can include context for key, scale, and tempo:

```rela
scale Major = { R, M2, M3, P4, P5, M6, M7 }
scale Dorian = { R, M2, m3, P4, P5, M6, m7 }

let melody = | <1> <3> <5> <3> |

; Section with context (planned feature)
; section "Bridge" with key:G, scale:Dorian {
;   melody
; }
```

## Combining Parts in Sections

Create multi-voice arrangements by combining parts:

```rela
scale Major = { R, M2, M3, P4, P5, M6, M7 }

; Define parts
let right_hand = | <1> <3> <5> <8> |
let left_hand = | R - P5 - |

; Combine using concatenation
let piano_part = right_hand ++ left_hand

section "Intro" piano_part
```

## Practical Example: Song Structure

```rela
scale Major = { R, M2, M3, P4, P5, M6, M7 }

; Verse melody
let verse_melody = |
  <1> <2> <3> <2>
  <1> <3> <5> <3>
|

; Chorus melody (higher energy)
let chorus_melody = |
  <5>^ <6>^ <7>^ <8>^
  <8> <7> <6> <5>
|

; Bridge (different character)
let bridge_melody = |
  <4>~ <5> <6>~ <5>
  <3>~ <4> <5>~ -
|

; Bass line
let bass = | R - P5 - R - P4 - |

; Build the song
let verse = verse_melody ++ bass
let chorus = chorus_melody ++ (bass |> transpose P5)
let bridge = bridge_melody

; Full arrangement
verse |> repeat 2 ++ chorus ++ verse ++ chorus ++ bridge ++ chorus
```

## Best Practices

1. **Name sections descriptively**: Use names like "Intro", "Verse", "Chorus", "Bridge", "Outro"
2. **Keep parts focused**: Each part should represent a single voice or instrument
3. **Use variables**: Define melodic fragments as variables, then combine them
4. **Layer for richness**: Use `layer` (see [Layers](./layers)) to play parts simultaneously
