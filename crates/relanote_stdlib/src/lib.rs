//! Standard library for relanote
//!
//! Provides built-in scales, chords, synth presets, and utility functions
//! as embedded source code strings.

/// The standard prelude - automatically loaded before user code
pub mod prelude {
    pub const PRELUDE: &str = include_str!("prelude.rela");
}
