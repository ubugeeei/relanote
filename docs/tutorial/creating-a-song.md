# Creating a Song

Put everything together to create a complete multi-part composition.

## Song Structure

A Relanote song consists of:
- **Sections** - Named parts of the song (Intro, Verse, Chorus)
- **Parts** - Instrument tracks within a section
- **Blocks** - Musical content for each part

## A Simple Song

Let's create a complete piece:

```rela
scale Major = { R, M2, M3, P4, P5, M6, M7 }

-- Define our musical material
let melody = | <5> <6> <7> <8> <8> <7> <6> <5> <5> <6> <7> <8> <8>:2 - - |

let bass = | <1>:2 <5>:2 <4>:2 <1>:2 <1>:2 <5>:2 <1>:4 |

melody
```

## Repetition and Variation

Use transformations for development:

```rela
scale Major = { R, M2, M3, P4, P5, M6, M7 }

let theme = | <1> <3> <5> <3> |

-- Variations
let theme_high = theme |> transpose(P8)
let theme_reverse = theme |> reverse
let theme_twice = theme |> repeat(2)

-- Combine all variations
let full = theme ++ theme_high ++ theme_reverse ++ theme_twice

full
```

## Complete Example: Simple Melody

```rela
scale Major = { R, M2, M3, P4, P5, M6, M7 }

-- Main theme
let theme = | <1> <2> <3> <4> <5> <5> <4> <3> <2> <1> <1>:2 |

-- Variation - transposed up
let variation = theme |> transpose(P5)

-- Combine
let fullSong = theme ++ variation ++ theme

fullSong
```

## Tips for Song Writing

1. **Start simple** - Begin with a melody, then add accompaniment
2. **Use repetition** - Repeat themes with variations for coherence
3. **Create contrast** - Vary dynamics, register, and texture between sections
4. **Layer gradually** - Build from sparse to full arrangement
5. **End strong** - Bring back main themes in the final section

## Exercise

Create your own song with:
- At least 2 phrases
- Some variation (transpose, reverse, repeat)
- Rests for breathing room

```rela
scale Major = { R, M2, M3, P4, P5, M6, M7 }

-- Your song here!
let myTheme = | <1> <3> <5> <3> |

let myVariation = myTheme |> transpose(P4)

let mySong = myTheme ++ myVariation ++ myTheme

mySong
```

## Rendering

When you're happy with your song, render it to MIDI:

```bash
relanote render mysong.rela -o mysong.mid
```

Open the MIDI file in your favorite DAW to:
- Add better instrument sounds
- Fine-tune timing and dynamics
- Mix and master your composition

Congratulations! You've learned the basics of Relanote. Continue exploring the [Reference](/reference/syntax) for more advanced features.
