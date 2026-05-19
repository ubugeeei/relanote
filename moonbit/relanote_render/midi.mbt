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
/// MIDI renderer. Produces a Standard MIDI File (SMF), format 1.
///
/// The "real" rendering path — translating an evaluated `Value` into
/// note events — lands alongside the evaluator port. Everything below
/// is the byte-level scaffolding: SMF header / track chunk framing,
/// variable-length-quantity (VLQ) encoding, the standard MIDI event
/// writers (note on / off, pitch bend, CC) and the meta-event writers
/// (tempo, time signature, end-of-track). They're tested directly so
/// the eventual walker can compose them without re-deriving the binary
/// format.
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
/// Render an evaluated value into the bytes of a valid SMF file. The
/// `value` argument is currently unused — the writer produces a
/// well-formed *empty* file (one track containing only a tempo meta
/// event and end-of-track) so downstream consumers can play /
/// validate it today.
pub fn MidiRenderer::render(
  self : MidiRenderer,
  value : @eval.Value,
) -> Array[Byte] {
  let _ = value
  let out : Array[Byte] = []
  write_smf_header(out, format=1, num_tracks=1, division=self.config.ticks_per_beat())
  let track : Array[Byte] = []
  write_meta_tempo(track, delta=0, bpm=self.config.tempo())
  write_meta_time_signature(
    track,
    delta=0,
    numerator=4,
    denominator=4,
    metronome=24,
    notated32=8,
  )
  write_meta_end_of_track(track, delta=0)
  write_track_chunk(out, track)
  out
}

///|
/// Convenience entry mirroring the Rust crate's `render_to_midi`.
pub fn render_to_midi(value : @eval.Value) -> Array[Byte] {
  MidiRenderer::new(MidiConfig::default()).render(value)
}

// ============================================================
// SMF byte writers — public so the eventual walker can compose them.
// ============================================================

///|
/// Write the 14-byte SMF header chunk into `out`.
pub fn write_smf_header(
  out : Array[Byte],
  format~ : Int,
  num_tracks~ : Int,
  division~ : Int,
) -> Unit {
  // "MThd"
  out.push(b'M')
  out.push(b'T')
  out.push(b'h')
  out.push(b'd')
  // length = 6
  write_u32_be(out, 6)
  // format
  write_u16_be(out, format)
  // num_tracks
  write_u16_be(out, num_tracks)
  // division (ticks per quarter note)
  write_u16_be(out, division)
}

///|
/// Wrap `events` in an MTrk chunk and append it to `out`.
pub fn write_track_chunk(out : Array[Byte], events : Array[Byte]) -> Unit {
  out.push(b'M')
  out.push(b'T')
  out.push(b'r')
  out.push(b'k')
  write_u32_be(out, events.length())
  for byte in events {
    out.push(byte)
  }
}

///|
/// Tempo meta event. `bpm` is converted to microseconds-per-quarter-note
/// internally (the unit SMF actually stores).
pub fn write_meta_tempo(
  out : Array[Byte],
  delta~ : Int,
  bpm~ : Int,
) -> Unit {
  write_var_len(out, delta)
  out.push(b'\xFF')
  out.push(b'\x51')
  out.push(b'\x03')
  let us_per_qn = 60000000 / bpm
  out.push(((us_per_qn >> 16) & 0xFF).to_byte())
  out.push(((us_per_qn >> 8) & 0xFF).to_byte())
  out.push((us_per_qn & 0xFF).to_byte())
}

///|
/// Time signature meta event. `denominator` is the actual denominator
/// (2, 4, 8, 16…); the function takes care of the log2 the file format
/// stores. `metronome` is MIDI clocks per click (24 is one beat in 4/4).
pub fn write_meta_time_signature(
  out : Array[Byte],
  delta~ : Int,
  numerator~ : Int,
  denominator~ : Int,
  metronome~ : Int,
  notated32~ : Int,
) -> Unit {
  write_var_len(out, delta)
  out.push(b'\xFF')
  out.push(b'\x58')
  out.push(b'\x04')
  out.push(numerator.to_byte())
  out.push(log2_int(denominator).to_byte())
  out.push(metronome.to_byte())
  out.push(notated32.to_byte())
}

///|
/// End-of-track meta event. Required as the final event of every MTrk.
pub fn write_meta_end_of_track(out : Array[Byte], delta~ : Int) -> Unit {
  write_var_len(out, delta)
  out.push(b'\xFF')
  out.push(b'\x2F')
  out.push(b'\x00')
}

///|
/// MIDI Note On event. `channel` is 0..15, `note` is 0..127, `velocity`
/// is 0..127.
pub fn write_note_on(
  out : Array[Byte],
  delta~ : Int,
  channel~ : Int,
  note~ : Int,
  velocity~ : Int,
) -> Unit {
  write_var_len(out, delta)
  out.push((0x90 | (channel & 0x0F)).to_byte())
  out.push((note & 0x7F).to_byte())
  out.push((velocity & 0x7F).to_byte())
}

///|
/// MIDI Note Off event.
pub fn write_note_off(
  out : Array[Byte],
  delta~ : Int,
  channel~ : Int,
  note~ : Int,
  velocity~ : Int,
) -> Unit {
  write_var_len(out, delta)
  out.push((0x80 | (channel & 0x0F)).to_byte())
  out.push((note & 0x7F).to_byte())
  out.push((velocity & 0x7F).to_byte())
}

///|
/// MIDI Pitch Bend event. `value` is 0..16383, centre 8192.
pub fn write_pitch_bend(
  out : Array[Byte],
  delta~ : Int,
  channel~ : Int,
  value~ : Int,
) -> Unit {
  write_var_len(out, delta)
  out.push((0xE0 | (channel & 0x0F)).to_byte())
  out.push((value & 0x7F).to_byte())
  out.push(((value >> 7) & 0x7F).to_byte())
}

///|
/// MIDI Control Change. `cc` is 0..127, `value` is 0..127.
pub fn write_cc(
  out : Array[Byte],
  delta~ : Int,
  channel~ : Int,
  cc~ : Int,
  value~ : Int,
) -> Unit {
  write_var_len(out, delta)
  out.push((0xB0 | (channel & 0x0F)).to_byte())
  out.push((cc & 0x7F).to_byte())
  out.push((value & 0x7F).to_byte())
}

///|
/// MIDI Program Change. `program` is 0..127.
pub fn write_program_change(
  out : Array[Byte],
  delta~ : Int,
  channel~ : Int,
  program~ : Int,
) -> Unit {
  write_var_len(out, delta)
  out.push((0xC0 | (channel & 0x0F)).to_byte())
  out.push((program & 0x7F).to_byte())
}

// ============================================================
// Binary helpers
// ============================================================

///|
/// SMF's variable-length quantity encoding. Each byte holds 7 bits of
/// the value; the high bit is set on every byte *except* the last.
///
/// Examples (from the SMF spec):
///   0x00000000 -> [0x00]
///   0x0000007F -> [0x7F]
///   0x00000080 -> [0x81, 0x00]
///   0x00002000 -> [0xC0, 0x00]
///   0x00003FFF -> [0xFF, 0x7F]
///   0x00004000 -> [0x81, 0x80, 0x00]
///   0x001FFFFF -> [0xFF, 0xFF, 0x7F]
///   0x0FFFFFFF -> [0xFF, 0xFF, 0xFF, 0x7F]
pub fn write_var_len(out : Array[Byte], value : Int) -> Unit {
  let mut buffer = value & 0x7F
  let mut shifted = value >> 7
  let stack : Array[Int] = []
  stack.push(buffer)
  while shifted > 0 {
    buffer = (shifted & 0x7F) | 0x80
    stack.push(buffer)
    shifted = shifted >> 7
  }
  let mut i = stack.length() - 1
  while i >= 0 {
    out.push(stack[i].to_byte())
    i -= 1
  }
}

///|
/// 16-bit big-endian write.
pub fn write_u16_be(out : Array[Byte], value : Int) -> Unit {
  out.push(((value >> 8) & 0xFF).to_byte())
  out.push((value & 0xFF).to_byte())
}

///|
/// 32-bit big-endian write.
pub fn write_u32_be(out : Array[Byte], value : Int) -> Unit {
  out.push(((value >> 24) & 0xFF).to_byte())
  out.push(((value >> 16) & 0xFF).to_byte())
  out.push(((value >> 8) & 0xFF).to_byte())
  out.push((value & 0xFF).to_byte())
}

///|
/// Integer base-2 log for power-of-two SMF denominators (1, 2, 4, 8,
/// 16, 32, …). Falls back to 0 for non-powers-of-two — callers should
/// have validated upstream.
fn log2_int(n : Int) -> Int {
  let mut x = n
  let mut k = 0
  while x > 1 {
    x = x >> 1
    k += 1
  }
  k
}
