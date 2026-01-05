# Language Design Deep Dive

This document explores the design philosophy and implementation of the Relanote language.

## Design Philosophy

### "Everything is Relative"

The core principle of Relanote is that music should be expressed in relative terms:

```rela
; Traditional approach: absolute pitches
| C4 E4 G4 | → | D4 F#4 A4 |  ; Must rewrite everything to transpose

; Relanote approach: relative intervals
scale Major = { R, M2, M3, P4, P5, M6, M7 }
| <1> <3> <5> | |> transpose M2  ; Just apply transformation
```

This makes music more portable and easier to manipulate.

### Functional Programming

Relanote embraces functional programming:

<svg viewBox="0 0 500 180" xmlns="http://www.w3.org/2000/svg" style="max-width: 500px; width: 100%;">
  <style>
    .title { font: bold 14px monospace; fill: #e0e0e0; }
    .label { font: bold 12px monospace; fill: #4fc3f7; }
    .desc { font: 11px monospace; fill: #b0b0b0; }
    .box { fill: #1e1e1e; stroke: #4fc3f7; stroke-width: 1.5; }
    .header { fill: #2d2d2d; }
  </style>
  <rect class="box" x="10" y="10" width="480" height="160" rx="6"/>
  <rect class="header" x="10" y="10" width="480" height="30" rx="6"/>
  <rect x="10" y="35" width="480" height="5" fill="#1e1e1e"/>
  <text class="title" x="250" y="30" text-anchor="middle">Functional Benefits</text>
  <line x1="10" y1="40" x2="490" y2="40" stroke="#4fc3f7" stroke-width="1"/>
  <text class="label" x="25" y="65">Immutability</text>
  <text class="desc" x="150" y="65">Values never change, safe composition</text>
  <text class="label" x="25" y="95">Pure Functions</text>
  <text class="desc" x="150" y="95">No side effects, predictable behavior</text>
  <text class="label" x="25" y="125">Composition</text>
  <text class="desc" x="150" y="125">Build complex from simple with pipes</text>
  <text class="label" x="25" y="155">Declarative</text>
  <text class="desc" x="150" y="155">Describe what, not how</text>
</svg>

## Interval System

### Interval Names

Relanote uses standard music theory interval names:

| Symbol | Name | Semitones |
|--------|------|-----------|
| R | Root (Unison) | 0 |
| m2 | Minor 2nd | 1 |
| M2 | Major 2nd | 2 |
| m3 | Minor 3rd | 3 |
| M3 | Major 3rd | 4 |
| P4 | Perfect 4th | 5 |
| A4 / d5 | Tritone | 6 |
| P5 | Perfect 5th | 7 |
| m6 | Minor 6th | 8 |
| M6 | Major 6th | 9 |
| m7 | Minor 7th | 10 |
| M7 | Major 7th | 11 |
| P8 | Octave | 12 |

### Quality Prefixes

```
P = Perfect   (for unisons, 4ths, 5ths, octaves)
M = Major     (for 2nds, 3rds, 6ths, 7ths)
m = minor     (for 2nds, 3rds, 6ths, 7ths)
A = Augmented (raised by half step)
d = diminished (lowered by half step)
```

### Interval Arithmetic

Intervals can be modified with `+` and `-`:

```rela
M3+   ; Major 3rd raised by half step (= 5 semitones)
P5-   ; Perfect 5th lowered by half step (= 6 semitones)
M2++  ; Major 2nd raised twice (= 4 semitones)
```

## Scale Degrees

Scale degrees reference positions within a scale:

```rela
scale Major = { R, M2, M3, P4, P5, M6, M7 }

; In C Major:
<1> → C  (degree 1 = R = root)
<2> → D  (degree 2 = M2 = major 2nd from root)
<3> → E  (degree 3 = M3 = major 3rd from root)
<4> → F  (degree 4 = P4 = perfect 4th from root)
<5> → G  (degree 5 = P5 = perfect 5th from root)
<6> → A  (degree 6 = M6 = major 6th from root)
<7> → B  (degree 7 = M7 = major 7th from root)
<8> → C' (degree 8 = octave up from root)
```

### How Scale Resolution Works

<svg viewBox="0 0 520 280" xmlns="http://www.w3.org/2000/svg" style="max-width: 520px; width: 100%;">
  <style>
    .title { font: bold 13px monospace; fill: #e0e0e0; }
    .code { font: 12px monospace; fill: #ce9178; }
    .arrow { font: 12px monospace; fill: #6a9955; }
    .num { font: 11px monospace; fill: #b5cea8; }
    .step { font: 11px monospace; fill: #b0b0b0; }
    .highlight { font: bold 11px monospace; fill: #4fc3f7; }
    .box { fill: #1e1e1e; stroke: #4fc3f7; stroke-width: 1.5; rx: 6; }
  </style>
  <text class="title" x="15" y="25">Scale Resolution Process:</text>
  <text class="code" x="30" y="55">scale Major = { R, M2, M3, P4, P5, M6, M7 }</text>
  <text class="arrow" x="128" y="75">↑</text>
  <text class="arrow" x="158" y="75">↑</text>
  <text class="arrow" x="188" y="75">↑</text>
  <text class="arrow" x="218" y="75">↑</text>
  <text class="arrow" x="248" y="75">↑</text>
  <text class="arrow" x="278" y="75">↑</text>
  <text class="arrow" x="308" y="75">↑</text>
  <text class="num" x="128" y="95">1</text>
  <text class="num" x="158" y="95">2</text>
  <text class="num" x="188" y="95">3</text>
  <text class="num" x="218" y="95">4</text>
  <text class="num" x="248" y="95">5</text>
  <text class="num" x="278" y="95">6</text>
  <text class="num" x="308" y="95">7</text>
  <text class="title" x="30" y="130">Note &lt;3&gt; in key of C:</text>
  <rect class="box" x="20" y="145" width="480" height="120"/>
  <text class="step" x="35" y="175">1. Look up degree 3 in scale →</text>
  <text class="highlight" x="280" y="175">M3 (Major 3rd)</text>
  <text class="step" x="35" y="205">2. Get current root note →</text>
  <text class="highlight" x="240" y="205">C4 (MIDI 60)</text>
  <text class="step" x="35" y="235">3. Apply interval →</text>
  <text class="highlight" x="190" y="235">60 + 4 semitones = 64 (E4)</text>
</svg>

## Type System

Relanote is statically typed with the following types:

### Primitive Types

| Type | Description | Example |
|------|-------------|---------|
| `Int` | Integer number | `42`, `-7` |
| `Float` | Floating point | `3.14`, `0.5` |
| `Bool` | Boolean | `true`, `false` |
| `String` | Text | `"hello"` |

### Music Types

| Type | Description | Example |
|------|-------------|---------|
| `Interval` | Relative pitch | `M3`, `P5`, `m7` |
| `Pitch` | Absolute pitch | `C4`, `F#5`, `Bb3` |
| `Duration` | Note length | `:4` (quarter), `:8` (eighth) |
| `Block` | Musical phrase | `\| C4 E4 G4 \|` |
| `Scale` | Set of intervals | `{ R, M2, M3, ... }` |
| `Chord` | Simultaneous notes | `[ R, M3, P5 ]` |
| `Synth` | Sound definition | `{ osc: Saw, ... }` |

### Compound Types

| Type | Description | Example |
|------|-------------|---------|
| `Array<T>` | List of values | `[1, 2, 3]` |
| `Tuple` | Fixed-size group | `(M3, P5)` |
| `Function` | Callable | `\x -> x + 1` |

## Block Syntax

Blocks are the fundamental unit of music:

<svg viewBox="0 0 520 320" xmlns="http://www.w3.org/2000/svg" style="max-width: 520px; width: 100%;">
  <style>
    .title { font: bold 14px monospace; fill: #e0e0e0; }
    .code { font: 13px monospace; fill: #ce9178; }
    .arrow { fill: #6a9955; }
    .label { font: 11px monospace; fill: #b0b0b0; }
    .box { fill: #1e1e1e; stroke: #4fc3f7; stroke-width: 1.5; }
    .header { fill: #2d2d2d; }
  </style>
  <rect class="box" x="10" y="10" width="500" height="300" rx="6"/>
  <rect class="header" x="10" y="10" width="500" height="30" rx="6"/>
  <rect x="10" y="35" width="500" height="5" fill="#1e1e1e"/>
  <text class="title" x="260" y="30" text-anchor="middle">Block Anatomy</text>
  <line x1="10" y1="40" x2="510" y2="40" stroke="#4fc3f7" stroke-width="1"/>
  <text class="code" x="50" y="80">| C4 E4:8 G4' - [C4 E4 G4] |</text>
  <!-- Arrows pointing up -->
  <text class="arrow" x="50" y="100" fill="#6a9955">↑</text>
  <text class="arrow" x="68" y="100" fill="#6a9955">↑</text>
  <text class="arrow" x="92" y="100" fill="#6a9955">↑</text>
  <text class="arrow" x="128" y="100" fill="#6a9955">↑</text>
  <text class="arrow" x="152" y="100" fill="#6a9955">↑</text>
  <text class="arrow" x="195" y="100" fill="#6a9955">↑</text>
  <text class="arrow" x="290" y="100" fill="#6a9955">↑</text>
  <!-- Vertical lines and labels -->
  <line x1="52" y1="105" x2="52" y2="280" stroke="#6a9955" stroke-width="1"/>
  <text class="label" x="60" y="285">Block start</text>
  <line x1="70" y1="105" x2="70" y2="255" stroke="#6a9955" stroke-width="1"/>
  <text class="label" x="78" y="260">Note</text>
  <line x1="94" y1="105" x2="94" y2="225" stroke="#6a9955" stroke-width="1"/>
  <text class="label" x="102" y="230">Duration modifier (eighth note)</text>
  <line x1="130" y1="105" x2="130" y2="195" stroke="#6a9955" stroke-width="1"/>
  <text class="label" x="138" y="200">Staccato articulation</text>
  <line x1="154" y1="105" x2="154" y2="165" stroke="#6a9955" stroke-width="1"/>
  <text class="label" x="162" y="170">Rest</text>
  <line x1="197" y1="105" x2="197" y2="135" stroke="#6a9955" stroke-width="1"/>
  <text class="label" x="205" y="140">Chord (simultaneous)</text>
  <line x1="292" y1="105" x2="340" y2="105" stroke="#6a9955" stroke-width="1"/>
  <text class="label" x="348" y="110">Block end</text>
</svg>

### Note Modifiers

| Modifier | Syntax | Description |
|----------|--------|-------------|
| Duration | `:n` | Note length (1=whole, 4=quarter, 8=eighth) |
| Staccato | `'` | Short, detached |
| Accent | `^` | Emphasized |
| Octave up | `++` | Raise octave |
| Octave down | `--` | Lower octave |

## Pipe Operator

The pipe operator `|>` is central to Relanote's design:

<svg viewBox="0 0 560 220" xmlns="http://www.w3.org/2000/svg" style="max-width: 560px; width: 100%;">
  <style>
    .title { font: bold 14px monospace; fill: #e0e0e0; }
    .code { font: 11px monospace; fill: #ce9178; }
    .boxtext { font: 11px monospace; fill: #e0e0e0; }
    .subtext { font: 10px monospace; fill: #4fc3f7; }
    .desc { font: 10px monospace; fill: #b0b0b0; }
    .box { fill: #1e1e1e; stroke: #4fc3f7; stroke-width: 1.5; }
    .innerbox { fill: #2d2d2d; stroke: #6a9955; stroke-width: 1; }
    .header { fill: #2d2d2d; }
  </style>
  <rect class="box" x="10" y="10" width="540" height="200" rx="6"/>
  <rect class="header" x="10" y="10" width="540" height="30" rx="6"/>
  <rect x="10" y="35" width="540" height="5" fill="#1e1e1e"/>
  <text class="title" x="280" y="30" text-anchor="middle">Pipe Operator Transformation</text>
  <line x1="10" y1="40" x2="550" y2="40" stroke="#4fc3f7" stroke-width="1"/>
  <text class="code" x="30" y="65">melody |> transpose M3 |> voice Lead |> volume 0.8</text>
  <!-- Flow boxes -->
  <rect class="innerbox" x="30" y="90" width="70" height="45" rx="4"/>
  <text class="boxtext" x="65" y="110" text-anchor="middle">melody</text>
  <text class="subtext" x="65" y="180" text-anchor="middle">Original</text>
  <text fill="#6a9955" x="110" y="112">→</text>
  <rect class="innerbox" x="130" y="90" width="100" height="45" rx="4"/>
  <text class="boxtext" x="180" y="105" text-anchor="middle">transpose</text>
  <text class="boxtext" x="180" y="122" text-anchor="middle">M3</text>
  <text class="subtext" x="180" y="180" text-anchor="middle">+4 semitones</text>
  <text fill="#6a9955" x="240" y="112">→</text>
  <rect class="innerbox" x="260" y="90" width="90" height="45" rx="4"/>
  <text class="boxtext" x="305" y="105" text-anchor="middle">voice</text>
  <text class="boxtext" x="305" y="122" text-anchor="middle">Lead</text>
  <text class="subtext" x="305" y="180" text-anchor="middle">Synth set</text>
  <text fill="#6a9955" x="360" y="112">→</text>
  <rect class="innerbox" x="380" y="90" width="80" height="45" rx="4"/>
  <text class="boxtext" x="420" y="105" text-anchor="middle">volume</text>
  <text class="boxtext" x="420" y="122" text-anchor="middle">0.8</text>
  <text class="subtext" x="420" y="180" text-anchor="middle">Quieter</text>
  <!-- Down arrows -->
  <text fill="#6a9955" x="62" y="155">↓</text>
  <text fill="#6a9955" x="177" y="155">↓</text>
  <text fill="#6a9955" x="302" y="155">↓</text>
  <text fill="#6a9955" x="417" y="155">↓</text>
</svg>

### Evaluation

`x |> f` is transformed to `f(x)` during evaluation:

```
melody |> transpose M3 |> voice Lead

; Desugars to:
voice(transpose(melody, M3), Lead)
```

## Parts and Sections

For organizing larger compositions:

```rela
let song = section "Verse" {
  part "Lead" {
    | <1> <3> <5> <8> |
  } |> voice Lead

  part "Bass" {
    | <1> - <5> - |
  } |> voice FatBass

  part "Drums" {
    | R - R R |
  } |> voice Kick
}
```

### Structure

<svg viewBox="0 0 480 340" xmlns="http://www.w3.org/2000/svg" style="max-width: 480px; width: 100%;">
  <style>
    .section-label { font: bold 13px monospace; fill: #e0e0e0; }
    .part-label { font: bold 11px monospace; fill: #4fc3f7; }
    .block-text { font: 10px monospace; fill: #ce9178; }
    .section-box { fill: #1e1e1e; stroke: #4fc3f7; stroke-width: 1.5; }
    .part-box { fill: #252525; stroke: #6a9955; stroke-width: 1; }
    .block-box { fill: #2d2d2d; stroke: #ce9178; stroke-width: 1; }
  </style>
  <!-- Section container -->
  <rect class="section-box" x="10" y="10" width="460" height="320" rx="6"/>
  <text class="section-label" x="25" y="35">Section "Verse"</text>
  <!-- Part Lead -->
  <rect class="part-box" x="25" y="50" width="430" height="75" rx="4"/>
  <text class="part-label" x="40" y="72">Part "Lead"</text>
  <rect class="block-box" x="40" y="82" width="400" height="30" rx="3"/>
  <text class="block-text" x="55" y="102">Block: | &lt;1&gt; &lt;3&gt; &lt;5&gt; &lt;8&gt; |</text>
  <!-- Part Bass -->
  <rect class="part-box" x="25" y="135" width="430" height="75" rx="4"/>
  <text class="part-label" x="40" y="157">Part "Bass"</text>
  <rect class="block-box" x="40" y="167" width="400" height="30" rx="3"/>
  <text class="block-text" x="55" y="187">Block: | &lt;1&gt; - &lt;5&gt; - |</text>
  <!-- Part Drums -->
  <rect class="part-box" x="25" y="220" width="430" height="75" rx="4"/>
  <text class="part-label" x="40" y="242">Part "Drums"</text>
  <rect class="block-box" x="40" y="252" width="400" height="30" rx="3"/>
  <text class="block-text" x="55" y="272">Block: | R - R R |</text>
</svg>

## Functions

### Built-in Functions

Relanote provides many built-in functions:

| Category | Functions |
|----------|-----------|
| Pitch | `transpose`, `invert`, `octave` |
| Time | `tempo`, `duration`, `stretch` |
| Synth | `voice`, `cutoff`, `resonance`, `adsr` |
| Mix | `volume`, `pan`, `reverb` |
| Structure | `repeat`, `reverse`, `concat` |

### User-Defined Functions

Lambda syntax for custom functions:

```rela
; Single parameter
let double = \x -> x * 2

; Multiple parameters
let add = \x y -> x + y

; With blocks
let harmonize = \melody -> melody ++ (melody |> transpose M3)
```

## Control Flow

### Conditional Expressions

```rela
let result = if condition then value1 else value2
```

### Pattern Matching

```rela
let describe = \interval ->
  match interval with
  | M3 -> "major third"
  | m3 -> "minor third"
  | P5 -> "perfect fifth"
  | _ -> "other interval"
```

## Evaluation Model

### Lazy vs Eager

Most operations are eager, but some constructs are lazy:

```
Eager: values evaluated immediately
  let x = 1 + 2  ; x = 3 immediately

Lazy: values evaluated when needed
  if condition then expensive_computation else default
  ; expensive_computation only evaluated if condition is true
```

### Environment and Scope

<svg viewBox="0 0 380 240" xmlns="http://www.w3.org/2000/svg" style="max-width: 380px; width: 100%;">
  <style>
    .scope-title { font: bold 12px monospace; fill: #4fc3f7; }
    .scope-item { font: 11px monospace; fill: #b0b0b0; }
    .tree-line { stroke: #6a9955; stroke-width: 1; }
  </style>
  <!-- Global Scope -->
  <text class="scope-title" x="20" y="25">Global Scope</text>
  <line class="tree-line" x1="20" y1="35" x2="20" y2="95"/>
  <line class="tree-line" x1="20" y1="45" x2="35" y2="45"/>
  <text class="scope-item" x="40" y="50">Prelude (scales, chords, synths)</text>
  <line class="tree-line" x1="20" y1="65" x2="35" y2="65"/>
  <text class="scope-item" x="40" y="70">User definitions</text>
  <line class="tree-line" x1="20" y1="85" x2="35" y2="85"/>
  <text class="scope-item" x="40" y="90">Current file definitions</text>
  <!-- Block Scope -->
  <text class="scope-title" x="20" y="125">Block Scope</text>
  <line class="tree-line" x1="20" y1="135" x2="20" y2="175"/>
  <line class="tree-line" x1="20" y1="145" x2="35" y2="145"/>
  <text class="scope-item" x="40" y="150">let bindings</text>
  <line class="tree-line" x1="20" y1="165" x2="35" y2="165"/>
  <text class="scope-item" x="40" y="170">Function parameters</text>
  <!-- Closure Scope -->
  <text class="scope-title" x="20" y="205">Closure Scope</text>
  <line class="tree-line" x1="20" y1="215" x2="35" y2="215"/>
  <text class="scope-item" x="40" y="220">Captured variables from enclosing scope</text>
</svg>

## Abstract Syntax Tree

The parser produces an AST that represents the program structure:

<svg viewBox="0 0 450 340" xmlns="http://www.w3.org/2000/svg" style="max-width: 450px; width: 100%;">
  <style>
    .node { font: bold 12px monospace; fill: #4fc3f7; }
    .field { font: 11px monospace; fill: #6a9955; }
    .value { font: 11px monospace; fill: #ce9178; }
    .tree-line { stroke: #555; stroke-width: 1; }
  </style>
  <!-- Program root -->
  <text class="node" x="20" y="20">Program</text>
  <line class="tree-line" x1="20" y1="30" x2="20" y2="305"/>
  <!-- Item::ScaleDef -->
  <line class="tree-line" x1="20" y1="45" x2="35" y2="45"/>
  <text class="node" x="40" y="50">Item::ScaleDef</text>
  <line class="tree-line" x1="40" y1="55" x2="40" y2="95"/>
  <line class="tree-line" x1="40" y1="70" x2="55" y2="70"/>
  <text class="field" x="60" y="75">name:</text>
  <text class="value" x="110" y="75">"Major"</text>
  <line class="tree-line" x1="40" y1="90" x2="55" y2="90"/>
  <text class="field" x="60" y="95">intervals:</text>
  <text class="value" x="140" y="95">[R, M2, M3, P4, P5, M6, M7]</text>
  <!-- Item::Let -->
  <line class="tree-line" x1="20" y1="125" x2="35" y2="125"/>
  <text class="node" x="40" y="130">Item::Let</text>
  <line class="tree-line" x1="40" y1="135" x2="40" y2="195"/>
  <line class="tree-line" x1="40" y1="150" x2="55" y2="150"/>
  <text class="field" x="60" y="155">name:</text>
  <text class="value" x="110" y="155">"melody"</text>
  <line class="tree-line" x1="40" y1="175" x2="55" y2="175"/>
  <text class="field" x="60" y="180">value:</text>
  <text class="node" x="110" y="180">Expr::Block</text>
  <line class="tree-line" x1="110" y1="185" x2="125" y2="200"/>
  <text class="field" x="130" y="205">notes:</text>
  <text class="value" x="180" y="205">[...]</text>
  <!-- Item::Expr -->
  <line class="tree-line" x1="20" y1="230" x2="35" y2="230"/>
  <text class="node" x="40" y="235">Item::Expr</text>
  <line class="tree-line" x1="40" y1="240" x2="55" y2="255"/>
  <text class="node" x="60" y="260">Expr::Pipe</text>
  <line class="tree-line" x1="60" y1="265" x2="60" y2="325"/>
  <line class="tree-line" x1="60" y1="280" x2="75" y2="280"/>
  <text class="field" x="80" y="285">left:</text>
  <text class="node" x="120" y="285">Expr::Var</text>
  <text class="value" x="190" y="285">("melody")</text>
  <line class="tree-line" x1="60" y1="305" x2="75" y2="305"/>
  <text class="field" x="80" y="310">right:</text>
  <text class="node" x="130" y="310">Expr::Call</text>
  <line class="tree-line" x1="130" y1="315" x2="145" y2="330"/>
  <text class="field" x="150" y="335">func:</text>
  <text class="value" x="195" y="335">"voice"</text>
  <text class="field" x="260" y="335">args:</text>
  <text class="value" x="300" y="335">[Expr::Var("Lead")]</text>
</svg>

## Error Handling

### Parse Errors

```
Error: Unexpected token at line 3, column 5
  |
3 | let x =
  |       ^ Expected expression after '='
```

### Type Errors

```
Error: Type mismatch at line 5
  Expected: Block
  Found: Int

5 | | C4 E4 G4 | |> transpose 3
                              ^ transpose expects an Interval, got Int
```

### Runtime Errors

```
Error: Scale degree out of range at line 7
  Scale has 7 degrees, but degree 9 was requested

7 | | <9> |
      ^^^ Invalid scale degree
```
