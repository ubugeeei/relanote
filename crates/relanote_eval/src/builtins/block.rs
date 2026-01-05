//! Block transformation builtins

use crate::error::EvalError;
use crate::value::{BlockValue, IntervalValue, PartValue, SlotValue, Value};

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
            Ok(Value::Block(BlockValue {
                slots,
                beats: block.beats,
            }))
        }
        _ => Err(EvalError::TypeError {
            expected: "Block".to_string(),
            found: format!("{:?}", args[0]),
            span: relanote_core::Span::dummy(),
        }),
    }
}

/// Rotate a block by n positions
/// Usage: block |> rotate(n) or rotate(n, block)
/// Positive n rotates left (first elements move to end)
/// Negative n rotates right (last elements move to start)
pub fn builtin_rotate(args: Vec<Value>) -> Result<Value, EvalError> {
    if args.len() != 2 {
        return Err(EvalError::Custom {
            message: "rotate expects 2 arguments".to_string(),
            span: relanote_core::Span::dummy(),
        });
    }

    // Support both argument orders: (block, n) or (n, block)
    let (block, n) = match (&args[0], &args[1]) {
        (Value::Block(block), Value::Int(n)) => (block, *n),
        (Value::Int(n), Value::Block(block)) => (block, *n),
        _ => {
            return Err(EvalError::TypeError {
                expected: "Block and Int".to_string(),
                found: format!("{:?}, {:?}", args[0], args[1]),
                span: relanote_core::Span::dummy(),
            })
        }
    };

    if block.slots.is_empty() {
        return Ok(Value::Block(block.clone()));
    }

    let len = block.slots.len() as i64;
    // Normalize n to be within [0, len)
    let n = ((n % len) + len) % len;

    let mut slots = block.slots.clone();
    slots.rotate_left(n as usize);

    Ok(Value::Block(BlockValue {
        slots,
        beats: block.beats,
    }))
}

/// Repeat a block n times
/// Usage: block |> repeat(n) or repeat(n, block)
pub fn builtin_repeat(args: Vec<Value>) -> Result<Value, EvalError> {
    if args.len() != 2 {
        return Err(EvalError::Custom {
            message: "repeat expects 2 arguments".to_string(),
            span: relanote_core::Span::dummy(),
        });
    }

    // Support both argument orders: (block, n) or (n, block)
    let (block, n) = match (&args[0], &args[1]) {
        (Value::Block(block), Value::Int(n)) => (block, *n as usize),
        (Value::Int(n), Value::Block(block)) => (block, *n as usize),
        _ => {
            return Err(EvalError::TypeError {
                expected: "Block and Int".to_string(),
                found: format!("{:?}, {:?}", args[0], args[1]),
                span: relanote_core::Span::dummy(),
            })
        }
    };

    let mut slots = Vec::new();
    for _ in 0..n {
        slots.extend(block.slots.clone());
    }
    // Repeat n times means n times the duration
    Ok(Value::Block(BlockValue {
        slots,
        beats: block.beats * n as f64,
    }))
}

/// Transpose a block up by one octave (12 semitones / 1200 cents)
/// Usage: block |> octaveUp or octaveUp(block)
pub fn builtin_octave_up(args: Vec<Value>) -> Result<Value, EvalError> {
    if args.len() != 1 {
        return Err(EvalError::Custom {
            message: "octaveUp expects 1 argument".to_string(),
            span: relanote_core::Span::dummy(),
        });
    }

    match &args[0] {
        Value::Block(block) => {
            let cents = 1200.0; // One octave = 12 semitones = 1200 cents
            let slots: Vec<SlotValue> = block
                .slots
                .iter()
                .map(|slot| transpose_slot(slot, cents))
                .collect();
            Ok(Value::Block(BlockValue {
                slots,
                beats: block.beats,
            }))
        }
        _ => Err(EvalError::TypeError {
            expected: "Block".to_string(),
            found: format!("{:?}", args[0]),
            span: relanote_core::Span::dummy(),
        }),
    }
}

/// Transpose a block down by one octave (12 semitones / 1200 cents)
/// Usage: block |> octaveDown or octaveDown(block)
pub fn builtin_octave_down(args: Vec<Value>) -> Result<Value, EvalError> {
    if args.len() != 1 {
        return Err(EvalError::Custom {
            message: "octaveDown expects 1 argument".to_string(),
            span: relanote_core::Span::dummy(),
        });
    }

    match &args[0] {
        Value::Block(block) => {
            let cents = -1200.0; // One octave down
            let slots: Vec<SlotValue> = block
                .slots
                .iter()
                .map(|slot| transpose_slot(slot, cents))
                .collect();
            Ok(Value::Block(BlockValue {
                slots,
                beats: block.beats,
            }))
        }
        _ => Err(EvalError::TypeError {
            expected: "Block".to_string(),
            found: format!("{:?}", args[0]),
            span: relanote_core::Span::dummy(),
        }),
    }
}

/// Transpose a block by an interval
/// Usage: block |> transpose(interval) or transpose(interval, block)
pub fn builtin_transpose(args: Vec<Value>) -> Result<Value, EvalError> {
    if args.len() != 2 {
        return Err(EvalError::Custom {
            message: "transpose expects 2 arguments".to_string(),
            span: relanote_core::Span::dummy(),
        });
    }

    // Support both argument orders: (block, interval) or (interval, block)
    let (block, cents) = match (&args[0], &args[1]) {
        (Value::Block(block), Value::Interval(interval)) => (block, interval.cents),
        (Value::Interval(interval), Value::Block(block)) => (block, interval.cents),
        _ => {
            return Err(EvalError::TypeError {
                expected: "Block and Interval".to_string(),
                found: format!("{:?}, {:?}", args[0], args[1]),
                span: relanote_core::Span::dummy(),
            })
        }
    };

    let slots: Vec<SlotValue> = block
        .slots
        .iter()
        .map(|slot| transpose_slot(slot, cents))
        .collect();
    Ok(Value::Block(BlockValue {
        slots,
        beats: block.beats,
    }))
}

fn transpose_slot(slot: &SlotValue, cents: f64) -> SlotValue {
    match slot {
        SlotValue::Note {
            interval,
            articulations,
            duration_beats,
        } => SlotValue::Note {
            interval: IntervalValue {
                cents: interval.cents + cents,
            },
            articulations: articulations.clone(),
            duration_beats: *duration_beats,
        },
        SlotValue::Rest { duration_beats } => SlotValue::Rest {
            duration_beats: *duration_beats,
        },
        SlotValue::Chord {
            intervals,
            articulations,
            duration_beats,
        } => SlotValue::Chord {
            intervals: intervals
                .iter()
                .map(|i| IntervalValue {
                    cents: i.cents + cents,
                })
                .collect(),
            articulations: articulations.clone(),
            duration_beats: *duration_beats,
        },
        SlotValue::Tuplet {
            slots,
            target_beats,
        } => SlotValue::Tuplet {
            slots: slots.iter().map(|s| transpose_slot(s, cents)).collect(),
            target_beats: *target_beats,
        },
    }
}

/// Apply swing feel to a block
/// Converts pairs of notes to 5-slot swing pattern: | n1 n2 | -> | n1~ - - n2 - |
/// Ratio is 3:2 (light swing), not 2:1 (shuffle)
/// Usage: block |> swing or swing(block)
pub fn builtin_swing(args: Vec<Value>) -> Result<Value, EvalError> {
    if args.len() != 1 {
        return Err(EvalError::Custom {
            message: "swing expects 1 argument".to_string(),
            span: relanote_core::Span::dummy(),
        });
    }

    let block = match &args[0] {
        Value::Block(block) => block,
        _ => {
            return Err(EvalError::TypeError {
                expected: "Block".to_string(),
                found: format!("{:?}", args[0]),
                span: relanote_core::Span::dummy(),
            })
        }
    };

    // Process pairs of notes into 5-slot swing pattern (3:2 ratio)
    let mut swing_slots = Vec::new();
    let mut iter = block.slots.iter().peekable();

    while iter.peek().is_some() {
        let first = iter.next();
        let second = iter.next();

        // Position 1: first note with slur
        if let Some(slot) = first {
            swing_slots.push(add_slur(slot.clone()));
        } else {
            swing_slots.push(SlotValue::Rest {
                duration_beats: None,
            });
        }

        // Positions 2-3: rest
        for _ in 0..2 {
            swing_slots.push(SlotValue::Rest {
                duration_beats: None,
            });
        }

        // Position 4: second note
        if let Some(slot) = second {
            swing_slots.push(slot.clone());
        } else {
            swing_slots.push(SlotValue::Rest {
                duration_beats: None,
            });
        }

        // Position 5: rest
        swing_slots.push(SlotValue::Rest {
            duration_beats: None,
        });
    }

    Ok(Value::Block(BlockValue {
        slots: swing_slots,
        beats: block.beats,
    }))
}

/// Add slur (portamento) articulation to a slot
fn add_slur(slot: SlotValue) -> SlotValue {
    match slot {
        SlotValue::Note {
            interval,
            mut articulations,
            duration_beats,
        } => {
            if !articulations.contains(&relanote_ast::Articulation::Portamento) {
                articulations.push(relanote_ast::Articulation::Portamento);
            }
            SlotValue::Note {
                interval,
                articulations,
                duration_beats,
            }
        }
        SlotValue::Chord {
            intervals,
            mut articulations,
            duration_beats,
        } => {
            if !articulations.contains(&relanote_ast::Articulation::Portamento) {
                articulations.push(relanote_ast::Articulation::Portamento);
            }
            SlotValue::Chord {
                intervals,
                articulations,
                duration_beats,
            }
        }
        other => other,
    }
}

/// Double the tempo of a block (halve all durations)
/// Usage: block |> double_time
pub fn builtin_double_time(args: Vec<Value>) -> Result<Value, EvalError> {
    if args.len() != 1 {
        return Err(EvalError::Custom {
            message: "double_time expects 1 argument".to_string(),
            span: relanote_core::Span::dummy(),
        });
    }

    let block = match &args[0] {
        Value::Block(block) => block,
        _ => {
            return Err(EvalError::TypeError {
                expected: "Block".to_string(),
                found: format!("{:?}", args[0]),
                span: relanote_core::Span::dummy(),
            })
        }
    };

    let slots: Vec<SlotValue> = block.slots.iter().map(halve_slot_duration).collect();

    Ok(Value::Block(BlockValue {
        slots,
        beats: block.beats / 2.0,
    }))
}

fn halve_slot_duration(slot: &SlotValue) -> SlotValue {
    match slot {
        SlotValue::Note {
            interval,
            articulations,
            duration_beats,
        } => SlotValue::Note {
            interval: interval.clone(),
            articulations: articulations.clone(),
            duration_beats: duration_beats.map(|d| d / 2.0),
        },
        SlotValue::Rest { duration_beats } => SlotValue::Rest {
            duration_beats: duration_beats.map(|d| d / 2.0),
        },
        SlotValue::Chord {
            intervals,
            articulations,
            duration_beats,
        } => SlotValue::Chord {
            intervals: intervals.clone(),
            articulations: articulations.clone(),
            duration_beats: duration_beats.map(|d| d / 2.0),
        },
        SlotValue::Tuplet {
            slots,
            target_beats,
        } => SlotValue::Tuplet {
            slots: slots.iter().map(halve_slot_duration).collect(),
            target_beats: *target_beats,
        },
    }
}

/// Generate a metronome click track
/// Usage: metronome(bars, beats_per_bar)
pub fn builtin_metronome(args: Vec<Value>) -> Result<Value, EvalError> {
    if args.len() != 2 {
        return Err(EvalError::Custom {
            message: "metronome expects 2 arguments (bars, beats_per_bar)".to_string(),
            span: relanote_core::Span::dummy(),
        });
    }

    let bars = match &args[0] {
        Value::Int(n) => *n as usize,
        _ => {
            return Err(EvalError::TypeError {
                expected: "Int".to_string(),
                found: format!("{:?}", args[0]),
                span: relanote_core::Span::dummy(),
            })
        }
    };

    let beats_per_bar = match &args[1] {
        Value::Int(n) => *n as usize,
        _ => {
            return Err(EvalError::TypeError {
                expected: "Int".to_string(),
                found: format!("{:?}", args[1]),
                span: relanote_core::Span::dummy(),
            })
        }
    };

    let mut slots = Vec::new();
    let total_beats = bars * beats_per_bar;

    let downbeat = SlotValue::Note {
        interval: IntervalValue { cents: 3600.0 }, // C7
        articulations: vec![],
        duration_beats: None,
    };
    let click = SlotValue::Note {
        interval: IntervalValue { cents: 3100.0 }, // G6
        articulations: vec![],
        duration_beats: None,
    };
    let rest = SlotValue::Rest {
        duration_beats: None,
    };

    for _bar in 0..bars {
        for beat in 0..beats_per_bar {
            if beat == 0 {
                slots.push(downbeat.clone());
            } else {
                slots.push(click.clone());
            }
            for _ in 0..7 {
                slots.push(rest.clone());
            }
        }
    }

    Ok(Value::Part(PartValue {
        instrument: "Metronome".to_string(),
        blocks: vec![BlockValue {
            slots,
            beats: total_beats as f64,
        }],
        envelope: None,
        reverb_level: None,
        volume_level: None,
        delay: None,
        phaser: None,
        distortion: None,
        synth: None,
    }))
}
