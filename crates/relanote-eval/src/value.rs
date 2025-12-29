//! Runtime values for relanote

use std::rc::Rc;
use std::cell::RefCell;

use relanote_ast::{Articulation, Expr, IntervalLit};
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
    Scale(ScaleValue),
    Chord(ChordValue),
    Block(BlockValue),
    Part(PartValue),
    Section(SectionValue),
    Song(SongValue),
    Articulation(Articulation),
    Envelope(EnvelopeValue),
    Dynamic(DynamicValue),

    // Collections
    Array(Vec<Value>),
    Tuple(Vec<Value>),

    // Functions
    Closure(Closure),
    Builtin(BuiltinFn),
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

/// Interval value (resolved to semitones)
#[derive(Clone, Debug)]
pub struct IntervalValue {
    pub semitones: i32,
}

impl From<&IntervalLit> for IntervalValue {
    fn from(lit: &IntervalLit) -> Self {
        Self {
            semitones: lit.semitones(),
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
#[derive(Clone, Debug)]
pub struct BlockValue {
    pub slots: Vec<SlotValue>,
}

/// Slot value in a block
#[derive(Clone, Debug)]
pub enum SlotValue {
    Note {
        interval: IntervalValue,
        articulations: Vec<Articulation>,
    },
    Rest,
    Chord {
        intervals: Vec<IntervalValue>,
        articulations: Vec<Articulation>,
    },
    Tuplet {
        slots: Vec<SlotValue>,
        target_beats: i64,
    },
}

/// Part value
#[derive(Clone, Debug)]
pub struct PartValue {
    pub instrument: String,
    pub blocks: Vec<BlockValue>,
    pub envelope: Option<EnvelopeValue>,
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
