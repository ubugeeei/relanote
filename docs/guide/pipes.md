# Pipes & Composition

Relanote uses pipes for data transformation, making code read left-to-right like music flows.

## The Pipe Operator

The pipe operator `|>` passes the left value as the argument to the right function:

```rela
scale Major = { R, M2, M3, P4, P5, M6, M7 }

let melody = | <1> <3> <5> <3> |

-- Without pipes
reverse(transpose(P5, melody))

-- With pipes (much clearer!)
melody |> transpose(P5) |> reverse
```

## Chaining Transformations

Build complex transformations step by step:

```rela
scale Major = { R, M2, M3, P4, P5, M6, M7 }

let melody = | <1> <3> <5> <3> |

let result = melody
  |> transpose(P5)              -- Transpose up a fifth
  |> repeat(2)                  -- Repeat twice

result
```

## Function Composition

Use `>>` to compose functions without applying them:

```rela
-- Create a reusable transformation
let myTransform = transpose(P5) >> reverse >> repeat(2)

-- Apply to different melodies
melody1 |> myTransform
melody2 |> myTransform
```

## Partial Application

Many functions support partial application:

```rela
let upFifth = transpose(P5)      -- Partially applied
let doubled = repeat(2)

melody |> upFifth |> doubled
```

## Common Pipe Patterns

### Transform and Combine

```rela
scale Major = { R, M2, M3, P4, P5, M6, M7 }

let theme = | <1> <3> <5> <3> |

let variation = theme
  |> transpose(P4)
  |> reverse

let combined = theme ++ variation

combined
```

### Conditional Transformation

```rela
let loud = melody |> withDynamic(ff)
let soft = melody |> withDynamic(pp)

if energetic then loud else soft
```

## Lambda Expressions

Create inline functions with `\`:

```rela
scale Major = { R, M2, M3, P4, P5, M6, M7 }

let melody = | <1> <2> <3> |

-- Add an octave to each note
let higher = melody |> map(\note -> note + P8)

higher
```

## Pipeline Best Practices

1. **Read left-to-right**: Each step should logically follow the previous
2. **Name intermediate results**: For complex pipelines, use `let` bindings
3. **Keep functions pure**: Avoid side effects in pipe chains
4. **Compose for reuse**: Create named transformations for common patterns

```rela
scale Major = { R, M2, M3, P4, P5, M6, M7 }

-- Good: Clear, named stages
let melody = | <1> <3> <5> |
let transposed = melody |> transpose(P5)
let final = transposed |> repeat(2)

-- Also good: Fluent chain for simple cases
| <1> <3> <5> | |> transpose(P5) |> repeat(2)
```
