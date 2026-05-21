///|
/// Apply a callable value to a list of evaluated arguments. Handles
/// user lambdas and user-defined functions (named `let f x = …`).
/// Builtins land in a later sub-PR of #56 — calling one today produces
/// a `NotAFunction` error.
fn Evaluator::call(
  self : Evaluator,
  func : Value,
  args : Array[Value],
  span : @core.Span,
) -> Result[Value, EvalError] {
  match func {
    LambdaV(params, body, captured) =>
      self.run_function(params, body, captured, args, span)
    ClosureV(def, captured) =>
      self.run_function(def.params(), def.body(), captured, args, span)
    BuiltinV(name) => call_builtin(name, args, span)
    PartialBuiltinV(name, saved) => {
      let all : Array[Value] = []
      for arg in saved {
        all.push(arg)
      }
      for arg in args {
        all.push(arg)
      }
      call_builtin(name, all, span)
    }
    _ => Err(NotAFunction(span~))
  }
}

///|
/// Dispatch a built-in by name. New builtins are added to this match;
/// unknown names land in the catch-all and surface a clear error so
/// the missing-binding bug is easy to track down.
fn call_builtin(
  name : String,
  args : Array[Value],
  span : @core.Span,
) -> Result[Value, EvalError] {
  match builtin_arity(name) {
    None => return Err(Custom(message="unknown builtin: " + name, span~))
    Some(n) => if args.length() < n { return Ok(PartialBuiltinV(name, args)) }
  }
  match name {
    "reverse" => builtin_reverse(args, span)
    "repeat" => builtin_repeat(args, span)
    "rotate" => builtin_rotate(args, span)
    "double_time" => builtin_double_time(args, span)
    "octave_up" => builtin_shift_octaves(args, span, 1)
    "octave_down" => builtin_shift_octaves(args, span, -1)
    other => Err(Custom(message="unknown builtin: " + other, span~))
  }
}

///|
fn builtin_arity(name : String) -> Int? {
  match name {
    "reverse" | "double_time" | "octave_up" | "octave_down" => Some(1)
    "repeat" | "rotate" => Some(2)
    _ => None
  }
}

///|
/// `octave_up` / `octave_down` — shift every note in a block by
/// `delta` octaves (positive for up, negative for down). Mirrors the
/// `builtin_octave_up` / `builtin_octave_down` helpers in the legacy
/// crate, which both delegate to a `transpose_slot` walker.
fn builtin_shift_octaves(
  args : Array[Value],
  span : @core.Span,
  delta : Int,
) -> Result[Value, EvalError] {
  if args.length() != 1 {
    return Err(WrongArity(expected=1, got=args.length(), span~))
  }
  match args[0] {
    BlockV(block) => Ok(BlockV(shift_block_octaves(block, delta)))
    _ => Err(TypeError(expected="Block", found="other", span~))
  }
}

///|
fn shift_block_octaves(block : @ast.Block, delta : Int) -> @ast.Block {
  let new_slots : Array[@core.Spanned[@ast.Slot]] = []
  for spanned in block.slots() {
    new_slots.push(
      @core.Spanned::new(
        shift_slot_octaves(spanned.node(), delta),
        spanned.span(),
      ),
    )
  }
  match block.beats() {
    Some(b) => @ast.Block::with_beats(new_slots, b)
    None => @ast.Block::new(new_slots)
  }
}

///|
fn shift_slot_octaves(slot : @ast.Slot, delta : Int) -> @ast.Slot {
  match slot {
    @ast.Note(pitch~, articulations~, duration~) => {
      let new_pitch = @core.Spanned::new(
        shift_pitch_octaves(pitch.node(), delta),
        pitch.span(),
      )
      @ast.Note(pitch=new_pitch, articulations~, duration~)
    }
    @ast.Chord(pitches~, articulations~, duration~) => {
      let new_pitches : Array[@core.Spanned[@ast.Pitch]] = []
      for p in pitches {
        new_pitches.push(
          @core.Spanned::new(shift_pitch_octaves(p.node(), delta), p.span()),
        )
      }
      @ast.Chord(pitches=new_pitches, articulations~, duration~)
    }
    other => other
  }
}

///|
/// Shift a pitch by `delta` octaves. Scale-degree references gain
/// `7 * delta` degrees; intervals gain `7 * delta` (one octave per 7
/// scale-degree steps); microtones add `1200 * delta` cents.
fn shift_pitch_octaves(pitch : @ast.Pitch, delta : Int) -> @ast.Pitch {
  let degree_step = 7 * delta
  let cents_step = (1200 * delta).to_double()
  match pitch {
    @ast.ScaleIndex(n) => @ast.ScaleIndex(n + degree_step)
    @ast.ScaleIndexMod(n, accs) => @ast.ScaleIndexMod(n + degree_step, accs)
    @ast.Interval(lit) =>
      @ast.Interval(
        @ast.IntervalLit::new(lit.quality(), lit.degree() + degree_step).with_accidentals(
          lit.accidentals(),
        ),
      )
    @ast.Microtone(c) => @ast.Microtone(c + cents_step)
    @ast.MicrotonalInterval(lit, c) =>
      @ast.MicrotonalInterval(lit, c + cents_step)
    @ast.ScaleIndexCents(n, c) => @ast.ScaleIndexCents(n + degree_step, c)
    @ast.Root => @ast.Root
  }
}

///|
/// `rotate : Int -> Block -> Block` — shift slots left by `n` positions.
/// Negative `n` rotates right. Mirrors the legacy implementation
/// `builtin_rotate` which accepts either argument order.
fn builtin_rotate(
  args : Array[Value],
  span : @core.Span,
) -> Result[Value, EvalError] {
  if args.length() != 2 {
    return Err(WrongArity(expected=2, got=args.length(), span~))
  }
  let (n_raw, block) = match (args[0], args[1]) {
    (IntV(n), BlockV(b)) => (n.to_int(), b)
    (BlockV(b), IntV(n)) => (n.to_int(), b)
    _ => return Err(TypeError(expected="Int and Block", found="other", span~))
  }
  let len = block.slots().length()
  if len == 0 {
    return Ok(BlockV(block))
  }
  // Normalise n to [0, len) — Moonbit `%` keeps the sign of the dividend.
  let n = (n_raw % len + len) % len
  let rotated_slots : Array[@core.Spanned[@ast.Slot]] = []
  let mut i = n
  while i < len {
    rotated_slots.push(block.slots()[i])
    i += 1
  }
  i = 0
  while i < n {
    rotated_slots.push(block.slots()[i])
    i += 1
  }
  let new_block = match block.beats() {
    Some(b) => @ast.Block::with_beats(rotated_slots, b)
    None => @ast.Block::new(rotated_slots)
  }
  Ok(BlockV(new_block))
}

///|
/// `double_time : Block -> Block` — halve the block's beats, keeping
/// the slot list intact. Mirrors `builtin_double_time` in the legacy
/// block builtins module.
fn builtin_double_time(
  args : Array[Value],
  span : @core.Span,
) -> Result[Value, EvalError] {
  if args.length() != 1 {
    return Err(WrongArity(expected=1, got=args.length(), span~))
  }
  match args[0] {
    BlockV(block) => {
      let new_beats = match block.beats() {
        Some(b) => b / 2.0
        None => 0.5
      }
      Ok(BlockV(@ast.Block::with_beats(block.slots(), new_beats)))
    }
    _ => Err(TypeError(expected="Block", found="other", span~))
  }
}

///|
/// `reverse : Block -> Block` — return a block with its slots reversed
/// in source order. The legacy implementation matches the same shape; see
/// legacy source.
fn builtin_reverse(
  args : Array[Value],
  span : @core.Span,
) -> Result[Value, EvalError] {
  if args.length() != 1 {
    return Err(WrongArity(expected=1, got=args.length(), span~))
  }
  match args[0] {
    BlockV(block) => {
      let reversed_slots : Array[@core.Spanned[@ast.Slot]] = []
      let mut i = block.slots().length() - 1
      while i >= 0 {
        reversed_slots.push(block.slots()[i])
        i -= 1
      }
      let new_block = match block.beats() {
        Some(b) => @ast.Block::with_beats(reversed_slots, b)
        None => @ast.Block::new(reversed_slots)
      }
      Ok(BlockV(new_block))
    }
    _ => Err(TypeError(expected="Block", found="other", span~))
  }
}

///|
/// `repeat : Int -> Block -> Block` — repeat the slots `n` times. The
/// resulting block's beats scale by `n`.
