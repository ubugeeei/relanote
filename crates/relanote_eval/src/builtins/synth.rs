//! Synth modifier builtins

use crate::error::EvalError;
use crate::value::{
    ADSREnvelope, FilterType, FilterValue, OscillatorValue, PartValue, SynthValue, Value, Waveform,
};

/// Create an ADSR envelope value
/// Usage: env(attack, decay, sustain, release)
pub fn builtin_env(args: Vec<Value>) -> Result<Value, EvalError> {
    if args.len() != 4 {
        return Err(EvalError::Custom {
            message: "env expects 4 arguments (attack, decay, sustain, release)".to_string(),
            span: relanote_core::Span::dummy(),
        });
    }

    let extract_float = |v: &Value| -> Option<f64> {
        match v {
            Value::Float(f) => Some(*f),
            Value::Int(i) => Some(*i as f64),
            _ => None,
        }
    };

    let values: Vec<f64> = args.iter().filter_map(extract_float).collect();

    if values.len() != 4 {
        return Err(EvalError::Custom {
            message: "env requires 4 numeric values (attack, decay, sustain, release)".to_string(),
            span: relanote_core::Span::dummy(),
        });
    }

    Ok(Value::ADSR(ADSREnvelope::new(
        values[0], values[1], values[2], values[3],
    )))
}

/// Apply a synth to a block
/// Usage: block |> voice(synth) or voice(synth, block)
pub fn builtin_voice(args: Vec<Value>) -> Result<Value, EvalError> {
    if args.len() != 2 {
        return Err(EvalError::Custom {
            message: "voice expects 2 arguments (synth, block)".to_string(),
            span: relanote_core::Span::dummy(),
        });
    }

    // Support both argument orders
    let (block, synth) = match (&args[0], &args[1]) {
        (Value::Block(block), Value::Synth(synth)) => (block.clone(), synth.clone()),
        (Value::Synth(synth), Value::Block(block)) => (block.clone(), synth.clone()),
        // Handle Part input to allow chaining
        (Value::Part(part), Value::Synth(synth)) => {
            return Ok(Value::Part(PartValue {
                instrument: synth.name.clone(),
                blocks: part.blocks.clone(),
                envelope: part.envelope.clone(),
                reverb_level: part.reverb_level,
                volume_level: part.volume_level,
                synth: Some(synth.clone()),
            }));
        }
        (Value::Synth(synth), Value::Part(part)) => {
            return Ok(Value::Part(PartValue {
                instrument: synth.name.clone(),
                blocks: part.blocks.clone(),
                envelope: part.envelope.clone(),
                reverb_level: part.reverb_level,
                volume_level: part.volume_level,
                synth: Some(synth.clone()),
            }));
        }
        _ => {
            return Err(EvalError::TypeError {
                expected: "Block/Part and Synth".to_string(),
                found: format!("{:?}, {:?}", args[0], args[1]),
                span: relanote_core::Span::dummy(),
            })
        }
    };

    Ok(Value::Part(PartValue {
        instrument: synth.name.clone(),
        blocks: vec![block],
        envelope: None,
        reverb_level: None,
        volume_level: None,
        synth: Some(synth),
    }))
}

/// Set filter cutoff frequency on a part
/// Usage: part |> cutoff(freq)
pub fn builtin_cutoff(args: Vec<Value>) -> Result<Value, EvalError> {
    if args.len() != 2 {
        return Err(EvalError::Custom {
            message: "cutoff expects 2 arguments (freq, part)".to_string(),
            span: relanote_core::Span::dummy(),
        });
    }

    let (part, freq) = match (&args[0], &args[1]) {
        (Value::Part(part), Value::Float(freq)) => (part.clone(), *freq),
        (Value::Float(freq), Value::Part(part)) => (part.clone(), *freq),
        (Value::Part(part), Value::Int(freq)) => (part.clone(), *freq as f64),
        (Value::Int(freq), Value::Part(part)) => (part.clone(), *freq as f64),
        _ => {
            return Err(EvalError::TypeError {
                expected: "Part and Float/Int".to_string(),
                found: format!("{:?}, {:?}", args[0], args[1]),
                span: relanote_core::Span::dummy(),
            })
        }
    };

    let mut synth = part.synth.unwrap_or_else(|| SynthValue::new("Custom"));
    if let Some(ref mut filter) = synth.filter {
        filter.cutoff = freq.max(20.0);
    } else {
        synth.filter = Some(FilterValue::lowpass(freq, 0.5));
    }

    Ok(Value::Part(PartValue {
        instrument: part.instrument,
        blocks: part.blocks,
        envelope: part.envelope,
        reverb_level: part.reverb_level,
        volume_level: part.volume_level,
        synth: Some(synth),
    }))
}

/// Set filter resonance on a part
/// Usage: part |> resonance(q)
pub fn builtin_resonance(args: Vec<Value>) -> Result<Value, EvalError> {
    if args.len() != 2 {
        return Err(EvalError::Custom {
            message: "resonance expects 2 arguments (q, part)".to_string(),
            span: relanote_core::Span::dummy(),
        });
    }

    let (part, reso) = match (&args[0], &args[1]) {
        (Value::Part(part), Value::Float(reso)) => (part.clone(), *reso),
        (Value::Float(reso), Value::Part(part)) => (part.clone(), *reso),
        _ => {
            return Err(EvalError::TypeError {
                expected: "Part and Float".to_string(),
                found: format!("{:?}, {:?}", args[0], args[1]),
                span: relanote_core::Span::dummy(),
            })
        }
    };

    let reso = reso.clamp(0.0, 1.0);
    let mut synth = part.synth.unwrap_or_else(|| SynthValue::new("Custom"));
    if let Some(ref mut filter) = synth.filter {
        filter.resonance = reso;
    } else {
        synth.filter = Some(FilterValue::lowpass(1000.0, reso));
    }

    Ok(Value::Part(PartValue {
        instrument: part.instrument,
        blocks: part.blocks,
        envelope: part.envelope,
        reverb_level: part.reverb_level,
        volume_level: part.volume_level,
        synth: Some(synth),
    }))
}

/// Set detune on a part
/// Usage: part |> detune(cents)
pub fn builtin_detune(args: Vec<Value>) -> Result<Value, EvalError> {
    if args.len() != 2 {
        return Err(EvalError::Custom {
            message: "detune expects 2 arguments (cents, part)".to_string(),
            span: relanote_core::Span::dummy(),
        });
    }

    let (part, cents) = match (&args[0], &args[1]) {
        (Value::Part(part), Value::Float(cents)) => (part.clone(), *cents),
        (Value::Float(cents), Value::Part(part)) => (part.clone(), *cents),
        (Value::Part(part), Value::Int(cents)) => (part.clone(), *cents as f64),
        (Value::Int(cents), Value::Part(part)) => (part.clone(), *cents as f64),
        _ => {
            return Err(EvalError::TypeError {
                expected: "Part and Float/Int".to_string(),
                found: format!("{:?}, {:?}", args[0], args[1]),
                span: relanote_core::Span::dummy(),
            })
        }
    };

    let mut synth = part.synth.unwrap_or_else(|| SynthValue::new("Custom"));
    synth.detune_cents = cents;

    Ok(Value::Part(PartValue {
        instrument: part.instrument,
        blocks: part.blocks,
        envelope: part.envelope,
        reverb_level: part.reverb_level,
        volume_level: part.volume_level,
        synth: Some(synth),
    }))
}

/// Set ADSR envelope on a part
/// Usage: part |> adsr(a, d, s, r)
pub fn builtin_adsr(args: Vec<Value>) -> Result<Value, EvalError> {
    if args.len() != 5 {
        return Err(EvalError::Custom {
            message: "adsr expects 5 arguments (attack, decay, sustain, release, part)".to_string(),
            span: relanote_core::Span::dummy(),
        });
    }

    let extract_float = |v: &Value| -> Option<f64> {
        match v {
            Value::Float(f) => Some(*f),
            Value::Int(i) => Some(*i as f64),
            _ => None,
        }
    };

    // Find the part and extract ADSR values
    let mut part_idx = None;
    for (i, arg) in args.iter().enumerate() {
        if matches!(arg, Value::Part(_)) {
            part_idx = Some(i);
            break;
        }
    }

    let part_idx = part_idx.ok_or_else(|| EvalError::TypeError {
        expected: "Part".to_string(),
        found: "no Part argument".to_string(),
        span: relanote_core::Span::dummy(),
    })?;

    let part = match &args[part_idx] {
        Value::Part(p) => p.clone(),
        _ => unreachable!(),
    };

    // Get the other 4 values
    let values: Vec<f64> = args
        .iter()
        .enumerate()
        .filter(|(i, _)| *i != part_idx)
        .filter_map(|(_, v)| extract_float(v))
        .collect();

    if values.len() != 4 {
        return Err(EvalError::Custom {
            message: "adsr requires 4 numeric values (attack, decay, sustain, release)".to_string(),
            span: relanote_core::Span::dummy(),
        });
    }

    let mut synth = part.synth.unwrap_or_else(|| SynthValue::new("Custom"));
    synth.envelope = ADSREnvelope::new(values[0], values[1], values[2], values[3]);

    Ok(Value::Part(PartValue {
        instrument: part.instrument,
        blocks: part.blocks,
        envelope: part.envelope,
        reverb_level: part.reverb_level,
        volume_level: part.volume_level,
        synth: Some(synth),
    }))
}

// ============================================
// Filter constructors
// ============================================

fn extract_number(v: &Value) -> Option<f64> {
    match v {
        Value::Float(f) => Some(*f),
        Value::Int(i) => Some(*i as f64),
        _ => None,
    }
}

/// Create a LowPass filter value
/// Usage: LowPass cutoff resonance
pub fn builtin_lowpass(args: Vec<Value>) -> Result<Value, EvalError> {
    if args.len() != 2 {
        return Err(EvalError::Custom {
            message: "LowPass expects 2 arguments (cutoff, resonance)".to_string(),
            span: relanote_core::Span::dummy(),
        });
    }

    let cutoff = extract_number(&args[0]).ok_or_else(|| EvalError::TypeError {
        expected: "number".to_string(),
        found: format!("{:?}", args[0]),
        span: relanote_core::Span::dummy(),
    })?;

    let resonance = extract_number(&args[1]).ok_or_else(|| EvalError::TypeError {
        expected: "number".to_string(),
        found: format!("{:?}", args[1]),
        span: relanote_core::Span::dummy(),
    })?;

    Ok(Value::Filter(FilterValue {
        filter_type: FilterType::LowPass,
        cutoff,
        resonance,
    }))
}

/// Create a HighPass filter value
/// Usage: HighPass cutoff resonance
pub fn builtin_highpass(args: Vec<Value>) -> Result<Value, EvalError> {
    if args.len() != 2 {
        return Err(EvalError::Custom {
            message: "HighPass expects 2 arguments (cutoff, resonance)".to_string(),
            span: relanote_core::Span::dummy(),
        });
    }

    let cutoff = extract_number(&args[0]).ok_or_else(|| EvalError::TypeError {
        expected: "number".to_string(),
        found: format!("{:?}", args[0]),
        span: relanote_core::Span::dummy(),
    })?;

    let resonance = extract_number(&args[1]).ok_or_else(|| EvalError::TypeError {
        expected: "number".to_string(),
        found: format!("{:?}", args[1]),
        span: relanote_core::Span::dummy(),
    })?;

    Ok(Value::Filter(FilterValue {
        filter_type: FilterType::HighPass,
        cutoff,
        resonance,
    }))
}

/// Create a BandPass filter value
/// Usage: BandPass cutoff resonance
pub fn builtin_bandpass(args: Vec<Value>) -> Result<Value, EvalError> {
    if args.len() != 2 {
        return Err(EvalError::Custom {
            message: "BandPass expects 2 arguments (cutoff, resonance)".to_string(),
            span: relanote_core::Span::dummy(),
        });
    }

    let cutoff = extract_number(&args[0]).ok_or_else(|| EvalError::TypeError {
        expected: "number".to_string(),
        found: format!("{:?}", args[0]),
        span: relanote_core::Span::dummy(),
    })?;

    let resonance = extract_number(&args[1]).ok_or_else(|| EvalError::TypeError {
        expected: "number".to_string(),
        found: format!("{:?}", args[1]),
        span: relanote_core::Span::dummy(),
    })?;

    Ok(Value::Filter(FilterValue {
        filter_type: FilterType::BandPass,
        cutoff,
        resonance,
    }))
}

// ============================================
// Oscillator constructors
// ============================================

/// Create a Pulse oscillator value with duty cycle
/// Usage: Pulse duty
pub fn builtin_pulse(args: Vec<Value>) -> Result<Value, EvalError> {
    if args.len() != 1 {
        return Err(EvalError::Custom {
            message: "Pulse expects 1 argument (duty cycle 0.0-1.0)".to_string(),
            span: relanote_core::Span::dummy(),
        });
    }

    let duty = extract_number(&args[0]).ok_or_else(|| EvalError::TypeError {
        expected: "number".to_string(),
        found: format!("{:?}", args[0]),
        span: relanote_core::Span::dummy(),
    })?;

    Ok(Value::Oscillator(OscillatorValue {
        waveform: Waveform::Pulse(duty.clamp(0.0, 1.0)),
        mix: 1.0,
        octave_offset: 0,
        detune_cents: 0.0,
    }))
}

/// Create a Square oscillator value (Pulse with 0.5 duty)
/// Usage: Square
pub fn builtin_square(_args: Vec<Value>) -> Result<Value, EvalError> {
    Ok(Value::Oscillator(OscillatorValue {
        waveform: Waveform::Square,
        mix: 1.0,
        octave_offset: 0,
        detune_cents: 0.0,
    }))
}

/// Create a Saw oscillator value
/// Usage: Saw
pub fn builtin_saw(_args: Vec<Value>) -> Result<Value, EvalError> {
    Ok(Value::Oscillator(OscillatorValue {
        waveform: Waveform::Saw,
        mix: 1.0,
        octave_offset: 0,
        detune_cents: 0.0,
    }))
}

/// Create a Triangle oscillator value
/// Usage: Triangle
pub fn builtin_triangle(_args: Vec<Value>) -> Result<Value, EvalError> {
    Ok(Value::Oscillator(OscillatorValue {
        waveform: Waveform::Triangle,
        mix: 1.0,
        octave_offset: 0,
        detune_cents: 0.0,
    }))
}

/// Create a Sine oscillator value
/// Usage: Sine
pub fn builtin_sine(_args: Vec<Value>) -> Result<Value, EvalError> {
    Ok(Value::Oscillator(OscillatorValue {
        waveform: Waveform::Sine,
        mix: 1.0,
        octave_offset: 0,
        detune_cents: 0.0,
    }))
}

/// Create a Noise oscillator value
/// Usage: Noise
pub fn builtin_noise(_args: Vec<Value>) -> Result<Value, EvalError> {
    Ok(Value::Oscillator(OscillatorValue {
        waveform: Waveform::Noise,
        mix: 1.0,
        octave_offset: 0,
        detune_cents: 0.0,
    }))
}

// ============================================
// Oscillator modifier functions
// ============================================

/// Set the mix level for an oscillator
/// Usage: Saw |> mix 0.5
pub fn builtin_osc_mix(args: Vec<Value>) -> Result<Value, EvalError> {
    if args.len() != 2 {
        return Err(EvalError::Custom {
            message: "mix expects 2 arguments (oscillator, level)".to_string(),
            span: relanote_core::Span::dummy(),
        });
    }

    let (osc, level) = match (&args[0], &args[1]) {
        (Value::Oscillator(osc), v) => {
            let level = extract_number(v).ok_or_else(|| EvalError::TypeError {
                expected: "number".to_string(),
                found: format!("{:?}", v),
                span: relanote_core::Span::dummy(),
            })?;
            (osc.clone(), level)
        }
        (v, Value::Oscillator(osc)) => {
            let level = extract_number(v).ok_or_else(|| EvalError::TypeError {
                expected: "number".to_string(),
                found: format!("{:?}", v),
                span: relanote_core::Span::dummy(),
            })?;
            (osc.clone(), level)
        }
        _ => {
            return Err(EvalError::TypeError {
                expected: "Oscillator and number".to_string(),
                found: format!("{:?}, {:?}", args[0], args[1]),
                span: relanote_core::Span::dummy(),
            })
        }
    };

    Ok(Value::Oscillator(OscillatorValue {
        mix: level.clamp(0.0, 1.0),
        ..osc
    }))
}

/// Set the octave offset for an oscillator
/// Usage: Saw |> octave 1  (or octave -1 for one octave down)
pub fn builtin_osc_octave(args: Vec<Value>) -> Result<Value, EvalError> {
    if args.len() != 2 {
        return Err(EvalError::Custom {
            message: "octave expects 2 arguments (oscillator, offset)".to_string(),
            span: relanote_core::Span::dummy(),
        });
    }

    let (osc, offset) = match (&args[0], &args[1]) {
        (Value::Oscillator(osc), Value::Int(offset)) => (osc.clone(), *offset as i8),
        (Value::Int(offset), Value::Oscillator(osc)) => (osc.clone(), *offset as i8),
        (Value::Oscillator(osc), Value::Float(offset)) => (osc.clone(), *offset as i8),
        (Value::Float(offset), Value::Oscillator(osc)) => (osc.clone(), *offset as i8),
        _ => {
            return Err(EvalError::TypeError {
                expected: "Oscillator and number".to_string(),
                found: format!("{:?}, {:?}", args[0], args[1]),
                span: relanote_core::Span::dummy(),
            })
        }
    };

    Ok(Value::Oscillator(OscillatorValue {
        octave_offset: offset.clamp(-4, 4),
        ..osc
    }))
}

/// Set the detune in cents for an oscillator
/// Usage: Saw |> osc_detune 5  (5 cents sharp)
pub fn builtin_osc_detune(args: Vec<Value>) -> Result<Value, EvalError> {
    if args.len() != 2 {
        return Err(EvalError::Custom {
            message: "osc_detune expects 2 arguments (oscillator, cents)".to_string(),
            span: relanote_core::Span::dummy(),
        });
    }

    let (osc, cents) = match (&args[0], &args[1]) {
        (Value::Oscillator(osc), v) => {
            let cents = extract_number(v).ok_or_else(|| EvalError::TypeError {
                expected: "number".to_string(),
                found: format!("{:?}", v),
                span: relanote_core::Span::dummy(),
            })?;
            (osc.clone(), cents)
        }
        (v, Value::Oscillator(osc)) => {
            let cents = extract_number(v).ok_or_else(|| EvalError::TypeError {
                expected: "number".to_string(),
                found: format!("{:?}", v),
                span: relanote_core::Span::dummy(),
            })?;
            (osc.clone(), cents)
        }
        _ => {
            return Err(EvalError::TypeError {
                expected: "Oscillator and number".to_string(),
                found: format!("{:?}, {:?}", args[0], args[1]),
                span: relanote_core::Span::dummy(),
            })
        }
    };

    Ok(Value::Oscillator(OscillatorValue {
        detune_cents: cents.clamp(-100.0, 100.0),
        ..osc
    }))
}
