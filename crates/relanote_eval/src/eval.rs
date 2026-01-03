//! Main evaluation logic

use std::cell::RefCell;
use std::collections::HashMap;
use std::path::PathBuf;
use std::rc::Rc;

use relanote_ast::*;
use relanote_core::{intern, Spanned};

use crate::builtins::*;
use crate::env::Env;
use crate::error::EvalError;
use crate::value::*;

/// Module registry to track loaded modules
#[derive(Default)]
pub struct ModuleRegistry {
    /// Loaded modules: module path -> module environment
    modules: HashMap<String, Rc<RefCell<Env>>>,
    /// Currently loading modules (for circular dependency detection)
    loading: Vec<String>,
}

impl ModuleRegistry {
    pub fn new() -> Self {
        Self::default()
    }

    /// Check if a module is currently being loaded (circular dependency)
    pub fn is_loading(&self, path: &str) -> bool {
        self.loading.contains(&path.to_string())
    }

    /// Mark a module as currently loading
    pub fn start_loading(&mut self, path: &str) {
        self.loading.push(path.to_string());
    }

    /// Mark a module as finished loading
    pub fn finish_loading(&mut self, path: &str) {
        self.loading.retain(|p| p != path);
    }

    /// Register a loaded module
    pub fn register(&mut self, path: &str, env: Rc<RefCell<Env>>) {
        self.modules.insert(path.to_string(), env);
    }

    /// Get a loaded module
    pub fn get(&self, path: &str) -> Option<Rc<RefCell<Env>>> {
        self.modules.get(path).cloned()
    }
}

/// Evaluator for relanote programs
pub struct Evaluator {
    env: Rc<RefCell<Env>>,
    /// Module registry for tracking loaded modules
    modules: ModuleRegistry,
    /// Base directory for module resolution
    base_dir: Option<PathBuf>,
}

impl Evaluator {
    pub fn new() -> Self {
        Self::with_base_dir(None)
    }

    pub fn with_base_dir(base_dir: Option<PathBuf>) -> Self {
        let env = Rc::new(RefCell::new(Env::new()));

        // Add primitive builtins
        {
            let mut e = env.borrow_mut();
            // Block transformations
            e.bind(intern("reverse"), Value::Builtin(builtin_reverse));
            e.bind(intern("repeat"), Value::Builtin(builtin_repeat));
            e.bind(intern("rotate"), Value::Builtin(builtin_rotate));
            e.bind(intern("transpose"), Value::Builtin(builtin_transpose));
            e.bind(intern("octaveUp"), Value::Builtin(builtin_octave_up));
            e.bind(intern("octaveDown"), Value::Builtin(builtin_octave_down));
            e.bind(intern("metronome"), Value::Builtin(builtin_metronome));
            e.bind(intern("swing"), Value::Builtin(builtin_swing));
            e.bind(intern("double_time"), Value::Builtin(builtin_double_time));

            // Effects
            e.bind(intern("reverb"), Value::Builtin(builtin_reverb));
            e.bind(intern("hall_reverb"), Value::Builtin(builtin_hall_reverb));
            e.bind(intern("room_reverb"), Value::Builtin(builtin_room_reverb));
            e.bind(intern("plate_reverb"), Value::Builtin(builtin_plate_reverb));
            e.bind(intern("dry"), Value::Builtin(builtin_dry));
            e.bind(intern("volume"), Value::Builtin(builtin_volume));

            // Synth functions
            e.bind(intern("voice"), Value::Builtin(builtin_voice));
            e.bind(intern("cutoff"), Value::Builtin(builtin_cutoff));
            e.bind(intern("resonance"), Value::Builtin(builtin_resonance));
            e.bind(intern("detune"), Value::Builtin(builtin_detune));
            e.bind(intern("adsr"), Value::Builtin(builtin_adsr));
            e.bind(intern("envelope"), Value::Builtin(builtin_env));

            // Filter constructors
            e.bind(intern("LowPass"), Value::Builtin(builtin_lowpass));
            e.bind(intern("HighPass"), Value::Builtin(builtin_highpass));
            e.bind(intern("BandPass"), Value::Builtin(builtin_bandpass));

            // Oscillator constructors
            e.bind(intern("Pulse"), Value::Builtin(builtin_pulse));
            e.bind(intern("Square"), Value::Builtin(builtin_square));
            e.bind(intern("Saw"), Value::Builtin(builtin_saw));
            e.bind(intern("Triangle"), Value::Builtin(builtin_triangle));
            e.bind(intern("Sine"), Value::Builtin(builtin_sine));
            e.bind(intern("Noise"), Value::Builtin(builtin_noise));

            // Functional programming utilities
            e.bind(intern("take"), Value::Builtin(builtin_take));
            e.bind(intern("drop"), Value::Builtin(builtin_drop));
            e.bind(intern("zip"), Value::Builtin(builtin_zip));
            e.bind(intern("concat"), Value::Builtin(builtin_concat));
            e.bind(intern("len"), Value::Builtin(builtin_len));
            e.bind(intern("map"), Value::Builtin(builtin_map));
            e.bind(intern("filter"), Value::Builtin(builtin_filter));
            e.bind(intern("foldl"), Value::Builtin(builtin_foldl));
            e.bind(intern("foldr"), Value::Builtin(builtin_foldr));
            e.bind(intern("find"), Value::Builtin(builtin_find));
            e.bind(intern("any"), Value::Builtin(builtin_any));
            e.bind(intern("all"), Value::Builtin(builtin_all));
            e.bind(intern("flat_map"), Value::Builtin(builtin_flat_map));
        }

        let mut evaluator = Self {
            env,
            modules: ModuleRegistry::new(),
            base_dir,
        };

        // Load stdlib prelude (scales, chords, synth presets)
        evaluator.load_prelude();

        evaluator
    }

    /// Set the base directory for module resolution
    pub fn set_base_dir(&mut self, dir: PathBuf) {
        self.base_dir = Some(dir);
    }

    /// Load the standard library prelude
    fn load_prelude(&mut self) {
        use relanote_stdlib::prelude::PRELUDE;

        let (program, _diagnostics) = relanote_parser::parse(PRELUDE);
        // Ignore errors in prelude - it should always be valid
        let _ = self.eval_program(&program);
    }

    /// Load a module by name
    fn load_module(&mut self, name: &str) -> Result<(), EvalError> {
        // Check if already loaded
        if self.modules.get(name).is_some() {
            return Ok(());
        }

        // Check for circular dependencies
        if self.modules.is_loading(name) {
            return Err(EvalError::CircularModuleDependency {
                module: name.to_string(),
            });
        }

        // Resolve module path
        let module_path = self.resolve_module_path(name)?;

        // Read module source
        let source =
            std::fs::read_to_string(&module_path).map_err(|e| EvalError::ModuleNotFound {
                module: name.to_string(),
                path: module_path.display().to_string(),
                reason: e.to_string(),
            })?;

        // Mark as loading
        self.modules.start_loading(name);

        // Create a new environment for the module
        let module_env = Rc::new(RefCell::new(Env::with_parent(self.env.clone())));
        let old_env = self.env.clone();
        self.env = module_env.clone();

        // Parse and evaluate the module
        let (program, _diagnostics) = relanote_parser::parse(&source);
        let result = self.eval_program(&program);

        // Restore environment
        self.env = old_env;

        // Mark as finished loading
        self.modules.finish_loading(name);

        // Register module if successful
        if result.is_ok() {
            self.modules.register(name, module_env);
        }

        result.map(|_| ())
    }

    /// Resolve module path from module name
    fn resolve_module_path(&self, name: &str) -> Result<PathBuf, EvalError> {
        let base_dir = self.base_dir.clone().unwrap_or_else(|| PathBuf::from("."));
        let module_file = format!("{}.rela", name);
        let path = base_dir.join(&module_file);

        if path.exists() {
            Ok(path)
        } else {
            Err(EvalError::ModuleNotFound {
                module: name.to_string(),
                path: path.display().to_string(),
                reason: "file does not exist".to_string(),
            })
        }
    }

    /// Evaluate a use declaration
    fn eval_use(&mut self, use_decl: &UseDecl) -> Result<(), EvalError> {
        let segments: Vec<String> = use_decl
            .path
            .segments
            .iter()
            .map(|s| s.name.to_string())
            .collect();

        if segments.is_empty() {
            return Ok(());
        }

        // First segment is the module name
        let module_name = &segments[0];

        // Load module if not already loaded
        self.load_module(module_name)?;

        // Get module environment
        let module_env =
            self.modules
                .get(module_name)
                .ok_or_else(|| EvalError::ModuleNotFound {
                    module: module_name.clone(),
                    path: format!("{}.rela", module_name),
                    reason: "module not registered".to_string(),
                })?;

        // Import bindings based on use kind
        match &use_decl.path.kind {
            UseKind::Simple => {
                // use foo::bar - import the final segment
                if segments.len() >= 2 {
                    let name = &segments[segments.len() - 1];
                    let symbol = intern(name);
                    if let Some(value) = module_env.borrow().lookup(&symbol) {
                        self.env.borrow_mut().bind(symbol, value);
                    }
                }
            }
            UseKind::Glob => {
                // use foo::* - import all public bindings
                let bindings = module_env.borrow().all_bindings();
                for (symbol, value) in bindings {
                    self.env.borrow_mut().bind(symbol, value);
                }
            }
            UseKind::Group(items) => {
                // use foo::{a, b as c} - import specific items
                for item in items {
                    let symbol = item.name.name;
                    if let Some(value) = module_env.borrow().lookup(&symbol) {
                        let target_name = item.alias.as_ref().map(|a| a.name).unwrap_or(symbol);
                        self.env.borrow_mut().bind(target_name, value);
                    }
                }
            }
        }

        Ok(())
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

                self.env.borrow_mut().bind(scale_def.name.name, scale);
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

                self.env.borrow_mut().bind(chord_def.name.name, chord);
                Ok(Value::Unit)
            }

            Item::SynthDef(synth_def) => {
                // Create a default synth and customize based on properties
                let mut synth = SynthValue::new(synth_def.name.name.to_string());

                for prop in &synth_def.properties {
                    match &prop.node {
                        relanote_ast::music::SynthProperty::Oscillator(expr) => {
                            let value = self.eval_expr(expr)?;
                            // Handle both direct Oscillator values and Builtin functions (like Noise, Square)
                            match value {
                                Value::Oscillator(osc) => {
                                    synth.oscillators = vec![osc];
                                }
                                Value::Builtin(f) => {
                                    // Call the builtin with empty args (for parameterless oscillators)
                                    if let Ok(Value::Oscillator(osc)) = f(vec![]) {
                                        synth.oscillators = vec![osc];
                                    }
                                }
                                _ => {}
                            }
                        }
                        relanote_ast::music::SynthProperty::Envelope(expr) => {
                            if let Ok(Value::ADSR(adsr)) = self.eval_expr(expr) {
                                synth.envelope = adsr;
                            }
                        }
                        relanote_ast::music::SynthProperty::Filter(expr) => {
                            let value = self.eval_expr(expr)?;
                            // Handle both direct Filter values and Builtin functions
                            match value {
                                Value::Filter(filter) => {
                                    synth.filter = Some(filter);
                                }
                                Value::Builtin(f) => {
                                    // Call the builtin with empty args (though filters need args)
                                    if let Ok(Value::Filter(filter)) = f(vec![]) {
                                        synth.filter = Some(filter);
                                    }
                                }
                                _ => {}
                            }
                        }
                        relanote_ast::music::SynthProperty::Detune(expr) => {
                            if let Ok(Value::Float(cents)) = self.eval_expr(expr) {
                                synth.detune_cents = cents;
                            } else if let Ok(Value::Int(cents)) = self.eval_expr(expr) {
                                synth.detune_cents = cents as f64;
                            }
                        }
                    }
                }

                let synth_value = Value::Synth(synth);
                self.env.borrow_mut().bind(synth_def.name.name, synth_value);
                Ok(Value::Unit)
            }

            Item::LetBinding(binding) => {
                let value = self.eval_expr(&binding.value)?;

                if let Pattern::Ident(ident) = &binding.pattern.node {
                    self.env.borrow_mut().bind(ident.name, value);
                }

                Ok(Value::Unit)
            }

            Item::SetBinding(binding) => {
                let value = self.eval_expr(&binding.value)?;
                self.env.borrow_mut().bind(binding.name.name, value);
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

                self.env.borrow_mut().bind(func_def.name.name, closure);
                Ok(Value::Unit)
            }

            Item::Import(_) | Item::Export(_) => Ok(Value::Unit),

            Item::Mod(mod_decl) => {
                // Module declaration - load module from file
                self.load_module(&mod_decl.name.name.to_string())?;
                Ok(Value::Unit)
            }

            Item::Use(use_decl) => {
                // Use declaration - import bindings from module
                self.eval_use(use_decl)?;
                Ok(Value::Unit)
            }

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

            Expr::Ident(ident) => {
                self.env
                    .borrow()
                    .lookup(&ident.name)
                    .ok_or_else(|| EvalError::UndefinedVariable {
                        name: ident.name.to_string(),
                        span: expr.span,
                    })
            }

            Expr::Interval(interval) => Ok(Value::Interval(IntervalValue::from(interval))),

            Expr::AbsolutePitch(pitch) => Ok(Value::AbsolutePitch(AbsolutePitchValue::from(pitch))),

            Expr::Root => Ok(Value::Interval(IntervalValue::from_cents(0.0))),

            Expr::Articulation(art) => Ok(Value::Articulation(*art)),

            Expr::Block(block) => {
                let slots: Result<Vec<_>, _> = block
                    .slots
                    .iter()
                    .map(|slot| self.eval_slot(slot))
                    .collect();
                Ok(Value::Block(BlockValue {
                    slots: slots?,
                    beats: block.duration_beats(),
                }))
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
                let args: Result<Vec<_>, _> = app.args.iter().map(|a| self.eval_expr(a)).collect();
                let args = args?;

                self.apply(func, args, expr.span)
            }

            Expr::Pipe(pipe) => {
                let arg = self.eval_expr(&pipe.left)?;
                // If right side is an application, add left arg to its args
                if let Expr::Application(app) = &pipe.right.node {
                    let func = self.eval_expr(&app.func)?;
                    let mut args = vec![arg];
                    for a in &app.args {
                        args.push(self.eval_expr(a)?);
                    }
                    self.apply(func, args, expr.span)
                } else {
                    let func = self.eval_expr(&pipe.right)?;
                    self.apply(func, vec![arg], expr.span)
                }
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

            Expr::Match(match_expr) => {
                let scrutinee = self.eval_expr(&match_expr.scrutinee)?;

                for arm in &match_expr.arms {
                    if let Some(bindings) = self.pattern_match(&arm.pattern, &scrutinee) {
                        // Check guard if present
                        if let Some(guard) = &arm.guard {
                            let old_env = self.env.clone();
                            self.env = Rc::new(RefCell::new(Env::with_parent(old_env.clone())));
                            for (name, value) in &bindings {
                                self.env.borrow_mut().bind(*name, value.clone());
                            }
                            let guard_result = self.eval_expr(guard)?;
                            self.env = old_env;
                            if !matches!(guard_result, Value::Bool(true)) {
                                continue;
                            }
                        }

                        // Bind pattern variables and evaluate body
                        let old_env = self.env.clone();
                        self.env = Rc::new(RefCell::new(Env::with_parent(old_env.clone())));
                        for (name, value) in bindings {
                            self.env.borrow_mut().bind(name, value);
                        }
                        let result = self.eval_expr(&arm.body);
                        self.env = old_env;
                        return result;
                    }
                }

                Err(EvalError::Custom {
                    message: "No matching pattern in match expression".to_string(),
                    span: expr.span,
                })
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

            Expr::Layer(layer) => {
                // Evaluate each part and create a Song with multiple parts
                let mut parts = Vec::new();
                for (i, part_expr) in layer.parts.iter().enumerate() {
                    let value = self.eval_expr(part_expr)?;
                    match value {
                        Value::Block(block) => {
                            parts.push(PartValue {
                                instrument: format!("Layer {}", i + 1),
                                blocks: vec![block],
                                envelope: None,
                                reverb_level: None,
                                volume_level: None,
                                synth: None,
                            });
                        }
                        Value::Part(part) => {
                            parts.push(part);
                        }
                        _ => {
                            // Skip non-block/part values
                        }
                    }
                }

                Ok(Value::Song(SongValue {
                    sections: vec![SectionValue {
                        name: "Layer".to_string(),
                        parts,
                    }],
                }))
            }

            Expr::InScale(in_scale) => {
                // Evaluate the scale expression and return a scale applicator
                let scale_value = self.eval_expr(&in_scale.scale)?;
                match scale_value {
                    Value::Scale(scale) => Ok(Value::InScaleApplicator(scale)),
                    _ => Err(EvalError::TypeError {
                        expected: "Scale".to_string(),
                        found: format!("{:?}", scale_value),
                        span: in_scale.scale.span,
                    }),
                }
            }

            Expr::With(with_expr) => {
                // Evaluate base and modifications
                let base = self.eval_expr(&with_expr.base)?;
                let _modifications: Result<Vec<_>, _> = with_expr
                    .modifications
                    .iter()
                    .map(|m| self.eval_expr(m))
                    .collect();
                // For now, just return the base value
                // Full modification semantics can be added later
                Ok(base)
            }

            // Placeholder for complex expressions
            _ => Ok(Value::Unit),
        }
    }

    /// Evaluate a slot in a block
    fn eval_slot(&mut self, slot: &Spanned<Slot>) -> Result<SlotValue, EvalError> {
        match &slot.node {
            Slot::Note {
                pitch,
                articulations,
                duration,
            } => {
                let interval = self.eval_pitch(&pitch.node)?;
                Ok(SlotValue::Note {
                    interval,
                    articulations: articulations.clone(),
                    duration_beats: duration.map(|d| d as f64),
                })
            }
            Slot::Rest { duration } => Ok(SlotValue::Rest {
                duration_beats: duration.map(|d| d as f64),
            }),
            Slot::Chord {
                pitches,
                articulations,
                duration,
            } => {
                let intervals: Result<Vec<_>, _> =
                    pitches.iter().map(|p| self.eval_pitch(&p.node)).collect();
                Ok(SlotValue::Chord {
                    intervals: intervals?,
                    articulations: articulations.clone(),
                    duration_beats: duration.map(|d| d as f64),
                })
            }
            Slot::Tuplet(tuplet) => {
                let slots: Result<Vec<_>, _> =
                    tuplet.contents.iter().map(|s| self.eval_slot(s)).collect();
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

    /// Convert scale index to semitones with octave support
    /// idx: 1-based scale index (1-7 for first octave, 8-14 for second, etc.)
    fn scale_index_to_semitones(idx: i64) -> i32 {
        // Major scale intervals in semitones
        const MAJOR_SCALE: [i32; 7] = [0, 2, 4, 5, 7, 9, 11];

        if idx <= 0 {
            return 0;
        }

        let idx = idx as i32;
        let octave = (idx - 1) / 7;
        let degree = ((idx - 1) % 7) as usize;

        MAJOR_SCALE[degree] + (octave * 12)
    }

    /// Evaluate a pitch
    fn eval_pitch(&self, pitch: &Pitch) -> Result<IntervalValue, EvalError> {
        match pitch {
            Pitch::Interval(interval) => Ok(IntervalValue::from(interval)),
            Pitch::Root => Ok(IntervalValue::from_cents(0.0)),
            Pitch::ScaleIndex(idx) => {
                let semitones = Self::scale_index_to_semitones(*idx as i64);
                Ok(IntervalValue::from_semitones(semitones))
            }
            Pitch::ScaleIndexMod(idx, accidentals) => {
                let base = Self::scale_index_to_semitones(*idx as i64);
                let offset: i32 = accidentals
                    .iter()
                    .map(|a| match a {
                        relanote_lexer::token::Accidental::Sharp => 1,
                        relanote_lexer::token::Accidental::Flat => -1,
                    })
                    .sum();
                Ok(IntervalValue::from_semitones(base + offset))
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
            Value::Composed(f, g) => {
                // f >> g means apply f first, then g
                // composed(x) = g(f(x))
                let intermediate = self.apply(*f, args, span)?;
                self.apply(*g, vec![intermediate], span)
            }
            Value::InScaleApplicator(scale) => {
                // Apply scale to a block, transforming <n> references
                if args.len() != 1 {
                    return Err(EvalError::WrongArity {
                        expected: 1,
                        got: args.len(),
                        span,
                    });
                }
                match &args[0] {
                    Value::Block(block) => {
                        let transformed = self.apply_scale_to_block(&scale, block);
                        Ok(Value::Block(transformed))
                    }
                    Value::Part(part) => {
                        // Transform all blocks in the part
                        let transformed_blocks: Vec<_> = part
                            .blocks
                            .iter()
                            .map(|b| self.apply_scale_to_block(&scale, b))
                            .collect();
                        Ok(Value::Part(PartValue {
                            instrument: part.instrument.clone(),
                            blocks: transformed_blocks,
                            envelope: part.envelope.clone(),
                            reverb_level: part.reverb_level,
                            volume_level: part.volume_level,
                            synth: part.synth.clone(),
                        }))
                    }
                    _ => Err(EvalError::TypeError {
                        expected: "Block or Part".to_string(),
                        found: format!("{:?}", args[0]),
                        span,
                    }),
                }
            }
            _ => Err(EvalError::NotAFunction { span }),
        }
    }

    /// Apply a scale to a block, transforming scale index references
    fn apply_scale_to_block(&self, scale: &ScaleValue, block: &BlockValue) -> BlockValue {
        let transformed_slots: Vec<_> = block
            .slots
            .iter()
            .map(|slot| self.apply_scale_to_slot(scale, slot))
            .collect();
        BlockValue {
            slots: transformed_slots,
            beats: block.beats,
        }
    }

    /// Apply a scale to a slot
    fn apply_scale_to_slot(&self, scale: &ScaleValue, slot: &SlotValue) -> SlotValue {
        match slot {
            SlotValue::Note {
                interval,
                articulations,
                duration_beats,
            } => {
                // Transform by looking up the interval's semitone in the scale
                let transformed_interval = self.transform_interval_with_scale(scale, interval);
                SlotValue::Note {
                    interval: transformed_interval,
                    articulations: articulations.clone(),
                    duration_beats: *duration_beats,
                }
            }
            SlotValue::Rest { duration_beats } => SlotValue::Rest {
                duration_beats: *duration_beats,
            },
            SlotValue::Chord {
                intervals,
                articulations,
                duration_beats,
            } => {
                let transformed: Vec<_> = intervals
                    .iter()
                    .map(|i| self.transform_interval_with_scale(scale, i))
                    .collect();
                SlotValue::Chord {
                    intervals: transformed,
                    articulations: articulations.clone(),
                    duration_beats: *duration_beats,
                }
            }
            SlotValue::Tuplet {
                slots,
                target_beats,
            } => {
                let transformed: Vec<_> = slots
                    .iter()
                    .map(|s| self.apply_scale_to_slot(scale, s))
                    .collect();
                SlotValue::Tuplet {
                    slots: transformed,
                    target_beats: *target_beats,
                }
            }
        }
    }

    /// Transform an interval using a scale
    /// This maps major scale degree semitones to the corresponding scale intervals
    fn transform_interval_with_scale(
        &self,
        scale: &ScaleValue,
        interval: &IntervalValue,
    ) -> IntervalValue {
        // Get semitones from the interval
        let semitones = (interval.cents / 100.0).round() as i32;

        // Map semitones to scale degree (reverse lookup from major scale)
        // Major scale: [0, 2, 4, 5, 7, 9, 11] for degrees 1-7
        let (octave, degree) = self.semitones_to_major_degree(semitones);

        if degree > 0 && degree <= scale.intervals.len() {
            // Get the interval from the target scale
            let scale_interval = &scale.intervals[degree - 1];
            let new_semitones = scale_interval.semitones() as i32 + (octave * 12);
            IntervalValue::from_semitones(new_semitones)
        } else {
            // Keep original if can't map
            interval.clone()
        }
    }

    /// Convert semitones back to major scale degree (1-based) and octave
    fn semitones_to_major_degree(&self, semitones: i32) -> (i32, usize) {
        const MAJOR_SCALE: [i32; 7] = [0, 2, 4, 5, 7, 9, 11];

        let octave = semitones / 12;
        let semitones_in_octave = semitones % 12;

        // Find the degree that matches these semitones
        for (idx, &scale_semitones) in MAJOR_SCALE.iter().enumerate() {
            if scale_semitones == semitones_in_octave {
                return (octave, idx + 1); // 1-based degree
            }
        }

        // If no exact match, find closest
        (octave, 0) // 0 means no match
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

            // Interval arithmetic
            (BinaryOp::Add, Value::Interval(a), Value::Interval(b)) => {
                Ok(Value::Interval(IntervalValue {
                    cents: a.cents + b.cents,
                }))
            }
            (BinaryOp::Sub, Value::Interval(a), Value::Interval(b)) => {
                Ok(Value::Interval(IntervalValue {
                    cents: a.cents - b.cents,
                }))
            }
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

            // Block concatenation (preserves each slot's original duration)
            (BinaryOp::Concat, Value::Block(a), Value::Block(b)) => {
                let a_slot_duration = a.beats / a.slots.len().max(1) as f64;
                let b_slot_duration = b.beats / b.slots.len().max(1) as f64;

                let mut slots: Vec<SlotValue> = a
                    .slots
                    .into_iter()
                    .map(|s| s.with_duration(a_slot_duration))
                    .collect();
                slots.extend(
                    b.slots
                        .into_iter()
                        .map(|s| s.with_duration(b_slot_duration)),
                );

                Ok(Value::Block(BlockValue {
                    slots,
                    beats: a.beats + b.beats,
                }))
            }

            // Array concatenation
            (BinaryOp::Concat, Value::Array(a), Value::Array(b)) => {
                let mut arr = a;
                arr.extend(b);
                Ok(Value::Array(arr))
            }

            // String concatenation
            (BinaryOp::Concat, Value::String(a), Value::String(b)) => Ok(Value::String(a + &b)),

            // Function composition: f >> g means apply f first, then g
            (BinaryOp::Compose, f, g) => {
                // Both operands should be callable (Closure, Builtin, or Composed)
                Ok(Value::Composed(Box::new(f), Box::new(g)))
            }

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

impl Evaluator {
    /// Try to match a value against a pattern, returning bindings if successful
    #[allow(clippy::only_used_in_recursion)]
    fn pattern_match(
        &self,
        pattern: &Spanned<Pattern>,
        value: &Value,
    ) -> Option<Vec<(relanote_core::InternedStr, Value)>> {
        match &pattern.node {
            Pattern::Wildcard => Some(vec![]),

            Pattern::Ident(ident) => Some(vec![(ident.name, value.clone())]),

            Pattern::Literal(lit) => {
                let matches = match (lit, value) {
                    (LiteralPattern::Integer(n), Value::Int(v)) => *n == *v,
                    (LiteralPattern::Float(f), Value::Float(v)) => (*f - *v).abs() < f64::EPSILON,
                    (LiteralPattern::String(s), Value::String(v)) => s == v,
                    (LiteralPattern::Bool(b), Value::Bool(v)) => *b == *v,
                    (LiteralPattern::Unit, Value::Unit) => true,
                    _ => false,
                };
                if matches {
                    Some(vec![])
                } else {
                    None
                }
            }

            Pattern::Tuple(patterns) => {
                if let Value::Tuple(values) = value {
                    if patterns.len() != values.len() {
                        return None;
                    }
                    let mut bindings = Vec::new();
                    for (p, v) in patterns.iter().zip(values.iter()) {
                        if let Some(mut b) = self.pattern_match(p, v) {
                            bindings.append(&mut b);
                        } else {
                            return None;
                        }
                    }
                    Some(bindings)
                } else {
                    None
                }
            }

            Pattern::Array(arr) => {
                if let Value::Array(values) = value {
                    if arr.elements.len() != values.len() {
                        return None;
                    }
                    let mut bindings = Vec::new();
                    for (p, v) in arr.elements.iter().zip(values.iter()) {
                        if let Some(mut b) = self.pattern_match(p, v) {
                            bindings.append(&mut b);
                        } else {
                            return None;
                        }
                    }
                    Some(bindings)
                } else {
                    None
                }
            }

            Pattern::Constructor { .. } => {
                // Constructor patterns not fully implemented yet
                None
            }

            Pattern::Or(p1, p2) => self
                .pattern_match(p1, value)
                .or_else(|| self.pattern_match(p2, value)),

            Pattern::Annotated(p, _) => self.pattern_match(p, value),
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

impl Evaluator {
    /// Get a binding from the environment by name
    pub fn get_binding(&self, name: &str) -> Option<Value> {
        self.env.borrow().lookup(&intern(name))
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
        assert!(
            matches!(result, Value::Int(42)),
            "Expected Int(42), got {:?}",
            result
        );
    }

    #[test]
    fn test_eval_lambda() {
        let (program, _) = parse("let f = \\x -> x in f(42)");
        let mut eval = Evaluator::new();
        let result = eval.eval_program(&program).unwrap();
        assert!(matches!(result, Value::Int(42)));
    }
}
