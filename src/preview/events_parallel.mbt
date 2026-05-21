///|
fn collect_parallel(
  values : Array[@eval.Value],
  out : Array[NoteEvent],
  start : Double,
  context : PreviewContext,
) -> Double {
  let mut end_ = start
  for value in values {
    let next = collect_value(value, out, start, context)
    if next > end_ {
      end_ = next
    }
  }
  end_
}
