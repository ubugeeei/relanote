# Relanote — MoonBit port

This directory hosts the in-progress MoonBit rewrite of Relanote.

The original Rust implementation under `../crates/` and the Nuxt playground
under `../web/` continue to be the source of truth while the rewrite lands
package by package. See the top-level `README.md` "Rewrite roadmap" section
for status.

## Packages

| Package            | Mirrors Rust crate       | Status                                                |
| ------------------ | ------------------------ | ----------------------------------------------------- |
| `relanote_core`    | `crates/relanote_core`   | Span / SourceId / Source / Spanned / InternedStr      |
| `relanote_lexer`   | `crates/relanote_lexer`  | TokenKind + tokenizer                                 |
| `relanote_ast`     | `crates/relanote_ast`    | AST data types (visitor deferred to a follow-up)      |
| `relanote_stdlib`  | `crates/relanote_stdlib` | Embedded prelude `.rela` modules + combined `PRELUDE` |
| `relanote_types`   | `crates/relanote_types`  | Type ADT, scheme, context, unify (inference walker deferred) |
| `relanote_hir`     | `crates/relanote_hir`    | Placeholder mirroring the Rust crate (also a placeholder)    |
| `relanote_parser`  | `crates/relanote_parser` | Public API + ParseError + Parser skeleton (descent deferred) |

Regenerate the stdlib embedding after editing the `.rela` sources with
`bash moonbit/scripts/gen_stdlib.sh`.

## Build

```bash
cd moonbit
moon check
moon test
```

The lexer is tested against the same fixtures as the Rust lexer, so any
behavioural drift between the two implementations should surface
immediately.
