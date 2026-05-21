# Control flow

relanote has the conventional pure-functional toolbox: `if-then-else`,
pattern matching, comparison and boolean operators, destructuring.
Use them sparingly — most "control flow" in a piece of music is
better expressed as values that you assemble rather than choices that
you branch on.

## `if … then … else`

A standard expression. Both branches must produce the same type:

```rela
scale Major = { R, M2, M3, P4, P5, M6, M7 }

let loud   = true
let melody = | <1> <3> <5> |

if loud
  then melody |> volume 1.0
  else melody |> volume 0.5
```

Chain with `else if`:

```rela
if dynamic == "ff" then
  melody |> volume 1.0
else if dynamic == "mf" then
  melody |> volume 0.7
else
  melody |> volume 0.4
```

## Pattern matching

`match` deconstructs values by shape — more readable than a chain of
`if`s when there are several cases:

```rela
let dynamic = "mf"

match dynamic {
  "ff" => melody |> volume 1.0
  "mf" => melody |> volume 0.7
  "p"  => melody |> volume 0.4
  _    => melody |> volume 0.5
}
```

Patterns can destructure tuples, lists and constructors:

```rela
let chord_quality = \chord ->
  match chord {
    [R, M3, P5]      => "major"
    [R, m3, P5]      => "minor"
    [R, M3, P5, M7]  => "major7"
    [R, m3, P5, m7]  => "minor7"
    _                => "other"
  }
```

## Boolean and comparison operators

| Operator | Meaning |
| --- | --- |
| `==` | equal |
| `!=` | not equal |
| `<`, `>`, `<=`, `>=` | ordering |
| `and`, `or`, `not` | boolean |

```rela
if tempo >= 120 then "fast"
else if tempo >= 80 then "moderate"
else "slow"
```

## Destructuring

`let (a, b) = (1, 2)` binds both halves at once. `_` ignores:

```rela
let (root, fifth) = (R, P5)
let (first, _)    = (theme, ignored)
```

Lambda parameters destructure the same way:

```rela
let sum_interval = \(a, b) -> a + b
let always_zero  = \_ -> 0
```

## Practical patterns

### Conditional transformation

```rela
let processed =
  if should_swing then melody |> swing
  else melody
```

### Lookup-by-name

```rela
let get_section = \name ->
  match name {
    "verse"  => verse
    "chorus" => chorus
    "bridge" => bridge
    _        => | - - - - |   ; silent default
  }
```

### Velocity-driven dynamics

```rela
let apply_dynamics = \(dynamic, melody) ->
  match dynamic {
    "ff" => melody |> volume 1.00
    "f"  => melody |> volume 0.85
    "mf" => melody |> volume 0.70
    "mp" => melody |> volume 0.55
    "p"  => melody |> volume 0.40
    "pp" => melody |> volume 0.25
    _    => melody |> volume 0.60
  }
```

## When *not* to branch

In music code the choice between two values is usually less
expressive than the *third* value that contains both:

```rela
; Branchy:
let intro = if upbeat then loud_intro else soft_intro

; Better — make both audible somewhere in the piece.
intro_soft ++ intro_loud
```

If you find a conditional inside a hot loop or at the top of every
section, consider whether the underlying *shape* should change —
maybe two parts in a layer, two sections in sequence, or two
expressions parameterised by an interval.

## Listen-through example

The branch chooses one phrase, then the coda proves that branching is
still just value selection.

```rela
scale Major = { R, M2, M3, P4, P5, M6, M7 }

let energetic = true
let phrase = if energetic then | <1> <3> <5> <7> |:2 else | <1> - <5> - |:2
let coda = if false then | <7> <6> <5> <3> |:2 else | <5> <3> <1> <1> |:2

phrase ++ coda
```
