//! Music rendering for relanote
//!
//! Converts evaluated music values to MIDI and other formats.

mod midi;

pub use midi::{render_to_midi, MidiConfig, MidiRenderer};
