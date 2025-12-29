# Syntax Reference

Complete syntax reference for Relanote.

## Comments

```rela
-- Single line comment
```

## Literals

### Intervals

```rela
R     -- Root (unison)
M2    -- Major second
m3    -- Minor third
A4    -- Augmented fourth
d5    -- Diminished fifth
P5+   -- Perfect fifth, octave up
M3-   -- Major third, octave down
```

### Numbers

```rela
42      -- Integer
3.14    -- Float
```

### Strings

```rela
"Hello, World!"
```

### Booleans

```rela
true
false
```

## Variables

### Let Binding

```rela
let name = value

-- With type annotation (optional)
let name: Type = value
```

### Let...In Expression

```rela
let x = 10 in
  x + 5    -- Returns 15
```

## Blocks

### Basic Block

```rela
| note1 note2 note3 |
```

### With Scale Degrees

```rela
| <1> <2> <3> |
```

### With Rests

```rela
| <1> - <3> |
```

### With Duration

```rela
| <1>:2 <2>:1 <3>:1 |   -- 2 beats, 1 beat, 1 beat
```

## Scale and Chord

### Scale Definition

```rela
scale Major = { R, M2, M3, P4, P5, M6, M7 }
```

### Chord Definition

```rela
chord MajorTriad = [ R, M3, P5 ]
```

## Functions

### Lambda Expression

```rela
\x -> x + 1

\x, y -> x + y
```

### Function Application

```rela
f(x)
f(x, y)
```

### Pipe Operator

```rela
x |> f          -- Same as f(x)
x |> f |> g     -- Same as g(f(x))
```

### Function Composition

```rela
f >> g    -- Same as \x -> g(f(x))
```

## Control Flow

### If Expression

```rela
if condition then
  true_expr
else
  false_expr
```

### Match Expression

```rela
match value with
  | pattern1 -> result1
  | pattern2 -> result2
  | _ -> default
```

## Operators

### Arithmetic

```rela
a + b    -- Addition
a - b    -- Subtraction
a * b    -- Multiplication
a / b    -- Division
```

### Comparison

```rela
a == b   -- Equal
a != b   -- Not equal
a < b    -- Less than
a > b    -- Greater than
a <= b   -- Less or equal
a >= b   -- Greater or equal
```

### Logical

```rela
a and b
a or b
not a
```

### Block Operations

```rela
a ++ b   -- Concatenation
```

## Articulations

```rela
<1>'     -- Staccato
<1>^     -- Accent
```

## Built-in Functions

### Block Transformations

```rela
melody |> reverse           -- Reverse the block
melody |> transpose(P5)     -- Transpose by interval
melody |> repeat(2)         -- Repeat n times
melody |> map(\n -> n + P8) -- Transform each note
```
