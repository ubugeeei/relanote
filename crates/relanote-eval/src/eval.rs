//! Main evaluation logic

use std::cell::RefCell;
use std::rc::Rc;

use relanote_ast::*;
use relanote_core::{intern, Spanned};

use crate::builtins::*;
use crate::env::Env;
use crate::error::EvalError;
use crate::value::*;

/// Evaluator for relanote programs
pub struct Evaluator {
    env: Rc<RefCell<Env>>,
}

impl Evaluator {
    pub fn new() -> Self {
        let env = Rc::new(RefCell::new(Env::new()));

        // Add builtins
        {
            let mut e = env.borrow_mut();
            e.bind(intern("reverse"), Value::Builtin(builtin_reverse));
            e.bind(intern("repeat"), Value::Builtin(builtin_repeat));
            e.bind(intern("transpose"), Value::Builtin(builtin_transpose));
        }

        Self { env }
    }

    /// Evaluate a program
    pub fn eval_program(&mut self, program: &Program) -> Result<Value, EvalError> {
        let mut result = Value::Unit;

        for item in &program.items {
            result = self.eval_item(item)?;
        }

        Ok(result)
    }

    /// Evaluate an item
    fn eval_item(&mut self, item: &Spanned<Item>) -> Result<Value, EvalError> {
        match &item.node {
            Item::ScaleDef(scale_def) => {
                let intervals: Vec<IntervalValue> = scale_def
                    .intervals
                    .iter()
                    .map(|i| IntervalValue::from(&i.node))
                    .collect();

                let scale = Value::Scale(ScaleValue {
                    name: scale_def.name.name.to_string(),
                    intervals,
                });

                self.env
                    .borrow_mut()
                    .bind(scale_def.name.name, scale);
                Ok(Value::Unit)
            }

            Item::ChordDef(chord_def) => {
                let intervals: Vec<IntervalValue> = chord_def
                    .intervals
                    .iter()
                    .map(|i| IntervalValue::from(&i.node))
                    .collect();

                let chord = Value::Chord(ChordValue {
                    name: chord_def.name.name.to_string(),
                    intervals,
                });

                self.env
                    .borrow_mut()
                    .bind(chord_def.name.name, chord);
                Ok(Value::Unit)
            }

            Item::LetBinding(binding) => {
                let value = self.eval_expr(&binding.value)?;

                if let Pattern::Ident(ident) = &binding.pattern.node {
                    self.env.borrow_mut().bind(ident.name, value);
                }

                Ok(Value::Unit)
            }

            Item::FunctionDef(func_def) => {
                let params: Vec<_> = func_def
                    .params
                    .iter()
                    .filter_map(|p| {
                        if let Pattern::Ident(ident) = &p.node {
                            Some(ident.name)
                        } else {
                            None
                        }
                    })
                    .collect();

                let closure = Value::Closure(Closure {
                    params,
                    body: Rc::new(func_def.body.clone()),
                    env: self.env.clone(),
                });

                self.env
                    .borrow_mut()
                    .bind(func_def.name.name, closure);
                Ok(Value::Unit)
            }

            Item::Import(_) | Item::Export(_) => Ok(Value::Unit),

            Item::ExprStmt(expr) => self.eval_expr(expr),
        }
    }

    /// Evaluate an expression
    pub fn eval_expr(&mut self, expr: &Spanned<Expr>) -> Result<Value, EvalError> {
        match &expr.node {
            Expr::Integer(n) => Ok(Value::Int(*n)),
            Expr::Float(n) => Ok(Value::Float(*n)),
            Expr::String(s) => Ok(Value::String(s.clone())),
            Expr::Bool(b) => Ok(Value::Bool(*b)),
            Expr::Unit => Ok(Value::Unit),

            Expr::Ident(ident) => self
                .env
                .borrow()
                .lookup(&ident.name)
                .ok_or_else(|| EvalError::UndefinedVariable {
                    name: ident.name.to_string(),
                    span: expr.span,
                }),

            Expr::Interval(interval) => Ok(Value::Interval(IntervalValue::from(interval))),

            Expr::Root => Ok(Value::Interval(IntervalValue { semitones: 0 })),

            Expr::Articulation(art) => Ok(Value::Articulation(*art)),

            Expr::Block(block) => {
                let slots: Result<Vec<_>, _> = block
                    .slots
                    .iter()
                    .map(|slot| self.eval_slot(slot))
                    .collect();
                Ok(Value::Block(BlockValue { slots: slots? }))
            }

            Expr::Lambda(lambda) => {
                let params: Vec<_> = lambda
                    .params
                    .iter()
                    .filter_map(|p| {
                        if let Pattern::Ident(ident) = &p.node {
                            Some(ident.name)
                        } else {
                            None
                        }
                    })
                    .collect();

                Ok(Value::Closure(Closure {
                    params,
                    body: Rc::new((*lambda.body).clone()),
                    env: self.env.clone(),
                }))
            }

            Expr::Application(app) => {
                let func = self.eval_expr(&app.func)?;
                let args: Result<Vec<_>, _> =
                    app.args.iter().map(|a| self.eval_expr(a)).collect();
                let args = args?;

                self.apply(func, args, expr.span)
            }

            Expr::Pipe(pipe) => {
                let arg = self.eval_expr(&pipe.left)?;
                let func = self.eval_expr(&pipe.right)?;
                self.apply(func, vec![arg], expr.span)
            }

            Expr::Binary(binary) => {
                let left = self.eval_expr(&binary.left)?;
                let right = self.eval_expr(&binary.right)?;
                self.eval_binary(binary.op, left, right, expr.span)
            }

            Expr::Unary(unary) => {
                let operand = self.eval_expr(&unary.operand)?;
                self.eval_unary(unary.op, operand, expr.span)
            }

            Expr::Array(elements) => {
                let values: Result<Vec<_>, _> =
                    elements.iter().map(|e| self.eval_expr(e)).collect();
                Ok(Value::Array(values?))
            }

            Expr::Tuple(elements) => {
                let values: Result<Vec<_>, _> =
                    elements.iter().map(|e| self.eval_expr(e)).collect();
                Ok(Value::Tuple(values?))
            }

            Expr::Index(index) => {
                let base = self.eval_expr(&index.base)?;
                let idx = self.eval_expr(&index.index)?;

                match (base, idx) {
                    (Value::Array(arr), Value::Int(i)) => {
                        let i = i as usize;
                        arr.get(i).cloned().ok_or(EvalError::IndexOutOfBounds {
                            index: i as i64,
                            len: arr.len(),
                            span: expr.span,
                        })
                    }
                    (Value::Scale(scale), Value::Int(i)) => {
                        let i = (i - 1) as usize; // 1-based indexing for scales
                        scale
                            .intervals
                            .get(i)
                            .map(|interval| Value::Interval(interval.clone()))
                            .ok_or(EvalError::IndexOutOfBounds {
                                index: i as i64,
                                len: scale.intervals.len(),
                                span: expr.span,
                            })
                    }
                    _ => Err(EvalError::TypeError {
                        expected: "Array or Scale".to_string(),
                        found: "other".to_string(),
                        span: expr.span,
                    }),
                }
            }

            Expr::If(if_expr) => {
                let cond = self.eval_expr(&if_expr.condition)?;
                match cond {
                    Value::Bool(true) => self.eval_expr(&if_expr.then_branch),
                    Value::Bool(false) => {
                        if let Some(else_branch) = &if_expr.else_branch {
                            self.eval_expr(else_branch)
                        } else {
                            Ok(Value::Unit)
                        }
                    }
                    _ => Err(EvalError::TypeError {
                        expected: "Bool".to_string(),
                        found: format!("{:?}", cond),
                        span: if_expr.condition.span,
                    }),
                }
            }

            Expr::Let(let_expr) => {
                let value = self.eval_expr(&let_expr.value)?;

                let old_env = self.env.clone();
                self.env = Rc::new(RefCell::new(Env::with_parent(old_env.clone())));

                if let Pattern::Ident(ident) = &let_expr.pattern.node {
                    self.env.borrow_mut().bind(ident.name, value);
                }

                let result = self.eval_expr(&let_expr.body)?;
                self.env = old_env;
                Ok(result)
            }

            Expr::Paren(inner) => self.eval_expr(inner),
            Expr::Annotated(inner, _) => self.eval_expr(inner),

            // Placeholder for complex expressions
            _ => Ok(Value::Unit),
        }
    }

    /// Evaluate a slot in a block
    fn eval_slot(&mut self, slot: &Spanned<Slot>) -> Result<SlotValue, EvalError> {
        match &slot.node {
            Slot::Note { pitch, articulations } => {
                let interval = self.eval_pitch(&pitch.node)?;
                Ok(SlotValue::Note {
                    interval,
                    articulations: articulations.clone(),
                })
            }
            Slot::Rest => Ok(SlotValue::Rest),
            Slot::Chord { pitches, articulations } => {
                let intervals: Result<Vec<_>, _> = pitches
                    .iter()
                    .map(|p| self.eval_pitch(&p.node))
                    .collect();
                Ok(SlotValue::Chord {
                    intervals: intervals?,
                    articulations: articulations.clone(),
                })
            }
            Slot::Tuplet(tuplet) => {
                let slots: Result<Vec<_>, _> = tuplet
                    .contents
                    .iter()
                    .map(|s| self.eval_slot(s))
                    .collect();
                let target = self.eval_expr(&tuplet.target_beats)?;
                let target_beats = match target {
                    Value::Int(n) => n,
                    _ => 2, // Default
                };
                Ok(SlotValue::Tuplet {
                    slots: slots?,
                    target_beats,
                })
            }
        }
    }

    /// Evaluate a pitch
    fn eval_pitch(&self, pitch: &Pitch) -> Result<IntervalValue, EvalError> {
        match pitch {
            Pitch::Interval(interval) => Ok(IntervalValue::from(interval)),
            Pitch::Root => Ok(IntervalValue { semitones: 0 }),
            Pitch::ScaleIndex(idx) => {
                // Simplified: return interval based on major scale
                let semitones = match idx {
                    1 => 0,  // R
                    2 => 2,  // M2
                    3 => 4,  // M3
                    4 => 5,  // P4
                    5 => 7,  // P5
                    6 => 9,  // M6
                    7 => 11, // M7
                    _ => 0,
                };
                Ok(IntervalValue { semitones })
            }
            Pitch::ScaleIndexMod(idx, accidentals) => {
                let base = match idx {
                    1 => 0,
                    2 => 2,
                    3 => 4,
                    4 => 5,
                    5 => 7,
                    6 => 9,
                    7 => 11,
                    _ => 0,
                };
                let offset: i32 = accidentals
                    .iter()
                    .map(|a| match a {
                        relanote_lexer::token::Accidental::Sharp => 1,
                        relanote_lexer::token::Accidental::Flat => -1,
                    })
                    .sum();
                Ok(IntervalValue {
                    semitones: base + offset,
                })
            }
        }
    }

    /// Apply a function to arguments
    fn apply(
        &mut self,
        func: Value,
        args: Vec<Value>,
        span: relanote_core::Span,
    ) -> Result<Value, EvalError> {
        match func {
            Value::Closure(closure) => {
                if closure.params.len() != args.len() {
                    return Err(EvalError::WrongArity {
                        expected: closure.params.len(),
                        got: args.len(),
                        span,
                    });
                }

                let old_env = self.env.clone();
                self.env = Rc::new(RefCell::new(Env::with_parent(closure.env)));

                for (param, arg) in closure.params.iter().zip(args) {
                    self.env.borrow_mut().bind(*param, arg);
                }

                let result = self.eval_expr(&closure.body)?;
                self.env = old_env;
                Ok(result)
            }
            Value::Builtin(f) => f(args),
            _ => Err(EvalError::NotAFunction { span }),
        }
    }

    /// Evaluate binary operation
    fn eval_binary(
        &self,
        op: BinaryOp,
        left: Value,
        right: Value,
        span: relanote_core::Span,
    ) -> Result<Value, EvalError> {
        match (op, left, right) {
            (BinaryOp::Add, Value::Int(a), Value::Int(b)) => Ok(Value::Int(a + b)),
            (BinaryOp::Sub, Value::Int(a), Value::Int(b)) => Ok(Value::Int(a - b)),
            (BinaryOp::Mul, Value::Int(a), Value::Int(b)) => Ok(Value::Int(a * b)),
            (BinaryOp::Div, Value::Int(a), Value::Int(b)) => {
                if b == 0 {
                    Err(EvalError::DivisionByZero { span })
                } else {
                    Ok(Value::Int(a / b))
                }
            }
            (BinaryOp::Eq, a, b) => Ok(Value::Bool(values_equal(&a, &b))),
            (BinaryOp::Ne, a, b) => Ok(Value::Bool(!values_equal(&a, &b))),
            (BinaryOp::Lt, Value::Int(a), Value::Int(b)) => Ok(Value::Bool(a < b)),
            (BinaryOp::Le, Value::Int(a), Value::Int(b)) => Ok(Value::Bool(a <= b)),
            (BinaryOp::Gt, Value::Int(a), Value::Int(b)) => Ok(Value::Bool(a > b)),
            (BinaryOp::Ge, Value::Int(a), Value::Int(b)) => Ok(Value::Bool(a >= b)),
            (BinaryOp::And, Value::Bool(a), Value::Bool(b)) => Ok(Value::Bool(a && b)),
            (BinaryOp::Or, Value::Bool(a), Value::Bool(b)) => Ok(Value::Bool(a || b)),
            _ => Err(EvalError::TypeError {
                expected: "compatible types".to_string(),
                found: "incompatible types".to_string(),
                span,
            }),
        }
    }

    /// Evaluate unary operation
    fn eval_unary(
        &self,
        op: UnaryOp,
        operand: Value,
        span: relanote_core::Span,
    ) -> Result<Value, EvalError> {
        match (op, operand) {
            (UnaryOp::Neg, Value::Int(n)) => Ok(Value::Int(-n)),
            (UnaryOp::Neg, Value::Float(n)) => Ok(Value::Float(-n)),
            (UnaryOp::Not, Value::Bool(b)) => Ok(Value::Bool(!b)),
            _ => Err(EvalError::TypeError {
                expected: "numeric or boolean".to_string(),
                found: "other".to_string(),
                span,
            }),
        }
    }
}

fn values_equal(a: &Value, b: &Value) -> bool {
    match (a, b) {
        (Value::Int(a), Value::Int(b)) => a == b,
        (Value::Float(a), Value::Float(b)) => (a - b).abs() < f64::EPSILON,
        (Value::String(a), Value::String(b)) => a == b,
        (Value::Bool(a), Value::Bool(b)) => a == b,
        (Value::Unit, Value::Unit) => true,
        _ => false,
    }
}

impl Default for Evaluator {
    fn default() -> Self {
        Self::new()
    }
}

#[cfg(test)]
mod tests {
    use relanote_parser::parse;

    use super::*;

    #[test]
    fn test_eval_integer() {
        let (program, _) = parse("42");
        let mut eval = Evaluator::new();
        let result = eval.eval_program(&program).unwrap();
        assert!(matches!(result, Value::Int(42)));
    }

    #[test]
    fn test_eval_let() {
        let (program, diagnostics) = parse("let x = 42 in x");
        assert!(!diagnostics.has_errors(), "Parse errors: {:?}", diagnostics);
        let mut eval = Evaluator::new();
        let result = eval.eval_program(&program).unwrap();
        assert!(matches!(result, Value::Int(42)), "Expected Int(42), got {:?}", result);
    }

    #[test]
    fn test_eval_lambda() {
        let (program, _) = parse("let f = \\x -> x in f(42)");
        let mut eval = Evaluator::new();
        let result = eval.eval_program(&program).unwrap();
        assert!(matches!(result, Value::Int(42)));
    }
}
