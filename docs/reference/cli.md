# CLI Reference

Relanote command-line interface reference.

## Installation

```bash
cargo install relanote
```

Or build from source:

```bash
git clone https://github.com/ubugeeei/relanote
cd relanote
cargo install --path crates/relanote_cli
```

## Commands

### relanote

Run a Relanote file:

```bash
relanote <file.rela>
```

### relanote render

Render a Relanote file to MIDI:

```bash
relanote render <file.rela> -o output.mid
```

**Options:**
- `-o, --output <file>` - Output MIDI file path

### relanote check

Type check a Relanote file without running:

```bash
relanote check <file.rela>
```

### relanote fmt

Format a Relanote file:

```bash
relanote fmt <file.rela>
```

### relanote repl

Start an interactive REPL:

```bash
relanote repl
```

## Examples

```bash
# Run a file
relanote examples/01_hello.rela

# Render to MIDI
relanote render mysong.rela -o mysong.mid

# Check for type errors
relanote check mysong.rela

# Format code
relanote fmt mysong.rela
```

## Exit Codes

| Code | Meaning |
|------|---------|
| 0 | Success |
| 1 | Error (parse, type, or runtime error) |
