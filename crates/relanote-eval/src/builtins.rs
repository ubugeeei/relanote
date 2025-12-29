//! Built-in functions

use crate::error::EvalError;
use crate::value::{BlockValue, SlotValue, Value};

/// Reverse a block
pub fn builtin_reverse(args: Vec<Value>) -> Result<Value, EvalError> {
    if args.len() != 1 {
        return Err(EvalError::Custom {
            message: "reverse expects 1 argument".to_string(),
            span: relanote_core::Span::dummy(),
        });
    }

    match &args[0] {
        Value::Block(block) => {
            let mut slots = block.slots.clone();
            slots.reverse();
            Ok(Value::Block(BlockValue { slots }))
        }
        _ => Err(EvalError::TypeError {
            expected: "Block".to_string(),
            found: format!("{:?}", args[0]),
            span: relanote_core::Span::dummy(),
        }),
    }
}

/// Repeat a block n times
pub fn builtin_repeat(args: Vec<Value>) -> Result<Value, EvalError> {
    if args.len() != 2 {
        return Err(EvalError::Custom {
            message: "repeat expects 2 arguments".to_string(),
            span: relanote_core::Span::dummy(),
        });
    }

    let n = match &args[0] {
        Value::Int(n) => *n as usize,
        _ => {
            return Err(EvalError::TypeError {
                expected: "Int".to_string(),
                found: format!("{:?}", args[0]),
                span: relanote_core::Span::dummy(),
            })
        }
    };

    match &args[1] {
        Value::Block(block) => {
            let mut slots = Vec::new();
            for _ in 0..n {
                slots.extend(block.slots.clone());
            }
            Ok(Value::Block(BlockValue { slots }))
        }
        _ => Err(EvalError::TypeError {
            expected: "Block".to_string(),
            found: format!("{:?}", args[1]),
            span: relanote_core::Span::dummy(),
        }),
    }
}

/// Transpose a block by an interval
pub fn builtin_transpose(args: Vec<Value>) -> Result<Value, EvalError> {
    if args.len() != 2 {
        return Err(EvalError::Custom {
            message: "transpose expects 2 arguments".to_string(),
            span: relanote_core::Span::dummy(),
        });
    }

    let semitones = match &args[0] {
        Value::Interval(interval) => interval.semitones,
        _ => {
            return Err(EvalError::TypeError {
                expected: "Interval".to_string(),
                found: format!("{:?}", args[0]),
                span: relanote_core::Span::dummy(),
            })
        }
    };

    match &args[1] {
        Value::Block(block) => {
            let slots: Vec<SlotValue> = block
                .slots
                .iter()
                .map(|slot| transpose_slot(slot, semitones))
                .collect();
            Ok(Value::Block(BlockValue { slots }))
        }
        _ => Err(EvalError::TypeError {
            expected: "Block".to_string(),
            found: format!("{:?}", args[1]),
            span: relanote_core::Span::dummy(),
        }),
    }
}

fn transpose_slot(slot: &SlotValue, semitones: i32) -> SlotValue {
    match slot {
        SlotValue::Note {
            interval,
            articulations,
        } => SlotValue::Note {
            interval: crate::value::IntervalValue {
                semitones: interval.semitones + semitones,
            },
            articulations: articulations.clone(),
        },
        SlotValue::Rest => SlotValue::Rest,
        SlotValue::Chord {
            intervals,
            articulations,
        } => SlotValue::Chord {
            intervals: intervals
                .iter()
                .map(|i| crate::value::IntervalValue {
                    semitones: i.semitones + semitones,
                })
                .collect(),
            articulations: articulations.clone(),
        },
        SlotValue::Tuplet {
            slots,
            target_beats,
        } => SlotValue::Tuplet {
            slots: slots.iter().map(|s| transpose_slot(s, semitones)).collect(),
            target_beats: *target_beats,
        },
    }
}
