# Your First Melody

Let's create a complete melody with rhythm, dynamics, and structure.

## Starting Simple

```rela
scale Major = { R, M2, M3, P4, P5, M6, M7 }

-- Twinkle Twinkle Little Star
let melody = | <1> <1> <5> <5> <6> <6> <5> - <4> <4> <3> <3> <2> <2> <1> - |

melody
```

## Adding Rhythm

Each note in a block has equal duration by default. Let's add variety:

```rela
scale Major = { R, M2, M3, P4, P5, M6, M7 }

let melody = | <1>:1 <1>:1 <5>:1 <5>:1 <6>:1 <6>:1 <5>:2 <4>:1 <4>:1 <3>:1 <3>:1 <2>:1 <2>:1 <1>:2 |

melody
```

The `:n` suffix specifies duration in beats. Now `<5>:2` is held twice as long.

## Adding Rests

Use `-` for rests:

```rela
scale Major = { R, M2, M3, P4, P5, M6, M7 }

let melody = | <1> <1> <5> <5> <6> <6> <5> - <4> <4> <3> <3> <2> <2> <1> - |

melody
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
let combined = theme ++ higher ++ backwards ++ twice

combined
```

## Complete Example

Here's a polished melody:

```rela
scale Major = { R, M2, M3, P4, P5, M6, M7 }

-- First phrase
let phrase1 = | <1>:1 <1>:1 <5>:1 <5>:1 <6>:1 <6>:1 <5>:2 |

-- Second phrase
let phrase2 = | <4>:1 <4>:1 <3>:1 <3>:1 <2>:1 <2>:1 <1>:2 |

-- Combine
let fullMelody = phrase1 ++ phrase2

fullMelody
```

## Exercise

Try creating your own melody:

1. Choose a scale (Major, Minor, Pentatonic)
2. Write a short phrase using scale degrees
3. Add rhythm with duration modifiers
4. Include some rests for breathing room

```rela
-- Your turn!
scale Major = { R, M2, M3, P4, P5, M6, M7 }

let myMelody = | <1> <3> <5> - <5> <3> <1> |

myMelody
```

## Next Steps

Now that you can create melodies, let's learn about [Building Chords](/tutorial/building-chords).
