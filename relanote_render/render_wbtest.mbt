///|
test "default MidiConfig matches legacy" {
  let c = MidiConfig::default()
  assert_eq(c.ticks_per_beat(), 480)
  assert_eq(c.tempo(), 120)
  assert_eq(c.base_note(), 60)
  assert_eq(c.pitch_bend_range(), 2.0)
}

// ----------------------------------------------------------------------
// SMF byte writer unit tests
// ----------------------------------------------------------------------

///|
test "write_var_len matches the SMF spec examples" {
  // The canonical examples in section A.1.1 of the SMF 1.0 spec.
  // `assert_eq` can't be called from a local closure (it raises an
  // implicit error that escapes the closure's signature), so each
  // case is inlined.
  let a : Array[Byte] = []
  write_var_len(a, 0x00000000)
  assert_eq(a.length(), 1)
  assert_eq(a[0].to_int(), 0x00)
  let b : Array[Byte] = []
  write_var_len(b, 0x0000007F)
  assert_eq(b.length(), 1)
  assert_eq(b[0].to_int(), 0x7F)
  let c : Array[Byte] = []
  write_var_len(c, 0x00000080)
  assert_eq(c.length(), 2)
  assert_eq(c[0].to_int(), 0x81)
  assert_eq(c[1].to_int(), 0x00)
  let d : Array[Byte] = []
  write_var_len(d, 0x00002000)
  assert_eq(d.length(), 2)
  assert_eq(d[0].to_int(), 0xC0)
  assert_eq(d[1].to_int(), 0x00)
  let e : Array[Byte] = []
  write_var_len(e, 0x00003FFF)
  assert_eq(e.length(), 2)
  assert_eq(e[0].to_int(), 0xFF)
  assert_eq(e[1].to_int(), 0x7F)
  let f : Array[Byte] = []
  write_var_len(f, 0x00004000)
  assert_eq(f.length(), 3)
  assert_eq(f[0].to_int(), 0x81)
  assert_eq(f[1].to_int(), 0x80)
  assert_eq(f[2].to_int(), 0x00)
  let g : Array[Byte] = []
  write_var_len(g, 0x001FFFFF)
  assert_eq(g.length(), 3)
  assert_eq(g[0].to_int(), 0xFF)
  assert_eq(g[1].to_int(), 0xFF)
  assert_eq(g[2].to_int(), 0x7F)
  let h : Array[Byte] = []
  write_var_len(h, 0x0FFFFFFF)
  assert_eq(h.length(), 4)
  assert_eq(h[0].to_int(), 0xFF)
  assert_eq(h[1].to_int(), 0xFF)
  assert_eq(h[2].to_int(), 0xFF)
  assert_eq(h[3].to_int(), 0x7F)
}

///|
test "write_u16_be / write_u32_be" {
  let buf : Array[Byte] = []
  write_u16_be(buf, 0x1234)
  assert_eq(buf.length(), 2)
  assert_eq(buf[0].to_int(), 0x12)
  assert_eq(buf[1].to_int(), 0x34)
  let buf2 : Array[Byte] = []
  write_u32_be(buf2, 0xDEADBEEF)
  assert_eq(buf2.length(), 4)
  assert_eq(buf2[0].to_int(), 0xDE)
  assert_eq(buf2[1].to_int(), 0xAD)
  assert_eq(buf2[2].to_int(), 0xBE)
  assert_eq(buf2[3].to_int(), 0xEF)
}

///|
test "SMF header is 14 bytes with the expected fields" {
  let out : Array[Byte] = []
  write_smf_header(out, format=1, num_tracks=3, division=480)
  assert_eq(out.length(), 14)
  // Magic "MThd"
  assert_eq(out[0].to_int(), 0x4D)
  assert_eq(out[1].to_int(), 0x54)
  assert_eq(out[2].to_int(), 0x68)
  assert_eq(out[3].to_int(), 0x64)
  // length = 6
  assert_eq(out[4].to_int(), 0x00)
  assert_eq(out[5].to_int(), 0x00)
  assert_eq(out[6].to_int(), 0x00)
  assert_eq(out[7].to_int(), 0x06)
  // format = 1
  assert_eq(out[8].to_int(), 0x00)
  assert_eq(out[9].to_int(), 0x01)
  // num_tracks = 3
  assert_eq(out[10].to_int(), 0x00)
  assert_eq(out[11].to_int(), 0x03)
  // division = 480 → 0x01E0
  assert_eq(out[12].to_int(), 0x01)
  assert_eq(out[13].to_int(), 0xE0)
}

///|
test "tempo meta event encodes microseconds-per-quarter-note" {
  let out : Array[Byte] = []
  // 120 BPM → 500000 us/qn = 0x07A120
  write_meta_tempo(out, delta=0, bpm=120)
  // delta(1) + FF + 51 + 03 + 3 data bytes = 7
  assert_eq(out.length(), 7)
  assert_eq(out[0].to_int(), 0x00)
  assert_eq(out[1].to_int(), 0xFF)
  assert_eq(out[2].to_int(), 0x51)
  assert_eq(out[3].to_int(), 0x03)
  assert_eq(out[4].to_int(), 0x07)
  assert_eq(out[5].to_int(), 0xA1)
  assert_eq(out[6].to_int(), 0x20)
}

///|
test "time signature meta event uses log2 of the denominator" {
  let out : Array[Byte] = []
  // 6/8 with 24 metronome clicks per beat and 8 notated-32nds per beat.
  write_meta_time_signature(
    out,
    delta=0,
    numerator=6,
    denominator=8,
    metronome=24,
    notated32=8,
  )
  // delta(1) + FF + 58 + 04 + 4 data bytes = 8
  assert_eq(out.length(), 8)
  assert_eq(out[0].to_int(), 0x00)
  assert_eq(out[1].to_int(), 0xFF)
  assert_eq(out[2].to_int(), 0x58)
  assert_eq(out[3].to_int(), 0x04)
  assert_eq(out[4].to_int(), 6) // numerator
  assert_eq(out[5].to_int(), 3) // log2(8)
  assert_eq(out[6].to_int(), 24)
  assert_eq(out[7].to_int(), 8)
}

///|
test "end-of-track meta event" {
  let out : Array[Byte] = []
  write_meta_end_of_track(out, delta=0)
  assert_eq(out.length(), 4)
  assert_eq(out[0].to_int(), 0x00)
  assert_eq(out[1].to_int(), 0xFF)
  assert_eq(out[2].to_int(), 0x2F)
  assert_eq(out[3].to_int(), 0x00)
}

///|
test "note on / note off events for middle C on channel 0" {
  let out : Array[Byte] = []
  write_note_on(out, delta=0, channel=0, note=60, velocity=100)
  // delta(1) + status(1) + note(1) + velocity(1) = 4
  assert_eq(out.length(), 4)
  assert_eq(out[0].to_int(), 0x00)
  assert_eq(out[1].to_int(), 0x90) // 9 = note on, channel 0
  assert_eq(out[2].to_int(), 60)
  assert_eq(out[3].to_int(), 100)
  let off : Array[Byte] = []
  write_note_off(off, delta=480, channel=0, note=60, velocity=64)
  // 480 encodes as 0x83 0x60 in VLQ.
  assert_eq(off[0].to_int(), 0x83)
  assert_eq(off[1].to_int(), 0x60)
  assert_eq(off[2].to_int(), 0x80) // 8 = note off, channel 0
  assert_eq(off[3].to_int(), 60)
  assert_eq(off[4].to_int(), 64)
}

///|
test "pitch bend encodes both 7-bit halves" {
  let out : Array[Byte] = []
  // Centre is 8192 = 0x2000 — LSB 0x00, MSB 0x40.
  write_pitch_bend(out, delta=0, channel=0, value=8192)
  assert_eq(out.length(), 4)
  assert_eq(out[0].to_int(), 0x00)
  assert_eq(out[1].to_int(), 0xE0)
  assert_eq(out[2].to_int(), 0x00) // lsb
  assert_eq(out[3].to_int(), 0x40) // msb
}

///|
test "CC and program change" {
  let cc : Array[Byte] = []
  write_cc(cc, delta=0, channel=0, cc=74, value=64)
  assert_eq(cc[1].to_int(), 0xB0)
  assert_eq(cc[2].to_int(), 74)
  assert_eq(cc[3].to_int(), 64)
  let pc : Array[Byte] = []
  write_program_change(pc, delta=0, channel=0, program=42)
  assert_eq(pc[1].to_int(), 0xC0)
  assert_eq(pc[2].to_int(), 42)
}

// ----------------------------------------------------------------------
// End-to-end: render() produces a valid SMF file structure
// ----------------------------------------------------------------------

///|
test "render() emits a well-formed SMF with tempo + time sig + EOT" {
  let bytes = render_to_midi(@eval.Placeholder)
  // Header (14) + MTrk magic (4) + length (4) + track contents.
  assert_true(bytes.length() > 14 + 4 + 4)
  // SMF magic.
  assert_eq(bytes[0].to_int(), 0x4D) // 'M'
  assert_eq(bytes[1].to_int(), 0x54) // 'T'
  assert_eq(bytes[2].to_int(), 0x68) // 'h'
  assert_eq(bytes[3].to_int(), 0x64) // 'd'
  // MTrk magic at offset 14.
  assert_eq(bytes[14].to_int(), 0x4D) // 'M'
  assert_eq(bytes[15].to_int(), 0x54) // 'T'
  assert_eq(bytes[16].to_int(), 0x72) // 'r'
  assert_eq(bytes[17].to_int(), 0x6B) // 'k'
  // Last three bytes are EOT: FF 2F 00.
  let len = bytes.length()
  assert_eq(bytes[len - 3].to_int(), 0xFF)
  assert_eq(bytes[len - 2].to_int(), 0x2F)
  assert_eq(bytes[len - 1].to_int(), 0x00)
}

///|
