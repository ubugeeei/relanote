//! Standard library for relanote
//!
//! Provides built-in scales, chords, and utility functions.

/// Standard library source files as embedded strings
pub mod prelude {
    pub const PRELUDE: &str = include_str!("prelude.rela");
}

pub const SCALES_SRC: &str = r#"
-- Standard scales
scale Major = { R, M2, M3, P4, P5, M6, M7 }
scale Minor = { R, M2, M3-, P4, P5, M6-, M7- }
scale Dorian = { R, M2, M3-, P4, P5, M6, M7- }
scale Phrygian = { R, M2-, M3-, P4, P5, M6-, M7- }
scale Lydian = Major with { P4+ }
scale Mixolydian = { R, M2, M3, P4, P5, M6, M7- }
scale Aeolian = Minor
scale Locrian = { R, M2-, M3-, P4, P5-, M6-, M7- }

-- Pentatonic scales
scale MajorPentatonic = { R, M2, M3, P5, M6 }
scale MinorPentatonic = { R, M3-, P4, P5, M7- }

-- Blues scale
scale Blues = { R, M3-, P4, P4+, P5, M7- }

-- Harmonic and melodic minor
scale HarmonicMinor = { R, M2, M3-, P4, P5, M6-, M7 }
scale MelodicMinor = { R, M2, M3-, P4, P5, M6, M7 }
"#;

pub const CHORDS_SRC: &str = r#"
-- Basic triads
chord Major = [ R, M3, P5 ]
chord Minor = [ R, M3-, P5 ]
chord Diminished = [ R, M3-, P5- ]
chord Augmented = [ R, M3, P5+ ]

-- Seventh chords
chord Major7 = [ R, M3, P5, M7 ]
chord Minor7 = [ R, M3-, P5, M7- ]
chord Dominant7 = [ R, M3, P5, M7- ]
chord MinorMajor7 = [ R, M3-, P5, M7 ]
chord HalfDiminished7 = [ R, M3-, P5-, M7- ]
chord Diminished7 = [ R, M3-, P5-, M6 ]

-- Extended chords
chord Major9 = [ R, M3, P5, M7, M2 ]
chord Minor9 = [ R, M3-, P5, M7-, M2 ]
chord Dominant9 = [ R, M3, P5, M7-, M2 ]

-- Suspended chords
chord Sus2 = [ R, M2, P5 ]
chord Sus4 = [ R, P4, P5 ]
chord Add9 = [ R, M3, P5, M2 ]
"#;
