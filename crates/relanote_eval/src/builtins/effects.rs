//! Audio effects builtins

use crate::error::EvalError;
use crate::value::{DelayParams, DistortionParams, DistortionType, PartValue, PhaserParams, Value};

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
                delay: None,
                phaser: None,
                distortion: None,
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
                delay: None,
                phaser: None,
                distortion: None,
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
                delay: None,
                phaser: None,
                distortion: None,
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
                delay: None,
                phaser: None,
                distortion: None,
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
        delay: part.delay,
        phaser: part.phaser,
        distortion: part.distortion,
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
            delay: None,
            phaser: None,
            distortion: None,
            synth: None,
        })),
        Value::Part(part) => Ok(Value::Part(PartValue {
            instrument: part.instrument.clone(),
            blocks: part.blocks.clone(),
            envelope: part.envelope.clone(),
            reverb_level: Some(0.7),
            volume_level: part.volume_level,
            delay: part.delay.clone(),
            phaser: part.phaser.clone(),
            distortion: part.distortion.clone(),
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
            delay: None,
            phaser: None,
            distortion: None,
            synth: None,
        })),
        Value::Part(part) => Ok(Value::Part(PartValue {
            instrument: part.instrument.clone(),
            blocks: part.blocks.clone(),
            envelope: part.envelope.clone(),
            reverb_level: Some(0.4),
            volume_level: part.volume_level,
            delay: part.delay.clone(),
            phaser: part.phaser.clone(),
            distortion: part.distortion.clone(),
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
            delay: None,
            phaser: None,
            distortion: None,
            synth: None,
        })),
        Value::Part(part) => Ok(Value::Part(PartValue {
            instrument: part.instrument.clone(),
            blocks: part.blocks.clone(),
            envelope: part.envelope.clone(),
            reverb_level: Some(0.5),
            volume_level: part.volume_level,
            delay: part.delay.clone(),
            phaser: part.phaser.clone(),
            distortion: part.distortion.clone(),
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
            delay: None,
            phaser: None,
            distortion: None,
            synth: None,
        })),
        Value::Part(part) => Ok(Value::Part(PartValue {
            instrument: part.instrument.clone(),
            blocks: part.blocks.clone(),
            envelope: part.envelope.clone(),
            reverb_level: Some(0.0),
            volume_level: part.volume_level,
            delay: part.delay.clone(),
            phaser: part.phaser.clone(),
            distortion: part.distortion.clone(),
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
                delay: None,
                phaser: None,
                distortion: None,
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
                delay: None,
                phaser: None,
                distortion: None,
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
                delay: None,
                phaser: None,
                distortion: None,
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
                delay: None,
                phaser: None,
                distortion: None,
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
        delay: part_or_block.delay,
        phaser: part_or_block.phaser,
        distortion: part_or_block.distortion,
        synth: part_or_block.synth,
    }))
}

// ============================================================================
// New Effects: Delay, Phaser, Distortion
// ============================================================================

/// Apply delay effect to a block or part
/// Usage: delay(time_ms, feedback, mix, block) or block |> delay(time_ms, feedback, mix)
pub fn builtin_delay(args: Vec<Value>) -> Result<Value, EvalError> {
    if args.len() != 4 {
        return Err(EvalError::Custom {
            message: "delay expects 4 arguments (time_ms, feedback, mix, block/part)".to_string(),
            span: relanote_core::Span::dummy(),
        });
    }

    // Extract parameters - try to find block/part and 3 numeric values
    let (target, time_ms, feedback, mix) = extract_delay_args(&args)?;

    let params = DelayParams::new(time_ms, feedback, mix);

    match target {
        Value::Block(block) => Ok(Value::Part(PartValue {
            instrument: "Delay".to_string(),
            blocks: vec![block],
            envelope: None,
            reverb_level: None,
            volume_level: None,
            delay: Some(params),
            phaser: None,
            distortion: None,
            synth: None,
        })),
        Value::Part(part) => Ok(Value::Part(PartValue {
            delay: Some(params),
            ..part
        })),
        _ => Err(EvalError::TypeError {
            expected: "Block or Part".to_string(),
            found: format!("{:?}", target),
            span: relanote_core::Span::dummy(),
        }),
    }
}

fn extract_delay_args(args: &[Value]) -> Result<(Value, f64, f64, f64), EvalError> {
    let mut nums: Vec<f64> = Vec::new();
    let mut target: Option<Value> = None;

    for arg in args {
        match arg {
            Value::Float(f) => nums.push(*f),
            Value::Int(i) => nums.push(*i as f64),
            Value::Block(_) | Value::Part(_) => {
                if target.is_some() {
                    return Err(EvalError::TypeError {
                        expected: "only one Block or Part".to_string(),
                        found: "multiple".to_string(),
                        span: relanote_core::Span::dummy(),
                    });
                }
                target = Some(arg.clone());
            }
            _ => {}
        }
    }

    if nums.len() != 3 {
        return Err(EvalError::Custom {
            message: "delay expects 3 numeric arguments (time_ms, feedback, mix)".to_string(),
            span: relanote_core::Span::dummy(),
        });
    }

    let target = target.ok_or_else(|| EvalError::TypeError {
        expected: "Block or Part".to_string(),
        found: "none".to_string(),
        span: relanote_core::Span::dummy(),
    })?;

    Ok((target, nums[0], nums[1], nums[2]))
}

/// Apply phaser effect to a block or part
/// Usage: phaser(rate, depth, mix, block) or block |> phaser(rate, depth, mix)
pub fn builtin_phaser(args: Vec<Value>) -> Result<Value, EvalError> {
    if args.len() != 4 {
        return Err(EvalError::Custom {
            message: "phaser expects 4 arguments (rate, depth, mix, block/part)".to_string(),
            span: relanote_core::Span::dummy(),
        });
    }

    let (target, rate, depth, mix) = extract_phaser_args(&args)?;

    let params = PhaserParams::new(rate, depth, mix);

    match target {
        Value::Block(block) => Ok(Value::Part(PartValue {
            instrument: "Phaser".to_string(),
            blocks: vec![block],
            envelope: None,
            reverb_level: None,
            volume_level: None,
            delay: None,
            phaser: Some(params),
            distortion: None,
            synth: None,
        })),
        Value::Part(part) => Ok(Value::Part(PartValue {
            phaser: Some(params),
            ..part
        })),
        _ => Err(EvalError::TypeError {
            expected: "Block or Part".to_string(),
            found: format!("{:?}", target),
            span: relanote_core::Span::dummy(),
        }),
    }
}

fn extract_phaser_args(args: &[Value]) -> Result<(Value, f64, f64, f64), EvalError> {
    let mut nums: Vec<f64> = Vec::new();
    let mut target: Option<Value> = None;

    for arg in args {
        match arg {
            Value::Float(f) => nums.push(*f),
            Value::Int(i) => nums.push(*i as f64),
            Value::Block(_) | Value::Part(_) => {
                if target.is_some() {
                    return Err(EvalError::TypeError {
                        expected: "only one Block or Part".to_string(),
                        found: "multiple".to_string(),
                        span: relanote_core::Span::dummy(),
                    });
                }
                target = Some(arg.clone());
            }
            _ => {}
        }
    }

    if nums.len() != 3 {
        return Err(EvalError::Custom {
            message: "phaser expects 3 numeric arguments (rate, depth, mix)".to_string(),
            span: relanote_core::Span::dummy(),
        });
    }

    let target = target.ok_or_else(|| EvalError::TypeError {
        expected: "Block or Part".to_string(),
        found: "none".to_string(),
        span: relanote_core::Span::dummy(),
    })?;

    Ok((target, nums[0], nums[1], nums[2]))
}

/// Apply distortion effect to a block or part
/// Usage: distortion(amount, type, mix, block) or block |> distortion(amount, type, mix)
pub fn builtin_distortion(args: Vec<Value>) -> Result<Value, EvalError> {
    if args.len() != 4 {
        return Err(EvalError::Custom {
            message: "distortion expects 4 arguments (amount, type, mix, block/part)".to_string(),
            span: relanote_core::Span::dummy(),
        });
    }

    let (target, amount, dist_type, mix) = extract_distortion_args(&args)?;

    let params = DistortionParams::new(amount, dist_type, mix);

    match target {
        Value::Block(block) => Ok(Value::Part(PartValue {
            instrument: "Distortion".to_string(),
            blocks: vec![block],
            envelope: None,
            reverb_level: None,
            volume_level: None,
            delay: None,
            phaser: None,
            distortion: Some(params),
            synth: None,
        })),
        Value::Part(part) => Ok(Value::Part(PartValue {
            distortion: Some(params),
            ..part
        })),
        _ => Err(EvalError::TypeError {
            expected: "Block or Part".to_string(),
            found: format!("{:?}", target),
            span: relanote_core::Span::dummy(),
        }),
    }
}

fn extract_distortion_args(args: &[Value]) -> Result<(Value, f64, DistortionType, f64), EvalError> {
    let mut nums: Vec<f64> = Vec::new();
    let mut target: Option<Value> = None;
    let mut dist_type: Option<DistortionType> = None;

    for arg in args {
        match arg {
            Value::Float(f) => nums.push(*f),
            Value::Int(i) => nums.push(*i as f64),
            Value::Block(_) | Value::Part(_) => {
                if target.is_some() {
                    return Err(EvalError::TypeError {
                        expected: "only one Block or Part".to_string(),
                        found: "multiple".to_string(),
                        span: relanote_core::Span::dummy(),
                    });
                }
                target = Some(arg.clone());
            }
            Value::DistortionType(dt) => {
                dist_type = Some(*dt);
            }
            _ => {}
        }
    }

    if nums.len() != 2 {
        return Err(EvalError::Custom {
            message: "distortion expects 2 numeric arguments (amount, mix)".to_string(),
            span: relanote_core::Span::dummy(),
        });
    }

    let target = target.ok_or_else(|| EvalError::TypeError {
        expected: "Block or Part".to_string(),
        found: "none".to_string(),
        span: relanote_core::Span::dummy(),
    })?;

    let dist_type = dist_type.unwrap_or(DistortionType::Soft);

    Ok((target, nums[0], dist_type, nums[1]))
}

// ============================================================================
// Distortion Type Constructors
// ============================================================================

/// Soft clipping distortion type (tube-like warmth)
pub fn builtin_soft_clip(_args: Vec<Value>) -> Result<Value, EvalError> {
    Ok(Value::DistortionType(DistortionType::Soft))
}

/// Hard clipping distortion type (aggressive)
pub fn builtin_hard_clip(_args: Vec<Value>) -> Result<Value, EvalError> {
    Ok(Value::DistortionType(DistortionType::Hard))
}

/// Fuzz distortion type (asymmetric clipping)
pub fn builtin_fuzz(_args: Vec<Value>) -> Result<Value, EvalError> {
    Ok(Value::DistortionType(DistortionType::Fuzz))
}

/// Bit crush distortion type (lo-fi bit reduction)
pub fn builtin_bitcrush(_args: Vec<Value>) -> Result<Value, EvalError> {
    Ok(Value::DistortionType(DistortionType::BitCrush))
}
