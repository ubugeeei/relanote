//! Runtime values for relanote

use std::cell::RefCell;
use std::rc::Rc;

use relanote_ast::{AbsolutePitchLit, Articulation, Expr, IntervalLit};
use relanote_core::{InternedStr, Spanned};

use crate::env::Env;

/// Runtime value
#[derive(Clone, Debug)]
pub enum Value {
    Unit,
    Bool(bool),
    Int(i64),
    Float(f64),
    String(String),

    // Music values
    Interval(IntervalValue),
    AbsolutePitch(AbsolutePitchValue),
    Scale(ScaleValue),
    Chord(ChordValue),
    Block(BlockValue),
    Part(PartValue),
    Section(SectionValue),
    Song(SongValue),
    Articulation(Articulation),
    Envelope(EnvelopeValue),
    Dynamic(DynamicValue),

    // Synth values
    Synth(SynthValue),
    Oscillator(OscillatorValue),
    Filter(FilterValue),
    ADSR(ADSREnvelope),

    // Collections
    Array(Vec<Value>),
    Tuple(Vec<Value>),

    // Functions
    Closure(Closure),
    Builtin(BuiltinFn),

    // Scale applicator: created by `in Scale` expression
    // When applied to a block, transforms <n> references using the scale
    InScaleApplicator(ScaleValue),
}

/// Closure (lambda with captured environment)
#[derive(Clone)]
pub struct Closure {
    pub params: Vec<InternedStr>,
    pub body: Rc<Spanned<Expr>>,
    pub env: Rc<RefCell<Env>>,
}

impl std::fmt::Debug for Closure {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        write!(f, "<closure>")
    }
}

/// Builtin function
pub type BuiltinFn = fn(Vec<Value>) -> Result<Value, crate::error::EvalError>;

/// Interval value (resolved to cents, 100 cents = 1 semitone)
#[derive(Clone, Debug)]
pub struct IntervalValue {
    pub cents: f64,
}

impl IntervalValue {
    /// Create a new interval from cents
    pub fn from_cents(cents: f64) -> Self {
        Self { cents }
    }

    /// Create a new interval from semitones
    pub fn from_semitones(semitones: i32) -> Self {
        Self {
            cents: semitones as f64 * 100.0,
        }
    }

    /// Get the interval in semitones (for backward compatibility)
    pub fn semitones(&self) -> f64 {
        self.cents / 100.0
    }
}

impl From<&IntervalLit> for IntervalValue {
    fn from(lit: &IntervalLit) -> Self {
        Self { cents: lit.cents() }
    }
}

/// Absolute pitch value (C4, D#3, Bb5, etc.)
#[derive(Clone, Debug)]
pub struct AbsolutePitchValue {
    /// MIDI note number (60 = C4)
    pub midi_note: u8,
}

impl AbsolutePitchValue {
    pub fn new(midi_note: u8) -> Self {
        Self { midi_note }
    }
}

impl From<&AbsolutePitchLit> for AbsolutePitchValue {
    fn from(lit: &AbsolutePitchLit) -> Self {
        Self {
            midi_note: lit.to_midi_note(),
        }
    }
}

/// Scale value
#[derive(Clone, Debug)]
pub struct ScaleValue {
    pub name: String,
    pub intervals: Vec<IntervalValue>,
}

/// Chord value
#[derive(Clone, Debug)]
pub struct ChordValue {
    pub name: String,
    pub intervals: Vec<IntervalValue>,
}

/// Block value (sequence of slots)
/// Rhythm is relative: slots are equally divided within the block's duration.
#[derive(Clone, Debug)]
pub struct BlockValue {
    pub slots: Vec<SlotValue>,
    /// Duration in beats (default: 1.0)
    pub beats: f64,
}

impl BlockValue {
    pub fn new(slots: Vec<SlotValue>) -> Self {
        Self { slots, beats: 1.0 }
    }

    pub fn with_beats(slots: Vec<SlotValue>, beats: f64) -> Self {
        Self { slots, beats }
    }
}

/// Slot value in a block
#[derive(Clone, Debug)]
pub enum SlotValue {
    Note {
        interval: IntervalValue,
        articulations: Vec<Articulation>,
        /// Explicit duration in beats (used when blocks are concatenated)
        duration_beats: Option<f64>,
    },
    Rest {
        /// Explicit duration in beats (used when blocks are concatenated)
        duration_beats: Option<f64>,
    },
    Chord {
        intervals: Vec<IntervalValue>,
        articulations: Vec<Articulation>,
        /// Explicit duration in beats (used when blocks are concatenated)
        duration_beats: Option<f64>,
    },
    Tuplet {
        slots: Vec<SlotValue>,
        target_beats: i64,
    },
}

impl SlotValue {
    /// Set explicit duration on this slot (used during block concatenation)
    /// If the slot already has a duration set, it is preserved.
    pub fn with_duration(self, beats: f64) -> Self {
        match self {
            SlotValue::Note {
                interval,
                articulations,
                duration_beats,
            } => SlotValue::Note {
                interval,
                articulations,
                duration_beats: duration_beats.or(Some(beats)),
            },
            SlotValue::Rest { duration_beats } => SlotValue::Rest {
                duration_beats: duration_beats.or(Some(beats)),
            },
            SlotValue::Chord {
                intervals,
                articulations,
                duration_beats,
            } => SlotValue::Chord {
                intervals,
                articulations,
                duration_beats: duration_beats.or(Some(beats)),
            },
            // Tuplets keep their own duration semantics
            tuplet @ SlotValue::Tuplet { .. } => tuplet,
        }
    }

    /// Get explicit duration if set
    pub fn duration_beats(&self) -> Option<f64> {
        match self {
            SlotValue::Note { duration_beats, .. } => *duration_beats,
            SlotValue::Rest { duration_beats } => *duration_beats,
            SlotValue::Chord { duration_beats, .. } => *duration_beats,
            SlotValue::Tuplet { target_beats, .. } => Some(*target_beats as f64),
        }
    }
}

/// Part value
#[derive(Clone, Debug)]
pub struct PartValue {
    pub instrument: String,
    pub blocks: Vec<BlockValue>,
    pub envelope: Option<EnvelopeValue>,
    /// Reverb send level (0.0 to 1.0, maps to MIDI CC#91 0-127)
    pub reverb_level: Option<f64>,
    /// Volume level (0.0 to 1.0, maps to MIDI CC#7 0-127)
    pub volume_level: Option<f64>,
    /// Synthesizer configuration (for WebAudio output)
    pub synth: Option<SynthValue>,
}

/// Section value
#[derive(Clone, Debug)]
pub struct SectionValue {
    pub name: String,
    pub parts: Vec<PartValue>,
}

/// Song value (final output)
#[derive(Clone, Debug)]
pub struct SongValue {
    pub sections: Vec<SectionValue>,
}

/// Envelope value
#[derive(Clone, Debug)]
pub struct EnvelopeValue {
    pub from: DynamicValue,
    pub to: DynamicValue,
    pub duration_beats: f64,
}

/// Dynamic value
#[derive(Clone, Copy, Debug)]
pub enum DynamicValue {
    PPP,
    PP,
    P,
    MP,
    MF,
    F,
    FF,
    FFF,
}

// ============================================================================
// Synth Types
// ============================================================================

/// Waveform type for oscillators
#[derive(Clone, Debug, PartialEq)]
pub enum Waveform {
    Sine,
    Square,
    Saw,
    Triangle,
    Noise,
    /// Pulse wave with duty cycle (0.0 to 1.0, 0.5 = square)
    Pulse(f64),
}

impl Waveform {
    /// Get the WebAudio oscillator type name
    pub fn to_web_audio_type(&self) -> &'static str {
        match self {
            Waveform::Sine => "sine",
            Waveform::Square => "square",
            Waveform::Saw => "sawtooth",
            Waveform::Triangle => "triangle",
            Waveform::Noise => "custom", // Noise requires custom implementation
            Waveform::Pulse(_) => "custom", // Pulse requires custom implementation
        }
    }
}

/// Filter type
#[derive(Clone, Copy, Debug, PartialEq)]
pub enum FilterType {
    LowPass,
    HighPass,
    BandPass,
}

impl FilterType {
    /// Get the WebAudio BiquadFilter type name
    pub fn to_web_audio_type(&self) -> &'static str {
        match self {
            FilterType::LowPass => "lowpass",
            FilterType::HighPass => "highpass",
            FilterType::BandPass => "bandpass",
        }
    }
}

/// Oscillator value
#[derive(Clone, Debug)]
pub struct OscillatorValue {
    pub waveform: Waveform,
    /// Mix level (0.0 to 1.0)
    pub mix: f64,
    /// Octave offset (-2 to +2)
    pub octave_offset: i8,
    /// Detune in cents
    pub detune_cents: f64,
}

impl OscillatorValue {
    pub fn new(waveform: Waveform) -> Self {
        Self {
            waveform,
            mix: 1.0,
            octave_offset: 0,
            detune_cents: 0.0,
        }
    }

    pub fn with_mix(mut self, mix: f64) -> Self {
        self.mix = mix.clamp(0.0, 1.0);
        self
    }

    pub fn with_octave(mut self, octave: i8) -> Self {
        self.octave_offset = octave.clamp(-2, 2);
        self
    }

    pub fn with_detune(mut self, cents: f64) -> Self {
        self.detune_cents = cents;
        self
    }
}

/// ADSR Envelope
#[derive(Clone, Debug)]
pub struct ADSREnvelope {
    /// Attack time in seconds
    pub attack: f64,
    /// Decay time in seconds
    pub decay: f64,
    /// Sustain level (0.0 to 1.0)
    pub sustain: f64,
    /// Release time in seconds
    pub release: f64,
}

impl Default for ADSREnvelope {
    fn default() -> Self {
        Self {
            attack: 0.01,
            decay: 0.1,
            sustain: 0.7,
            release: 0.2,
        }
    }
}

impl ADSREnvelope {
    pub fn new(attack: f64, decay: f64, sustain: f64, release: f64) -> Self {
        Self {
            attack: attack.max(0.001),
            decay: decay.max(0.0),
            sustain: sustain.clamp(0.0, 1.0),
            release: release.max(0.0),
        }
    }
}

/// Filter value
#[derive(Clone, Debug)]
pub struct FilterValue {
    pub filter_type: FilterType,
    /// Cutoff frequency in Hz
    pub cutoff: f64,
    /// Resonance (Q factor, 0.0 to 1.0)
    pub resonance: f64,
}

impl FilterValue {
    pub fn lowpass(cutoff: f64, resonance: f64) -> Self {
        Self {
            filter_type: FilterType::LowPass,
            cutoff: cutoff.max(20.0),
            resonance: resonance.clamp(0.0, 1.0),
        }
    }

    pub fn highpass(cutoff: f64, resonance: f64) -> Self {
        Self {
            filter_type: FilterType::HighPass,
            cutoff: cutoff.max(20.0),
            resonance: resonance.clamp(0.0, 1.0),
        }
    }

    pub fn bandpass(cutoff: f64, resonance: f64) -> Self {
        Self {
            filter_type: FilterType::BandPass,
            cutoff: cutoff.max(20.0),
            resonance: resonance.clamp(0.0, 1.0),
        }
    }

    /// Convert resonance (0.0-1.0) to Q factor for WebAudio
    pub fn to_q_factor(&self) -> f64 {
        // Q ranges from 0.0001 to ~30 typically
        // Map 0.0-1.0 to reasonable Q range (0.5 to 20)
        0.5 + self.resonance * 19.5
    }
}

/// Synth value - complete synthesizer configuration
#[derive(Clone, Debug)]
pub struct SynthValue {
    pub name: String,
    pub oscillators: Vec<OscillatorValue>,
    pub envelope: ADSREnvelope,
    pub filter: Option<FilterValue>,
    /// Global detune in cents
    pub detune_cents: f64,
    /// Pitch envelope for drums (start_hz, end_hz, time_seconds)
    pub pitch_envelope: Option<(f64, f64, f64)>,
}

impl SynthValue {
    pub fn new(name: impl Into<String>) -> Self {
        Self {
            name: name.into(),
            oscillators: vec![OscillatorValue::new(Waveform::Sine)],
            envelope: ADSREnvelope::default(),
            filter: None,
            detune_cents: 0.0,
            pitch_envelope: None,
        }
    }

    pub fn with_oscillators(mut self, oscillators: Vec<OscillatorValue>) -> Self {
        self.oscillators = oscillators;
        self
    }

    pub fn with_envelope(mut self, envelope: ADSREnvelope) -> Self {
        self.envelope = envelope;
        self
    }

    pub fn with_filter(mut self, filter: FilterValue) -> Self {
        self.filter = Some(filter);
        self
    }

    pub fn with_detune(mut self, cents: f64) -> Self {
        self.detune_cents = cents;
        self
    }

    pub fn with_pitch_envelope(mut self, start_hz: f64, end_hz: f64, time: f64) -> Self {
        self.pitch_envelope = Some((start_hz, end_hz, time));
        self
    }
}

impl DynamicValue {
    /// Convert to MIDI velocity (0-127)
    pub fn to_velocity(&self) -> u8 {
        match self {
            DynamicValue::PPP => 16,
            DynamicValue::PP => 33,
            DynamicValue::P => 49,
            DynamicValue::MP => 64,
            DynamicValue::MF => 80,
            DynamicValue::F => 96,
            DynamicValue::FF => 112,
            DynamicValue::FFF => 127,
        }
    }
}
