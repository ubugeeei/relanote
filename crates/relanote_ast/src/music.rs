use std::str::FromStr;

use relanote_core::Spanned;
use relanote_lexer::token::{AbsolutePitchData, Accidental, IntervalQuality};

use crate::expr::{Expr, Ident};

/// Dynamic marking
#[derive(Clone, Copy, Debug, PartialEq, Eq, Hash)]
pub enum Dynamic {
    Pianississimo, // ppp
    Pianissimo,    // pp
    Piano,         // p
    MezzoPiano,    // mp
    MezzoForte,    // mf
    Forte,         // f
    Fortissimo,    // ff
    Fortississimo, // fff
}

/// Error when parsing a dynamic marking
#[derive(Debug, Clone)]
pub struct ParseDynamicError;

impl std::fmt::Display for ParseDynamicError {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        write!(f, "invalid dynamic marking")
    }
}

impl std::error::Error for ParseDynamicError {}

impl FromStr for Dynamic {
    type Err = ParseDynamicError;

    fn from_str(s: &str) -> Result<Self, Self::Err> {
        match s {
            "ppp" => Ok(Dynamic::Pianississimo),
            "pp" => Ok(Dynamic::Pianissimo),
            "p" => Ok(Dynamic::Piano),
            "mp" => Ok(Dynamic::MezzoPiano),
            "mf" => Ok(Dynamic::MezzoForte),
            "f" => Ok(Dynamic::Forte),
            "ff" => Ok(Dynamic::Fortissimo),
            "fff" => Ok(Dynamic::Fortississimo),
            _ => Err(ParseDynamicError),
        }
    }
}

/// Interval literal (parsed from M3, P5+, m7-, etc.)
#[derive(Clone, Debug, PartialEq, Eq)]
pub struct IntervalLit {
    pub quality: IntervalQuality,
    pub degree: u8,
    pub accidentals: Vec<Accidental>,
}

impl IntervalLit {
    pub fn new(quality: IntervalQuality, degree: u8) -> Self {
        Self {
            quality,
            degree,
            accidentals: Vec::new(),
        }
    }

    pub fn with_accidentals(mut self, accidentals: Vec<Accidental>) -> Self {
        self.accidentals = accidentals;
        self
    }

    /// Calculate the semitone offset from the root
    pub fn semitones(&self) -> i32 {
        // Base semitones for each degree (assuming major scale)
        let base = match (self.quality, self.degree) {
            // Unison
            (_, 1) => 0,
            // Second
            (IntervalQuality::Major, 2) => 2,
            (IntervalQuality::Minor, 2) => 1,
            // Third
            (IntervalQuality::Major, 3) => 4,
            (IntervalQuality::Minor, 3) => 3,
            // Fourth
            (IntervalQuality::Perfect, 4) => 5,
            (IntervalQuality::Augmented, 4) => 6,
            // Fifth
            (IntervalQuality::Perfect, 5) => 7,
            (IntervalQuality::Diminished, 5) => 6,
            // Sixth
            (IntervalQuality::Major, 6) => 9,
            (IntervalQuality::Minor, 6) => 8,
            // Seventh
            (IntervalQuality::Major, 7) => 11,
            (IntervalQuality::Minor, 7) => 10,
            // Octave and beyond
            (_, n) if n > 7 => {
                let octaves = (n - 1) / 7;
                let remainder = ((n - 1) % 7) + 1;
                let base_interval = IntervalLit::new(self.quality, remainder);
                base_interval.semitones() + (octaves as i32 * 12)
            }
            // Default case
            _ => 0,
        };

        // Apply accidentals (each +/- is 1 semitone)
        let accidental_offset: i32 = self
            .accidentals
            .iter()
            .map(|a| match a {
                Accidental::Sharp => 1,
                Accidental::Flat => -1,
            })
            .sum();

        base + accidental_offset
    }

    /// Calculate the cent offset from the root (100 cents = 1 semitone)
    pub fn cents(&self) -> f64 {
        self.semitones() as f64 * 100.0
    }
}

/// Absolute pitch literal (C4, D#3, Bb5, etc.)
#[derive(Clone, Debug, PartialEq, Eq)]
pub struct AbsolutePitchLit {
    /// Note name (C, D, E, F, G, A, B)
    pub note: char,
    /// Accidental: sharp (#) = +1, flat (b) = -1, natural = 0
    pub accidental: i8,
    /// Octave number (4 = middle C octave)
    pub octave: u8,
}

impl AbsolutePitchLit {
    pub fn new(note: char, accidental: i8, octave: u8) -> Self {
        Self {
            note,
            accidental,
            octave,
        }
    }

    /// Convert to MIDI note number (C4 = 60)
    pub fn to_midi_note(&self) -> u8 {
        let base = match self.note {
            'C' => 0,
            'D' => 2,
            'E' => 4,
            'F' => 5,
            'G' => 7,
            'A' => 9,
            'B' => 11,
            _ => 0,
        };
        let midi = 12 * (self.octave as i16 + 1) + base as i16 + self.accidental as i16;
        midi.clamp(0, 127) as u8
    }
}

impl From<AbsolutePitchData> for AbsolutePitchLit {
    fn from(data: AbsolutePitchData) -> Self {
        Self {
            note: data.note,
            accidental: data.accidental,
            octave: data.octave,
        }
    }
}

/// Articulation type
#[derive(Clone, Copy, Debug, PartialEq, Eq, Hash)]
pub enum Articulation {
    Staccato,   // *
    Accent,     // ^
    Portamento, // ~
}

/// A pitch in a block (can be interval or scale index)
#[derive(Clone, Debug)]
pub enum Pitch {
    /// Direct interval (M3, P5, etc.)
    Interval(IntervalLit),
    /// Scale index (<1>, <3>, etc.)
    ScaleIndex(u8),
    /// Scale index with accidentals (<4+>)
    ScaleIndexMod(u8, Vec<Accidental>),
    /// Root reference (R)
    Root,
}

/// A slot in a block (note, rest, chord, or tuplet)
#[derive(Clone, Debug)]
pub enum Slot {
    /// A single note with optional articulations and duration
    Note {
        pitch: Spanned<Pitch>,
        articulations: Vec<Articulation>,
        /// Explicit duration in slots (e.g., :2 means this note takes 2 slot positions)
        duration: Option<u32>,
    },
    /// Rest (-) with optional duration
    Rest {
        /// Explicit duration in slots (e.g., :2 means this rest takes 2 slot positions)
        duration: Option<u32>,
    },
    /// Chord (multiple simultaneous pitches)
    Chord {
        pitches: Vec<Spanned<Pitch>>,
        articulations: Vec<Articulation>,
        /// Explicit duration in slots
        duration: Option<u32>,
    },
    /// Nested tuplet
    Tuplet(Tuplet),
}

/// Block: | slot slot slot | or | slot slot slot |:n
/// Rhythm is relative: slots are equally divided within the block's duration.
#[derive(Clone, Debug)]
pub struct Block {
    pub slots: Vec<Spanned<Slot>>,
    /// Number of beats for this block. None means 1 beat (default).
    pub beats: Option<f64>,
}

impl Block {
    pub fn new(slots: Vec<Spanned<Slot>>) -> Self {
        Self { slots, beats: None }
    }

    pub fn with_beats(slots: Vec<Spanned<Slot>>, beats: f64) -> Self {
        Self {
            slots,
            beats: Some(beats),
        }
    }

    pub fn empty() -> Self {
        Self {
            slots: Vec::new(),
            beats: None,
        }
    }

    /// Get the number of slots (for rhythm calculation)
    pub fn slot_count(&self) -> usize {
        self.slots.len()
    }

    /// Get the duration in beats (default: 1.0)
    pub fn duration_beats(&self) -> f64 {
        self.beats.unwrap_or(1.0)
    }
}

/// Tuplet: { contents }:n
#[derive(Clone, Debug)]
pub struct Tuplet {
    pub contents: Vec<Spanned<Slot>>,
    pub target_beats: Box<Spanned<Expr>>,
}

/// Envelope literal: env(from, to, duration)
#[derive(Clone, Debug)]
pub struct EnvelopeLit {
    pub from: Box<Spanned<Expr>>,
    pub to: Box<Spanned<Expr>>,
    pub duration: Box<Spanned<Expr>>,
}

/// Scale definition
#[derive(Clone, Debug)]
pub struct ScaleDef {
    pub name: Ident,
    pub base: Option<Spanned<Expr>>,
    pub intervals: Vec<Spanned<IntervalLit>>,
}

/// Chord definition
#[derive(Clone, Debug)]
pub struct ChordDef {
    pub name: Ident,
    pub intervals: Vec<Spanned<IntervalLit>>,
}

// ============================================================================
// Synth Definition AST
// ============================================================================

/// Synth definition: synth Lead = { osc: Saw, env: { ... }, filter: LowPass(...) }
#[derive(Clone, Debug)]
pub struct SynthDef {
    pub name: Ident,
    pub properties: Vec<Spanned<SynthProperty>>,
}

/// A property in a synth definition
#[derive(Clone, Debug)]
pub enum SynthProperty {
    /// osc: Saw + Square(0.3)
    Oscillator(Spanned<Expr>),
    /// env: { A: 0.01, D: 0.1, S: 0.7, R: 0.3 }
    Envelope(Spanned<Expr>),
    /// filter: LowPass(800, 0.5)
    Filter(Spanned<Expr>),
    /// detune: 5
    Detune(Spanned<Expr>),
    /// pitch_env: (start_hz, end_hz, time_seconds)
    /// Used for drum sounds like kicks where pitch sweeps down
    PitchEnvelope(Spanned<Expr>),
}

/// Part expression: part "instrument" { body }
#[derive(Clone, Debug)]
pub struct PartExpr {
    pub instrument: Box<Spanned<Expr>>,
    pub body: Option<Box<Spanned<Expr>>>,
}

/// Section expression: section "name" { ... }
#[derive(Clone, Debug)]
pub struct SectionExpr {
    pub name: Spanned<Expr>,
    pub context: Option<SectionContext>,
    pub body: Spanned<Expr>,
}

/// Section context: with key:G, scale:Lydian { ... }
#[derive(Clone, Debug)]
pub struct SectionContext {
    pub key: Option<Spanned<Expr>>,
    pub scale: Option<Spanned<Expr>>,
    pub tempo: Option<Spanned<Expr>>,
}

/// Layer expression: layer [ part1, part2, ... ]
#[derive(Clone, Debug)]
pub struct LayerExpr {
    pub parts: Vec<Spanned<Expr>>,
}

/// Duration unit
#[derive(Clone, Copy, Debug, PartialEq)]
pub enum DurationUnit {
    Bars(u32),
    Beats(u32),
}

impl DurationUnit {
    /// Convert to beats given a time signature numerator
    pub fn to_beats(&self, beats_per_bar: u32) -> f64 {
        match self {
            DurationUnit::Bars(n) => (*n as f64) * (beats_per_bar as f64),
            DurationUnit::Beats(n) => *n as f64,
        }
    }
}

/// Dynamic literal
#[derive(Clone, Debug)]
pub struct DynamicLit {
    pub dynamic: Dynamic,
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_interval_semitones() {
        // Major third = 4 semitones
        assert_eq!(IntervalLit::new(IntervalQuality::Major, 3).semitones(), 4);

        // Perfect fifth = 7 semitones
        assert_eq!(IntervalLit::new(IntervalQuality::Perfect, 5).semitones(), 7);

        // Minor seventh = 10 semitones
        assert_eq!(IntervalLit::new(IntervalQuality::Minor, 7).semitones(), 10);

        // Augmented fourth = 6 semitones
        assert_eq!(
            IntervalLit::new(IntervalQuality::Augmented, 4).semitones(),
            6
        );

        // Perfect fifth with sharp = 8 semitones
        assert_eq!(
            IntervalLit::new(IntervalQuality::Perfect, 5)
                .with_accidentals(vec![Accidental::Sharp])
                .semitones(),
            8
        );

        // Major third with flat = 3 semitones (enharmonic to minor third)
        assert_eq!(
            IntervalLit::new(IntervalQuality::Major, 3)
                .with_accidentals(vec![Accidental::Flat])
                .semitones(),
            3
        );
    }
}
