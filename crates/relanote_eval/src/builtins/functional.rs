//! Functional programming builtins
//!
//! This module provides common FP utilities for working with arrays and lists.

use std::cell::RefCell;
use std::rc::Rc;

use crate::env::Env;
use crate::error::EvalError;
use crate::value::{Closure, Value};

/// Map a function over an array
/// Usage: map(fn, array) or array |> map(fn)
pub fn builtin_map(args: Vec<Value>) -> Result<Value, EvalError> {
    if args.len() != 2 {
        return Err(EvalError::Custom {
            message: "map expects 2 arguments (fn, array)".to_string(),
            span: relanote_core::Span::dummy(),
        });
    }

    let (arr, func) = match (&args[0], &args[1]) {
        (Value::Array(arr), Value::Closure(f)) => (arr.clone(), f.clone()),
        (Value::Closure(f), Value::Array(arr)) => (arr.clone(), f.clone()),
        (Value::Array(arr), Value::Builtin(f)) => {
            // Apply builtin to each element
            let results: Result<Vec<_>, _> = arr.iter().map(|v| f(vec![v.clone()])).collect();
            return Ok(Value::Array(results?));
        }
        (Value::Builtin(f), Value::Array(arr)) => {
            let results: Result<Vec<_>, _> = arr.iter().map(|v| f(vec![v.clone()])).collect();
            return Ok(Value::Array(results?));
        }
        _ => {
            return Err(EvalError::TypeError {
                expected: "Array and Function".to_string(),
                found: format!("{:?}, {:?}", args[0], args[1]),
                span: relanote_core::Span::dummy(),
            })
        }
    };

    let results: Result<Vec<_>, _> = arr
        .iter()
        .map(|v| apply_closure(&func, vec![v.clone()]))
        .collect();
    Ok(Value::Array(results?))
}

/// Filter an array by a predicate function
/// Usage: filter(fn, array) or array |> filter(fn)
pub fn builtin_filter(args: Vec<Value>) -> Result<Value, EvalError> {
    if args.len() != 2 {
        return Err(EvalError::Custom {
            message: "filter expects 2 arguments (fn, array)".to_string(),
            span: relanote_core::Span::dummy(),
        });
    }

    let (arr, func) = match (&args[0], &args[1]) {
        (Value::Array(arr), Value::Closure(f)) => (arr.clone(), f.clone()),
        (Value::Closure(f), Value::Array(arr)) => (arr.clone(), f.clone()),
        _ => {
            return Err(EvalError::TypeError {
                expected: "Array and Function".to_string(),
                found: format!("{:?}, {:?}", args[0], args[1]),
                span: relanote_core::Span::dummy(),
            })
        }
    };

    let mut results = Vec::new();
    for v in arr {
        let result = apply_closure(&func, vec![v.clone()])?;
        if let Value::Bool(true) = result {
            results.push(v);
        }
    }
    Ok(Value::Array(results))
}

/// Left fold: foldl fn init array
/// Accumulates from left to right: foldl f z [a,b,c] = f (f (f z a) b) c
pub fn builtin_foldl(args: Vec<Value>) -> Result<Value, EvalError> {
    if args.len() != 3 {
        return Err(EvalError::Custom {
            message: "foldl expects 3 arguments: foldl fn init array".to_string(),
            span: relanote_core::Span::dummy(),
        });
    }

    // Find the array and closure
    let mut arr = None;
    let mut func = None;
    let mut init = None;

    for arg in &args {
        match arg {
            Value::Array(a) if arr.is_none() => arr = Some(a.clone()),
            Value::Closure(f) if func.is_none() => func = Some(f.clone()),
            v if init.is_none() && !matches!(v, Value::Array(_) | Value::Closure(_)) => {
                init = Some(v.clone())
            }
            _ => {}
        }
    }

    let arr = arr.ok_or_else(|| EvalError::TypeError {
        expected: "Array".to_string(),
        found: "no array argument".to_string(),
        span: relanote_core::Span::dummy(),
    })?;

    let func = func.ok_or_else(|| EvalError::TypeError {
        expected: "Function".to_string(),
        found: "no function argument".to_string(),
        span: relanote_core::Span::dummy(),
    })?;

    let init = init.ok_or_else(|| EvalError::Custom {
        message: "foldl requires an initial value".to_string(),
        span: relanote_core::Span::dummy(),
    })?;

    let mut acc = init;
    for v in arr {
        acc = apply_closure(&func, vec![acc, v])?;
    }
    Ok(acc)
}

/// Right fold: foldr fn init array
/// Accumulates from right to left: foldr f z [a,b,c] = f a (f b (f c z))
pub fn builtin_foldr(args: Vec<Value>) -> Result<Value, EvalError> {
    if args.len() != 3 {
        return Err(EvalError::Custom {
            message: "foldr expects 3 arguments: foldr fn init array".to_string(),
            span: relanote_core::Span::dummy(),
        });
    }

    // Find the array and closure
    let mut arr = None;
    let mut func = None;
    let mut init = None;

    for arg in &args {
        match arg {
            Value::Array(a) if arr.is_none() => arr = Some(a.clone()),
            Value::Closure(f) if func.is_none() => func = Some(f.clone()),
            v if init.is_none() && !matches!(v, Value::Array(_) | Value::Closure(_)) => {
                init = Some(v.clone())
            }
            _ => {}
        }
    }

    let arr = arr.ok_or_else(|| EvalError::TypeError {
        expected: "Array".to_string(),
        found: "no array argument".to_string(),
        span: relanote_core::Span::dummy(),
    })?;

    let func = func.ok_or_else(|| EvalError::TypeError {
        expected: "Function".to_string(),
        found: "no function argument".to_string(),
        span: relanote_core::Span::dummy(),
    })?;

    let init = init.ok_or_else(|| EvalError::Custom {
        message: "foldr requires an initial value".to_string(),
        span: relanote_core::Span::dummy(),
    })?;

    // Fold from right to left
    let mut acc = init;
    for v in arr.into_iter().rev() {
        acc = apply_closure(&func, vec![v, acc])?;
    }
    Ok(acc)
}

/// Find the first element matching a predicate
/// Usage: find(fn, array) or array |> find(fn)
pub fn builtin_find(args: Vec<Value>) -> Result<Value, EvalError> {
    if args.len() != 2 {
        return Err(EvalError::Custom {
            message: "find expects 2 arguments (fn, array)".to_string(),
            span: relanote_core::Span::dummy(),
        });
    }

    let (arr, func) = match (&args[0], &args[1]) {
        (Value::Array(arr), Value::Closure(f)) => (arr.clone(), f.clone()),
        (Value::Closure(f), Value::Array(arr)) => (arr.clone(), f.clone()),
        _ => {
            return Err(EvalError::TypeError {
                expected: "Array and Function".to_string(),
                found: format!("{:?}, {:?}", args[0], args[1]),
                span: relanote_core::Span::dummy(),
            })
        }
    };

    for v in arr {
        let result = apply_closure(&func, vec![v.clone()])?;
        if let Value::Bool(true) = result {
            return Ok(v);
        }
    }
    Ok(Value::Unit) // Not found
}

/// Check if any element matches a predicate
/// Usage: any(fn, array) or array |> any(fn)
pub fn builtin_any(args: Vec<Value>) -> Result<Value, EvalError> {
    if args.len() != 2 {
        return Err(EvalError::Custom {
            message: "any expects 2 arguments (fn, array)".to_string(),
            span: relanote_core::Span::dummy(),
        });
    }

    let (arr, func) = match (&args[0], &args[1]) {
        (Value::Array(arr), Value::Closure(f)) => (arr.clone(), f.clone()),
        (Value::Closure(f), Value::Array(arr)) => (arr.clone(), f.clone()),
        _ => {
            return Err(EvalError::TypeError {
                expected: "Array and Function".to_string(),
                found: format!("{:?}, {:?}", args[0], args[1]),
                span: relanote_core::Span::dummy(),
            })
        }
    };

    for v in arr {
        let result = apply_closure(&func, vec![v])?;
        if let Value::Bool(true) = result {
            return Ok(Value::Bool(true));
        }
    }
    Ok(Value::Bool(false))
}

/// Check if all elements match a predicate
/// Usage: all(fn, array) or array |> all(fn)
pub fn builtin_all(args: Vec<Value>) -> Result<Value, EvalError> {
    if args.len() != 2 {
        return Err(EvalError::Custom {
            message: "all expects 2 arguments (fn, array)".to_string(),
            span: relanote_core::Span::dummy(),
        });
    }

    let (arr, func) = match (&args[0], &args[1]) {
        (Value::Array(arr), Value::Closure(f)) => (arr.clone(), f.clone()),
        (Value::Closure(f), Value::Array(arr)) => (arr.clone(), f.clone()),
        _ => {
            return Err(EvalError::TypeError {
                expected: "Array and Function".to_string(),
                found: format!("{:?}, {:?}", args[0], args[1]),
                span: relanote_core::Span::dummy(),
            })
        }
    };

    for v in arr {
        let result = apply_closure(&func, vec![v])?;
        if let Value::Bool(false) = result {
            return Ok(Value::Bool(false));
        }
    }
    Ok(Value::Bool(true))
}

/// Take the first n elements
/// Usage: take(n, array) or array |> take(n)
pub fn builtin_take(args: Vec<Value>) -> Result<Value, EvalError> {
    if args.len() != 2 {
        return Err(EvalError::Custom {
            message: "take expects 2 arguments (n, array)".to_string(),
            span: relanote_core::Span::dummy(),
        });
    }

    let (arr, n) = match (&args[0], &args[1]) {
        (Value::Array(arr), Value::Int(n)) => (arr.clone(), *n as usize),
        (Value::Int(n), Value::Array(arr)) => (arr.clone(), *n as usize),
        _ => {
            return Err(EvalError::TypeError {
                expected: "Array and Int".to_string(),
                found: format!("{:?}, {:?}", args[0], args[1]),
                span: relanote_core::Span::dummy(),
            })
        }
    };

    Ok(Value::Array(arr.into_iter().take(n).collect()))
}

/// Drop the first n elements
/// Usage: drop(n, array) or array |> drop(n)
pub fn builtin_drop(args: Vec<Value>) -> Result<Value, EvalError> {
    if args.len() != 2 {
        return Err(EvalError::Custom {
            message: "drop expects 2 arguments (n, array)".to_string(),
            span: relanote_core::Span::dummy(),
        });
    }

    let (arr, n) = match (&args[0], &args[1]) {
        (Value::Array(arr), Value::Int(n)) => (arr.clone(), *n as usize),
        (Value::Int(n), Value::Array(arr)) => (arr.clone(), *n as usize),
        _ => {
            return Err(EvalError::TypeError {
                expected: "Array and Int".to_string(),
                found: format!("{:?}, {:?}", args[0], args[1]),
                span: relanote_core::Span::dummy(),
            })
        }
    };

    Ok(Value::Array(arr.into_iter().skip(n).collect()))
}

/// Zip two arrays together
/// Usage: zip(array1, array2)
pub fn builtin_zip(args: Vec<Value>) -> Result<Value, EvalError> {
    if args.len() != 2 {
        return Err(EvalError::Custom {
            message: "zip expects 2 arguments".to_string(),
            span: relanote_core::Span::dummy(),
        });
    }

    let (arr1, arr2) = match (&args[0], &args[1]) {
        (Value::Array(a1), Value::Array(a2)) => (a1.clone(), a2.clone()),
        _ => {
            return Err(EvalError::TypeError {
                expected: "Two Arrays".to_string(),
                found: format!("{:?}, {:?}", args[0], args[1]),
                span: relanote_core::Span::dummy(),
            })
        }
    };

    let zipped: Vec<Value> = arr1
        .into_iter()
        .zip(arr2)
        .map(|(a, b)| Value::Tuple(vec![a, b]))
        .collect();
    Ok(Value::Array(zipped))
}

/// Concatenate two arrays
/// Usage: concat(array1, array2)
pub fn builtin_concat(args: Vec<Value>) -> Result<Value, EvalError> {
    if args.len() != 2 {
        return Err(EvalError::Custom {
            message: "concat expects 2 arguments".to_string(),
            span: relanote_core::Span::dummy(),
        });
    }

    let (arr1, arr2) = match (&args[0], &args[1]) {
        (Value::Array(a1), Value::Array(a2)) => (a1.clone(), a2.clone()),
        _ => {
            return Err(EvalError::TypeError {
                expected: "Two Arrays".to_string(),
                found: format!("{:?}, {:?}", args[0], args[1]),
                span: relanote_core::Span::dummy(),
            })
        }
    };

    let mut result = arr1;
    result.extend(arr2);
    Ok(Value::Array(result))
}

/// Get the length of an array
/// Usage: len(array)
pub fn builtin_len(args: Vec<Value>) -> Result<Value, EvalError> {
    if args.len() != 1 {
        return Err(EvalError::Custom {
            message: "len expects 1 argument".to_string(),
            span: relanote_core::Span::dummy(),
        });
    }

    match &args[0] {
        Value::Array(arr) => Ok(Value::Int(arr.len() as i64)),
        Value::String(s) => Ok(Value::Int(s.len() as i64)),
        _ => Err(EvalError::TypeError {
            expected: "Array or String".to_string(),
            found: format!("{:?}", args[0]),
            span: relanote_core::Span::dummy(),
        }),
    }
}

/// FlatMap: map then flatten
/// Usage: flatMap(fn, array) or array |> flatMap(fn)
pub fn builtin_flat_map(args: Vec<Value>) -> Result<Value, EvalError> {
    if args.len() != 2 {
        return Err(EvalError::Custom {
            message: "flatMap expects 2 arguments (fn, array)".to_string(),
            span: relanote_core::Span::dummy(),
        });
    }

    let (arr, func) = match (&args[0], &args[1]) {
        (Value::Array(arr), Value::Closure(f)) => (arr.clone(), f.clone()),
        (Value::Closure(f), Value::Array(arr)) => (arr.clone(), f.clone()),
        _ => {
            return Err(EvalError::TypeError {
                expected: "Array and Function".to_string(),
                found: format!("{:?}, {:?}", args[0], args[1]),
                span: relanote_core::Span::dummy(),
            })
        }
    };

    let mut results = Vec::new();
    for v in arr {
        let result = apply_closure(&func, vec![v])?;
        match result {
            Value::Array(inner) => results.extend(inner),
            other => results.push(other),
        }
    }
    Ok(Value::Array(results))
}

/// Helper function to apply a closure to arguments
fn apply_closure(closure: &Closure, args: Vec<Value>) -> Result<Value, EvalError> {
    if closure.params.len() != args.len() {
        return Err(EvalError::WrongArity {
            expected: closure.params.len(),
            got: args.len(),
            span: relanote_core::Span::dummy(),
        });
    }

    // Create new environment with closure's captured environment as parent
    let new_env = Rc::new(RefCell::new(Env::with_parent(closure.env.clone())));

    // Bind parameters
    for (param, arg) in closure.params.iter().zip(args) {
        new_env.borrow_mut().bind(*param, arg);
    }

    // Evaluate body - we need to use a simple evaluator here
    // For now, we'll need to import Evaluator to do this properly
    // This is a limitation - we may need to restructure

    // For closures that return simple values, we can evaluate expressions directly
    // But for complex expressions, we'd need the full evaluator

    // For now, return an error if we can't evaluate
    Err(EvalError::Custom {
        message: "Closure evaluation in functional builtins requires evaluator context".to_string(),
        span: relanote_core::Span::dummy(),
    })
}
