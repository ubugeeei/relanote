use std::str::FromStr;

use relanote_core::Spanned;
use relanote_lexer::token::{Accidental, IntervalQuality};

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

        // Apply accidentals
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
    /// A single note with optional articulations
    Note {
        pitch: Spanned<Pitch>,
        articulations: Vec<Articulation>,
    },
    /// Rest (-)
    Rest,
    /// Chord (multiple simultaneous pitches)
    Chord {
        pitches: Vec<Spanned<Pitch>>,
        articulations: Vec<Articulation>,
    },
    /// Nested tuplet
    Tuplet(Tuplet),
}

/// Block: | slot slot slot |
#[derive(Clone, Debug)]
pub struct Block {
    pub slots: Vec<Spanned<Slot>>,
}

impl Block {
    pub fn new(slots: Vec<Spanned<Slot>>) -> Self {
        Self { slots }
    }

    pub fn empty() -> Self {
        Self { slots: Vec::new() }
    }

    /// Get the number of slots (for rhythm calculation)
    pub fn slot_count(&self) -> usize {
        self.slots.len()
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

/// Part expression: Part "instrument"
#[derive(Clone, Debug)]
pub struct PartExpr {
    pub instrument: Box<Spanned<Expr>>,
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
        assert_eq!(
            IntervalLit::new(IntervalQuality::Major, 3).semitones(),
            4
        );

        // Perfect fifth = 7 semitones
        assert_eq!(
            IntervalLit::new(IntervalQuality::Perfect, 5).semitones(),
            7
        );

        // Minor seventh = 10 semitones
        assert_eq!(
            IntervalLit::new(IntervalQuality::Minor, 7).semitones(),
            10
        );

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
