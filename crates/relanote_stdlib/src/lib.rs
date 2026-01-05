//! Standard library for relanote
//!
//! Provides built-in scales, chords, synth presets, and utility functions
//! as embedded source code strings.

/// The standard prelude - automatically loaded before user code
/// Organized into modular files for maintainability
pub mod prelude {
    /// Scales module
    pub const SCALES: &str = include_str!("prelude/scales.rela");

    /// Chords module
    pub const CHORDS: &str = include_str!("prelude/chords.rela");

    /// Basic synth presets (8-bit, classic, basic drums)
    pub const SYNTHS_BASIC: &str = include_str!("prelude/synths_basic.rela");

    /// Piano & Electric Piano presets
    pub const SYNTHS_PIANO: &str = include_str!("prelude/synths_piano.rela");

    /// Bass instrument presets
    pub const SYNTHS_BASS: &str = include_str!("prelude/synths_bass.rela");

    /// Brass instrument presets
    pub const SYNTHS_BRASS: &str = include_str!("prelude/synths_brass.rela");

    /// Synth lead presets
    pub const SYNTHS_LEADS: &str = include_str!("prelude/synths_leads.rela");

    /// Synth pad presets
    pub const SYNTHS_PADS: &str = include_str!("prelude/synths_pads.rela");

    /// Pluck & percussive synth presets
    pub const SYNTHS_PLUCK: &str = include_str!("prelude/synths_pluck.rela");

    /// Drum kit presets (with pitch envelope)
    pub const SYNTHS_DRUMS: &str = include_str!("prelude/synths_drums.rela");

    /// Percussion instrument presets
    pub const SYNTHS_PERCUSSION: &str = include_str!("prelude/synths_percussion.rela");

    /// Retro / Lo-Fi sound presets
    pub const SYNTHS_RETRO: &str = include_str!("prelude/synths_retro.rela");

    /// Clap & hand percussion presets
    pub const SYNTHS_CLAP: &str = include_str!("prelude/synths_clap.rela");

    /// Reverb effect presets
    pub const EFFECTS_REVERB: &str = include_str!("prelude/effects_reverb.rela");

    /// Delay effect presets
    pub const EFFECTS_DELAY: &str = include_str!("prelude/effects_delay.rela");

    /// Phaser effect presets
    pub const EFFECTS_PHASER: &str = include_str!("prelude/effects_phaser.rela");

    /// Distortion effect presets
    pub const EFFECTS_DISTORTION: &str = include_str!("prelude/effects_distortion.rela");

    /// Combined prelude - all modules concatenated
    /// This maintains backward compatibility with existing code
    pub const PRELUDE: &str = concat!(
        "; ===========================================\n",
        "; Relanote Standard Prelude\n",
        "; Automatically imported into every program\n",
        "; ===========================================\n\n",
        include_str!("prelude/scales.rela"),
        "\n",
        include_str!("prelude/chords.rela"),
        "\n",
        include_str!("prelude/synths_basic.rela"),
        "\n",
        include_str!("prelude/synths_piano.rela"),
        "\n",
        include_str!("prelude/synths_bass.rela"),
        "\n",
        include_str!("prelude/synths_brass.rela"),
        "\n",
        include_str!("prelude/synths_leads.rela"),
        "\n",
        include_str!("prelude/synths_pads.rela"),
        "\n",
        include_str!("prelude/synths_pluck.rela"),
        "\n",
        include_str!("prelude/synths_drums.rela"),
        "\n",
        include_str!("prelude/synths_percussion.rela"),
        "\n",
        include_str!("prelude/synths_retro.rela"),
        "\n",
        include_str!("prelude/synths_clap.rela"),
        "\n",
        include_str!("prelude/effects_reverb.rela"),
        "\n",
        include_str!("prelude/effects_delay.rela"),
        "\n",
        include_str!("prelude/effects_phaser.rela"),
        "\n",
        include_str!("prelude/effects_distortion.rela"),
    );
}
