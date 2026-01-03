# Control Flow

Relanote provides control flow constructs for conditional logic and decision-making in your compositions.

## If-Then-Else

The basic conditional expression:

```rela
scale Major = { R, M2, M3, P4, P5, M6, M7 }

let loud = true
let melody = | <1> <3> <5> |

if loud then
  melody |> volume 1.0
else
  melody |> volume 0.5
```

### Chained Conditionals

```rela
scale Major = { R, M2, M3, P4, P5, M6, M7 }

let dynamic = "ff"
let melody = | <1> <3> <5> |

if dynamic == "ff" then
  melody |> volume 1.0
else if dynamic == "mf" then
  melody |> volume 0.7
else if dynamic == "p" then
  melody |> volume 0.4
else
  melody |> volume 0.5
```

## Boolean Operators

Combine conditions with `and`, `or`, and `not`:

```rela
let x = 5
let y = 10

; Logical and
if x > 0 and y > 0 then "both positive" else "not both positive"

; Logical or
if x > 10 or y > 5 then "at least one condition met" else "neither"

; Logical not
if not (x == y) then "different" else "same"
```

## Comparison Operators

| Operator | Meaning |
|----------|---------|
| `==` | Equal |
| `!=` | Not equal |
| `<` | Less than |
| `>` | Greater than |
| `<=` | Less than or equal |
| `>=` | Greater than or equal |

```rela
set tempo = 120

if tempo >= 120 then
  "fast tempo"
else if tempo >= 80 then
  "moderate tempo"
else
  "slow tempo"
```

## Destructuring

Destructure values in `let` bindings:

```rela
; Simple binding
let x = 5

; Tuple destructuring
let (a, b) = (1, 2)

; Wildcard pattern (ignore a value)
let (first, _) = (42, "unused")
```

### Lambda Parameters

Lambda parameters support destructuring:

```rela
; Simple parameter
\x -> x + 1

; Tuple parameter
\(a, b) -> a + b

; Wildcard (ignore parameter)
\_ -> 0
```

## Practical Examples

### Dynamic Volume Control

```rela
scale Major = { R, M2, M3, P4, P5, M6, M7 }

let apply_dynamics = \dynamic melody ->
  if dynamic == "forte" then
    melody |> volume 1.0
  else if dynamic == "piano" then
    melody |> volume 0.4
  else
    melody |> volume 0.7

let theme = | <1> <3> <5> |
theme |> apply_dynamics "forte"
```

### Conditional Transformations

```rela
scale Major = { R, M2, M3, P4, P5, M6, M7 }

let should_swing = true
let melody = | <1> <2> <3> <4> <5> <6> <7> <8> |

let processed =
  if should_swing then
    melody |> swing
  else
    melody

processed
```

### Section Selection

```rela
scale Major = { R, M2, M3, P4, P5, M6, M7 }

let verse = | <1> <2> <3> <2> <1>~ - - - |
let chorus = | <5>^ <6>^ <7>^ <8>^ <8> <7> <6> <5> |
let bridge = | <4>~ <5> <6>~ <5> <3>~ - - - |

let get_section = \name ->
  if name == "verse" then verse
  else if name == "chorus" then chorus
  else if name == "bridge" then bridge
  else | - - - - |  ; rest as default

get_section "chorus"
```

## Best Practices

1. **Keep conditions simple**: Complex logic should be broken into named functions
2. **Use meaningful variable names**: `is_loud`, `should_swing`, `has_reverb`
3. **Always handle else cases**: Provide default values for robustness
4. **Prefer composition over conditionals**: When possible, use function composition instead of if-then-else
