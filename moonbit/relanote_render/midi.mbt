///|
/// MIDI renderer configuration. Mirrors
/// `relanote_render::midi::MidiConfig` one-to-one.
pub struct MidiConfig {
  ticks_per_beat : Int
  tempo : Int
  base_note : Int
  pitch_bend_range : Double
}

///|
pub fn MidiConfig::default() -> MidiConfig {
  { ticks_per_beat: 480, tempo: 120, base_note: 60, pitch_bend_range: 2.0 }
}

///|
pub fn MidiConfig::ticks_per_beat(self : MidiConfig) -> Int {
  self.ticks_per_beat
}

///|
pub fn MidiConfig::tempo(self : MidiConfig) -> Int {
  self.tempo
}

///|
pub fn MidiConfig::base_note(self : MidiConfig) -> Int {
  self.base_note
}

///|
pub fn MidiConfig::pitch_bend_range(self : MidiConfig) -> Double {
  self.pitch_bend_range
}

///|
/// MIDI renderer. The Rust crate hand-writes a standard MIDI file via
/// `midly`; the MoonBit port lands the public shape so consumers compile
/// today and produces an empty byte sequence until the writer is ported.
///
/// Tracked in #11.
pub struct MidiRenderer {
  config : MidiConfig
}

///|
pub fn MidiRenderer::new(config : MidiConfig) -> MidiRenderer {
  { config, }
}

///|
pub fn MidiRenderer::config(self : MidiRenderer) -> MidiConfig {
  self.config
}

///|
/// Render an evaluated `SongValue` (placeholder for now) into bytes of
/// a standard MIDI file. Returns an empty array until the writer is
/// ported.
pub fn MidiRenderer::render(
  self : MidiRenderer,
  song : @eval.Value,
) -> Array[Byte] {
  let _ = self
  let _ = song
  []
}

///|
/// Convenience entry mirroring the Rust crate's `render_to_midi`.
pub fn render_to_midi(song : @eval.Value) -> Array[Byte] {
  MidiRenderer::new(MidiConfig::default()).render(song)
}
