//! Audio effects builtins

use crate::error::EvalError;
use crate::value::{PartValue, Value};

/// Apply reverb to a block or part with specified level
/// Usage: reverb(level, block) or block |> reverb(level)
pub fn builtin_reverb(args: Vec<Value>) -> Result<Value, EvalError> {
    if args.len() != 2 {
        return Err(EvalError::Custom {
            message: "reverb expects 2 arguments (level, block/part)".to_string(),
            span: relanote_core::Span::dummy(),
        });
    }

    // Handle Part input to allow chaining (e.g., |> voice ... |> reverb ...)
    let (part, level) = match (&args[0], &args[1]) {
        (Value::Part(part), Value::Float(level)) => (part.clone(), *level),
        (Value::Float(level), Value::Part(part)) => (part.clone(), *level),
        (Value::Part(part), Value::Int(level)) => (part.clone(), *level as f64 / 100.0),
        (Value::Int(level), Value::Part(part)) => (part.clone(), *level as f64 / 100.0),
        // Also handle Block input directly
        (Value::Block(block), Value::Float(level)) => {
            let level = level.clamp(0.0, 1.0);
            return Ok(Value::Part(PartValue {
                instrument: "Reverb".to_string(),
                blocks: vec![block.clone()],
                envelope: None,
                reverb_level: Some(level),
                volume_level: None,
                synth: None,
            }));
        }
        (Value::Float(level), Value::Block(block)) => {
            let level = level.clamp(0.0, 1.0);
            return Ok(Value::Part(PartValue {
                instrument: "Reverb".to_string(),
                blocks: vec![block.clone()],
                envelope: None,
                reverb_level: Some(level),
                volume_level: None,
                synth: None,
            }));
        }
        (Value::Block(block), Value::Int(level)) => {
            let level = (*level as f64 / 100.0).clamp(0.0, 1.0);
            return Ok(Value::Part(PartValue {
                instrument: "Reverb".to_string(),
                blocks: vec![block.clone()],
                envelope: None,
                reverb_level: Some(level),
                volume_level: None,
                synth: None,
            }));
        }
        (Value::Int(level), Value::Block(block)) => {
            let level = (*level as f64 / 100.0).clamp(0.0, 1.0);
            return Ok(Value::Part(PartValue {
                instrument: "Reverb".to_string(),
                blocks: vec![block.clone()],
                envelope: None,
                reverb_level: Some(level),
                volume_level: None,
                synth: None,
            }));
        }
        _ => {
            return Err(EvalError::TypeError {
                expected: "Block/Part and Float (or Int)".to_string(),
                found: format!("{:?}, {:?}", args[0], args[1]),
                span: relanote_core::Span::dummy(),
            })
        }
    };

    let level = level.clamp(0.0, 1.0);

    Ok(Value::Part(PartValue {
        instrument: part.instrument,
        blocks: part.blocks,
        envelope: part.envelope,
        reverb_level: Some(level),
        volume_level: part.volume_level,
        synth: part.synth,
    }))
}

/// Hall reverb preset (high reverb level for large spaces)
/// Usage: block |> hall_reverb
pub fn builtin_hall_reverb(args: Vec<Value>) -> Result<Value, EvalError> {
    if args.len() != 1 {
        return Err(EvalError::Custom {
            message: "hall_reverb expects 1 argument".to_string(),
            span: relanote_core::Span::dummy(),
        });
    }

    match &args[0] {
        Value::Block(block) => Ok(Value::Part(PartValue {
            instrument: "Hall".to_string(),
            blocks: vec![block.clone()],
            envelope: None,
            reverb_level: Some(0.7),
            volume_level: None,
            synth: None,
        })),
        Value::Part(part) => Ok(Value::Part(PartValue {
            instrument: part.instrument.clone(),
            blocks: part.blocks.clone(),
            envelope: part.envelope.clone(),
            reverb_level: Some(0.7),
            volume_level: part.volume_level,
            synth: part.synth.clone(),
        })),
        _ => Err(EvalError::TypeError {
            expected: "Block or Part".to_string(),
            found: format!("{:?}", args[0]),
            span: relanote_core::Span::dummy(),
        }),
    }
}

/// Room reverb preset (medium reverb level for smaller spaces)
/// Usage: block |> room_reverb
pub fn builtin_room_reverb(args: Vec<Value>) -> Result<Value, EvalError> {
    if args.len() != 1 {
        return Err(EvalError::Custom {
            message: "room_reverb expects 1 argument".to_string(),
            span: relanote_core::Span::dummy(),
        });
    }

    match &args[0] {
        Value::Block(block) => Ok(Value::Part(PartValue {
            instrument: "Room".to_string(),
            blocks: vec![block.clone()],
            envelope: None,
            reverb_level: Some(0.4),
            volume_level: None,
            synth: None,
        })),
        Value::Part(part) => Ok(Value::Part(PartValue {
            instrument: part.instrument.clone(),
            blocks: part.blocks.clone(),
            envelope: part.envelope.clone(),
            reverb_level: Some(0.4),
            volume_level: part.volume_level,
            synth: part.synth.clone(),
        })),
        _ => Err(EvalError::TypeError {
            expected: "Block or Part".to_string(),
            found: format!("{:?}", args[0]),
            span: relanote_core::Span::dummy(),
        }),
    }
}

/// Plate reverb preset (crisp, bright reverb)
/// Usage: block |> plate_reverb
pub fn builtin_plate_reverb(args: Vec<Value>) -> Result<Value, EvalError> {
    if args.len() != 1 {
        return Err(EvalError::Custom {
            message: "plate_reverb expects 1 argument".to_string(),
            span: relanote_core::Span::dummy(),
        });
    }

    match &args[0] {
        Value::Block(block) => Ok(Value::Part(PartValue {
            instrument: "Plate".to_string(),
            blocks: vec![block.clone()],
            envelope: None,
            reverb_level: Some(0.5),
            volume_level: None,
            synth: None,
        })),
        Value::Part(part) => Ok(Value::Part(PartValue {
            instrument: part.instrument.clone(),
            blocks: part.blocks.clone(),
            envelope: part.envelope.clone(),
            reverb_level: Some(0.5),
            volume_level: part.volume_level,
            synth: part.synth.clone(),
        })),
        _ => Err(EvalError::TypeError {
            expected: "Block or Part".to_string(),
            found: format!("{:?}", args[0]),
            span: relanote_core::Span::dummy(),
        }),
    }
}

/// Dry signal (no reverb)
/// Usage: block |> dry
pub fn builtin_dry(args: Vec<Value>) -> Result<Value, EvalError> {
    if args.len() != 1 {
        return Err(EvalError::Custom {
            message: "dry expects 1 argument".to_string(),
            span: relanote_core::Span::dummy(),
        });
    }

    match &args[0] {
        Value::Block(block) => Ok(Value::Part(PartValue {
            instrument: "Dry".to_string(),
            blocks: vec![block.clone()],
            envelope: None,
            reverb_level: Some(0.0),
            volume_level: None,
            synth: None,
        })),
        Value::Part(part) => Ok(Value::Part(PartValue {
            instrument: part.instrument.clone(),
            blocks: part.blocks.clone(),
            envelope: part.envelope.clone(),
            reverb_level: Some(0.0),
            volume_level: part.volume_level,
            synth: part.synth.clone(),
        })),
        _ => Err(EvalError::TypeError {
            expected: "Block or Part".to_string(),
            found: format!("{:?}", args[0]),
            span: relanote_core::Span::dummy(),
        }),
    }
}

/// Set volume level for a block
/// Usage: block |> volume(level) where level is 0.0-1.0 or 0-100
pub fn builtin_volume(args: Vec<Value>) -> Result<Value, EvalError> {
    if args.len() != 2 {
        return Err(EvalError::Custom {
            message: "volume expects 2 arguments (level, block)".to_string(),
            span: relanote_core::Span::dummy(),
        });
    }

    // Support both argument orders: (level, block) or (block, level)
    let (part_or_block, level) = match (&args[0], &args[1]) {
        (Value::Block(block), Value::Float(level)) => {
            let part = PartValue {
                instrument: "Volume".to_string(),
                blocks: vec![block.clone()],
                envelope: None,
                reverb_level: None,
                volume_level: Some(*level),
                synth: None,
            };
            return Ok(Value::Part(part));
        }
        (Value::Float(level), Value::Block(block)) => {
            let part = PartValue {
                instrument: "Volume".to_string(),
                blocks: vec![block.clone()],
                envelope: None,
                reverb_level: None,
                volume_level: Some(*level),
                synth: None,
            };
            return Ok(Value::Part(part));
        }
        (Value::Block(block), Value::Int(level)) => {
            let part = PartValue {
                instrument: "Volume".to_string(),
                blocks: vec![block.clone()],
                envelope: None,
                reverb_level: None,
                volume_level: Some(*level as f64 / 100.0),
                synth: None,
            };
            return Ok(Value::Part(part));
        }
        (Value::Int(level), Value::Block(block)) => {
            let part = PartValue {
                instrument: "Volume".to_string(),
                blocks: vec![block.clone()],
                envelope: None,
                reverb_level: None,
                volume_level: Some(*level as f64 / 100.0),
                synth: None,
            };
            return Ok(Value::Part(part));
        }
        // Handle Part input to allow chaining
        (Value::Part(part), Value::Float(level)) => (part.clone(), *level),
        (Value::Float(level), Value::Part(part)) => (part.clone(), *level),
        (Value::Part(part), Value::Int(level)) => (part.clone(), *level as f64 / 100.0),
        (Value::Int(level), Value::Part(part)) => (part.clone(), *level as f64 / 100.0),
        _ => {
            return Err(EvalError::TypeError {
                expected: "Block/Part and Float (or Int)".to_string(),
                found: format!("{:?}, {:?}", args[0], args[1]),
                span: relanote_core::Span::dummy(),
            })
        }
    };

    let level = level.clamp(0.0, 1.0);

    Ok(Value::Part(PartValue {
        instrument: part_or_block.instrument,
        blocks: part_or_block.blocks,
        envelope: part_or_block.envelope,
        reverb_level: part_or_block.reverb_level,
        volume_level: Some(level),
        synth: part_or_block.synth,
    }))
}
