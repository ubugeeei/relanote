# Your First Melody

Let's create a complete melody with rhythm, dynamics, and structure.

## Starting Simple

```rela
scale Major = { R, M2, M3, P4, P5, M6, M7 }

-- Twinkle Twinkle Little Star
let melody = | <1> <1> <5> <5> <6> <6> <5> - <4> <4> <3> <3> <2> <2> <1> - |

melody
```

Each slot in the block has equal duration. With 16 slots in a default 1-beat block, each note is 1/16 of a beat.

## Understanding Relative Rhythm

In Relanote, rhythm is determined by **how many slots** are in a block, not by explicit duration values:

```rela
scale Major = { R, M2, M3, P4, P5, M6, M7 }

-- 4 slots = each note is 1/4 of the block duration
let fast = | <1> <2> <3> <4> |

-- 2 slots = each note is 1/2 of the block duration
let slower = | <1> <5> |

-- 1 slot = the note fills the whole block
let whole = | <1> |
```

## Controlling Block Duration

Use `:n` after a block to set its total duration in beats:

```rela
scale Major = { R, M2, M3, P4, P5, M6, M7 }

-- 4 notes spread over 4 beats = quarter notes
let quarters = | <1> <2> <3> <4> |:4

-- 4 notes in 2 beats = eighth notes
let eighths = | <1> <2> <3> <4> |:2

-- 4 notes in 1 beat = sixteenth notes (default)
let sixteenths = | <1> <2> <3> <4> |

quarters
```

## Rests Create Rhythm

Use `-` for rests to add space:

```rela
scale Major = { R, M2, M3, P4, P5, M6, M7 }

-- Notes with rests
let with_rests = | <1> - <3> - <5> - - - |

with_rests
```

## Combining Different Rhythms

Concatenate blocks with `++` to create varied rhythms:

```rela
scale Major = { R, M2, M3, P4, P5, M6, M7 }

-- Fast passage
let fast = | <1> <2> <3> <4> <5> <4> <3> <2> |

-- Slow resolution
let slow = | <1> <5> |

-- Held final note (2 beats)
let ending = | <1> |:2

-- Each block keeps its own rhythm!
let phrase = fast ++ slow ++ ending

phrase
```

## Transformations

Make variations using transformations:

```rela
scale Major = { R, M2, M3, P4, P5, M6, M7 }

let theme = | <1> <3> <5> <3> |

-- Variations
let higher = theme |> transpose(P8)      -- One octave up
let backwards = theme |> reverse          -- Play in reverse
let twice = theme |> repeat(2)            -- Play twice

-- Combine variations
let combined = theme ++ higher ++ backwards

combined
```

## Complete Example: Twinkle Twinkle

Here's the full melody with proper phrasing:

```rela
scale Major = { R, M2, M3, P4, P5, M6, M7 }

-- First phrase: "Twinkle twinkle little star"
let phrase1 = | <1> <1> <5> <5> <6> <6> <5> - |

-- Second phrase: "How I wonder what you are"
let phrase2 = | <4> <4> <3> <3> <2> <2> <1> - |

-- Combine into full melody
let twinkle = phrase1 ++ phrase2

twinkle
```

## Adding Expression

Use articulations to add character:

```rela
scale Major = { R, M2, M3, P4, P5, M6, M7 }

-- With accents and staccato
let expressive = | <1>^ <1> <5>^ <5> <6>^ <6> <5>~ - |

expressive
```

## Exercise

Try creating your own melody:

1. Choose a scale (Major, Minor, Pentatonic)
2. Write a short phrase using scale degrees
3. Experiment with the number of slots for different rhythms
4. Add rests for breathing room
5. Use articulations for expression

```rela
scale Major = { R, M2, M3, P4, P5, M6, M7 }

-- Your turn! Create a melody
let myMelody = | <1> <3> <5> - <5> <3> <1> - |

myMelody
```

## Next Steps

Now that you can create melodies, let's learn about [Building Chords](/tutorial/building-chords).
