///|
test "render() of a 3-slot block emits 3 note-on events" {
  let one : @ast.Pitch = @ast.ScaleIndex(1)
  let three : @ast.Pitch = @ast.ScaleIndex(3)
  let five : @ast.Pitch = @ast.ScaleIndex(5)
  let one_slot : @ast.Slot = @ast.Note(
    pitch=@core.Spanned::new(one, @core.Span::dummy()),
    articulations=[],
    duration=None,
  )
  let three_slot : @ast.Slot = @ast.Note(
    pitch=@core.Spanned::new(three, @core.Span::dummy()),
    articulations=[],
    duration=None,
  )
  let five_slot : @ast.Slot = @ast.Note(
    pitch=@core.Spanned::new(five, @core.Span::dummy()),
    articulations=[],
    duration=None,
  )
  let block = @ast.Block::new([
    @core.Spanned::new(one_slot, @core.Span::dummy()),
    @core.Spanned::new(three_slot, @core.Span::dummy()),
    @core.Spanned::new(five_slot, @core.Span::dummy()),
  ])
  let bytes = render_to_midi(@eval.BlockV(block))
  // Count note-on bytes — they all have status byte 0x90.
  let mut note_ons = 0
  let mut i = 18
  while i < bytes.length() {
    if bytes[i].to_int() == 0x90 {
      note_ons += 1
    }
    i += 1
  }
  assert_eq(note_ons, 3)
}

///|
test "render() of an AbsolutePitch value emits a single note" {
  let bytes = render_to_midi(@eval.AbsolutePitchV(60))
  let mut note_ons = 0
  let mut i = 18
  while i < bytes.length() {
    if bytes[i].to_int() == 0x90 {
      note_ons += 1
    }
    i += 1
  }
  assert_eq(note_ons, 1)
}
