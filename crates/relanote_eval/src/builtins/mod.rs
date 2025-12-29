//! Built-in functions for relanote
//!
//! This module provides native functions that are available in every relanote program.
//! Functions are organized into categories:
//!
//! - `block`: Block transformations (reverse, repeat, transpose, swing, etc.)
//! - `effects`: Audio effects (reverb, volume, etc.)
//! - `synth`: Synthesizer modifiers (voice, cutoff, resonance, etc.)
//! - `functional`: Functional programming utilities (map, filter, fold, etc.)

pub mod block;
pub mod effects;
pub mod functional;
pub mod synth;

// Re-export all builtins for convenient access
pub use block::*;
pub use effects::*;
pub use functional::*;
pub use synth::*;
