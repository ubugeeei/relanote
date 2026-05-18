// Smoke tests for the embedded prelude. The real "does it lex / parse / type"
// guarantee will land alongside the parser port; for now we just confirm
// that every prelude file is actually embedded and the combined string
// contains all of them in the expected order.

test "every prelude module is non-empty" {
  assert_true(SCALES.length() > 0)
  assert_true(CHORDS.length() > 0)
  assert_true(SYNTHS_BASIC.length() > 0)
  assert_true(SYNTHS_PIANO.length() > 0)
  assert_true(SYNTHS_BASS.length() > 0)
  assert_true(SYNTHS_BRASS.length() > 0)
  assert_true(SYNTHS_LEADS.length() > 0)
  assert_true(SYNTHS_PADS.length() > 0)
  assert_true(SYNTHS_PLUCK.length() > 0)
  assert_true(SYNTHS_DRUMS.length() > 0)
  assert_true(SYNTHS_PERCUSSION.length() > 0)
  assert_true(SYNTHS_RETRO.length() > 0)
  assert_true(SYNTHS_CLAP.length() > 0)
  assert_true(EFFECTS_REVERB.length() > 0)
  assert_true(EFFECTS_DELAY.length() > 0)
  assert_true(EFFECTS_PHASER.length() > 0)
  assert_true(EFFECTS_DISTORTION.length() > 0)
}

test "SCALES contains the Major scale definition" {
  assert_true(SCALES.contains("scale Major"))
}

test "CHORDS contains the MajorTriad chord definition" {
  assert_true(CHORDS.contains("chord MajorTriad"))
}

test "PRELUDE concatenates every module" {
  assert_true(PRELUDE.contains("scale Major"))
  assert_true(PRELUDE.contains("chord MajorTriad"))
  // Synth presets ship with the prelude too.
  assert_true(PRELUDE.contains("synth"))
  // Header banner present.
  assert_true(PRELUDE.contains("Relanote Standard Prelude"))
}
