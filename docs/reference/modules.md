# Module System

Relanote supports a Rust-style module system for organizing code across multiple files.

## Module Declaration

Use `mod` to declare a submodule that should be loaded from a file.

```rela
mod scales
mod chords
mod synth
```

This will look for files named `scales.rela`, `chords.rela`, and `synth.rela` in the same directory.

## Use Declaration

Use `use` to import bindings from a module.

### Simple Import

Import a single item from a module:

```rela
use scales::Major
use chords::Maj7
```

### Glob Import

Import all public bindings from a module:

```rela
use scales::*
use chords::*
```

### Grouped Import

Import multiple items at once:

```rela
use scales::{Major, Minor, Dorian}
use chords::{Maj7, Min7, Dom7}
```

### Aliased Import

Import with a different name:

```rela
use scales::{Major as MajorScale}
use chords::{Min7 as MinorSeventh}
```

## Example Project Structure

```
my_song/
├── main.rela
├── scales.rela
├── chords.rela
└── instruments.rela
```

**main.rela:**
```rela
mod scales
mod chords
mod instruments

use scales::{Major, Minor}
use chords::*
use instruments::Lead

let melody = | <1> <3> <5> <8> |
let harmony = | Maj7 Min7 |

render(
  layer [
    melody |> voice(Lead),
    harmony
  ]
)
```

**scales.rela:**
```rela
scale Major = { R, M2, M3, P4, P5, M6, M7 }
scale Minor = { R, M2, m3, P4, P5, m6, m7 }
```

**chords.rela:**
```rela
chord Maj7 = [ R, M3, P5, M7 ]
chord Min7 = [ R, m3, P5, m7 ]
chord Dom7 = [ R, M3, P5, m7 ]
```

## Module Resolution

When you write `mod foo`, Relanote looks for:

1. `foo.rela` in the same directory as the current file
2. `foo/mod.rela` (for nested modules)

## Circular Dependencies

Circular module dependencies are detected and will result in an error:

```rela
; a.rela
mod b
use b::something

; b.rela
mod a  ; Error: circular module dependency
use a::other
```

## Best Practices

1. **Organize by concern**: Group related scales, chords, or instruments into their own modules.

2. **Use specific imports**: Prefer `use foo::{A, B}` over `use foo::*` to make dependencies clear.

3. **Keep modules focused**: Each module should have a single responsibility.

4. **Export intentionally**: Only export what other modules need to use.
