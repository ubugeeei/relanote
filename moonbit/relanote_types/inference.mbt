// Inference engine — the AST → Type walker is intentionally deferred to a
// follow-up PR because it touches every AST node and is the bulk of the
// Hindley–Milner implementation. The infrastructure it needs (`TyVar`,
// `Type`, `TypeScheme`, `TypeContext`, `unify`) is already in place, so
// the follow-up can land without further substrate work.
//
// Track in #7.
