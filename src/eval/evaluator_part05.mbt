///|
fn eval_concat(
  left : Value,
  right : Value,
  span : @core.Span,
) -> Result[Value, EvalError] {
  match (left, right) {
    (BlockV(_), BlockV(_)) => Ok(SequenceV(sequence_values(left, right)))
    (SequenceV(_), BlockV(_))
    | (BlockV(_), SequenceV(_))
    | (SequenceV(_), SequenceV(_)) =>
      Ok(SequenceV(sequence_values(left, right)))
    _ =>
      Err(TypeError(expected="matching concat operands", found="other", span~))
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
