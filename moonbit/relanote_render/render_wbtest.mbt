test "default MidiConfig matches Rust" {
  let c = MidiConfig::default()
  assert_eq(c.ticks_per_beat(), 480)
  assert_eq(c.tempo(), 120)
  assert_eq(c.base_note(), 60)
  assert_eq(c.pitch_bend_range(), 2.0)
}

test "render_to_midi emits an empty byte stream in the skeleton" {
  let bytes = render_to_midi(@eval.Placeholder)
  assert_eq(bytes.length(), 0)
}
