///|
fn eval_concat(
  left : Value,
  right : Value,
  span : @core.Span,
) -> Result[Value, EvalError] {
  match (left, right) {
    _ =>
      if concat_value(left) && concat_value(right) {
        Ok(SequenceV(sequence_values(left, right)))
      } else {
        Err(
          TypeError(expected="matching concat operands", found="other", span~),
        )
      }
  }
}

///|
fn concat_value(value : Value) -> Bool {
  match value {
    BlockV(_) | SequenceV(_) | VoicedV(_, _) => true
    _ => false
  }
}

///|
fn sequence_values(left : Value, right : Value) -> Array[Value] {
  let values : Array[Value] = []
  match left {
    SequenceV(items) =>
      for item in items {
        values.push(item)
      }
    other => values.push(other)
  }
  match right {
    SequenceV(items) =>
      for item in items {
        values.push(item)
      }
    other => values.push(other)
  }
  values
}

///|
fn builtin_voice(
  args : Array[Value],
  span : @core.Span,
) -> Result[Value, EvalError] {
  if args.length() != 2 {
    return Err(WrongArity(expected=2, got=args.length(), span~))
  }
  match (args[0], args[1]) {
    (SynthV(synth), value) if concat_value(value) =>
      Ok(VoicedV(synth.name().name(), value))
    (value, SynthV(synth)) if concat_value(value) =>
      Ok(VoicedV(synth.name().name(), value))
    _ =>
      Err(TypeError(expected="Synth and playable value", found="other", span~))
  }
}

///|
fn builtin_layer(
  args : Array[Value],
  span : @core.Span,
) -> Result[Value, EvalError] {
  if args.length() != 1 {
    return Err(WrongArity(expected=1, got=args.length(), span~))
  }
  match args[0] {
    ArrayV(values) | TupleV(values) => Ok(ParallelV(values))
    _ =>
      Err(TypeError(expected="array of playable values", found="other", span~))
  }
}
