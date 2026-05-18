# Relanote — MoonBit port

This directory hosts the in-progress MoonBit rewrite of Relanote.

The original Rust implementation under `../crates/` and the Nuxt playground
under `../web/` continue to be the source of truth while the rewrite lands
package by package. See the top-level `README.md` "Rewrite roadmap" section
for status.

## Packages

| Package          | Mirrors Rust crate     | Status                          |
| ---------------- | ---------------------- | ------------------------------- |
| `relanote_core`  | `crates/relanote_core` | Span / SourceId / Source ported |
| `relanote_lexer` | `crates/relanote_lexer`| TokenKind + tokenizer ported    |

## Build

```bash
cd moonbit
moon check
moon test
```

The lexer is tested against the same fixtures as the Rust lexer, so any
behavioural drift between the two implementations should surface
immediately.
