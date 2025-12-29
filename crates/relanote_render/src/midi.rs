//! MIDI rendering

use midly::{Format, Header, MidiMessage, Smf, Timing, Track, TrackEvent, TrackEventKind};
use relanote_ast::Articulation;
use relanote_eval::value::{
    BlockValue, IntervalValue, PartValue, SlotValue, SongValue, SynthValue,
};

// MIDI CC numbers for synth parameters
const CC_MODULATION: u8 = 1; // Vibrato/Modulation
const CC_RESONANCE: u8 = 71; // Resonance (Sound Controller 2)
const CC_RELEASE: u8 = 72; // Release Time (Sound Controller 3)
const CC_ATTACK: u8 = 73; // Attack Time (Sound Controller 4)
const CC_CUTOFF: u8 = 74; // Brightness/Cutoff (Sound Controller 5)
const CC_DECAY: u8 = 75; // Decay Time (Sound Controller 6)

/// MIDI renderer configuration
pub struct MidiConfig {
    /// Ticks per quarter note
    pub ticks_per_beat: u16,
    /// Base tempo in BPM
    pub tempo: u32,
    /// Base key (MIDI note number, 60 = C4)
    pub base_note: u8,
    /// Pitch bend range in semitones (default: 2)
    pub pitch_bend_range: f64,
}

impl Default for MidiConfig {
    fn default() -> Self {
        Self {
            ticks_per_beat: 480,
            tempo: 120,
            base_note: 60, // C4 (middle C)
            pitch_bend_range: 2.0,
        }
    }
}

/// Calculate MIDI note and pitch bend from cents
/// Returns (midi_note, pitch_bend) where pitch_bend is 0-16383 (center: 8192)
fn cents_to_midi(base_note: u8, cents: f64, pitch_bend_range: f64) -> (u8, u16) {
    let semitones = cents / 100.0;
    let midi_note_float = base_note as f64 + semitones;
    let midi_note = midi_note_float.round() as i32;
    let fractional_semitones = midi_note_float - midi_note as f64;

    // Clamp MIDI note to valid range
    let midi_note = midi_note.clamp(0, 127) as u8;

    // Calculate pitch bend (14-bit value, center at 8192)
    // pitch_bend_range is the range in semitones for full bend
    let bend_ratio = fractional_semitones / pitch_bend_range;
    let pitch_bend = ((bend_ratio * 8192.0) + 8192.0).clamp(0.0, 16383.0) as u16;

    (midi_note, pitch_bend)
}

/// Convert filter cutoff frequency (Hz) to MIDI CC value (0-127)
/// Uses logarithmic scaling: 20Hz -> 0, ~5000Hz -> 64, 20000Hz -> 127
fn cutoff_to_cc(cutoff_hz: f64) -> u8 {
    const MIN_FREQ: f64 = 20.0;
    const MAX_FREQ: f64 = 20000.0;

    let clamped = cutoff_hz.clamp(MIN_FREQ, MAX_FREQ);
    let log_min = MIN_FREQ.ln();
    let log_max = MAX_FREQ.ln();
    let log_val = clamped.ln();

    let normalized = (log_val - log_min) / (log_max - log_min);
    (normalized * 127.0).round() as u8
}

/// Convert resonance (0.0-1.0) to MIDI CC value (0-127)
fn resonance_to_cc(resonance: f64) -> u8 {
    (resonance.clamp(0.0, 1.0) * 127.0).round() as u8
}

/// Convert ADSR time (seconds) to MIDI CC value (0-127)
/// Uses logarithmic scaling: 0.001s -> 0, ~0.5s -> 64, 4s -> 127
fn adsr_time_to_cc(time_seconds: f64) -> u8 {
    const MIN_TIME: f64 = 0.001;
    const MAX_TIME: f64 = 4.0;

    let clamped = time_seconds.clamp(MIN_TIME, MAX_TIME);
    let log_min = MIN_TIME.ln();
    let log_max = MAX_TIME.ln();
    let log_val = clamped.ln();

    let normalized = (log_val - log_min) / (log_max - log_min);
    (normalized * 127.0).round() as u8
}

/// Generate MIDI CC events for synth parameters
fn synth_to_cc_events(synth: &SynthValue, channel: u8) -> Vec<TrackEvent<'static>> {
    let mut events = Vec::new();

    // Filter cutoff and resonance
    if let Some(filter) = &synth.filter {
        events.push(TrackEvent {
            delta: 0.into(),
            kind: TrackEventKind::Midi {
                channel: channel.into(),
                message: MidiMessage::Controller {
                    controller: CC_CUTOFF.into(),
                    value: cutoff_to_cc(filter.cutoff).into(),
                },
            },
        });

        events.push(TrackEvent {
            delta: 0.into(),
            kind: TrackEventKind::Midi {
                channel: channel.into(),
                message: MidiMessage::Controller {
                    controller: CC_RESONANCE.into(),
                    value: resonance_to_cc(filter.resonance).into(),
                },
            },
        });
    }

    // ADSR envelope
    events.push(TrackEvent {
        delta: 0.into(),
        kind: TrackEventKind::Midi {
            channel: channel.into(),
            message: MidiMessage::Controller {
                controller: CC_ATTACK.into(),
                value: adsr_time_to_cc(synth.envelope.attack).into(),
            },
        },
    });

    events.push(TrackEvent {
        delta: 0.into(),
        kind: TrackEventKind::Midi {
            channel: channel.into(),
            message: MidiMessage::Controller {
                controller: CC_DECAY.into(),
                value: adsr_time_to_cc(synth.envelope.decay).into(),
            },
        },
    });

    events.push(TrackEvent {
        delta: 0.into(),
        kind: TrackEventKind::Midi {
            channel: channel.into(),
            message: MidiMessage::Controller {
                controller: CC_RELEASE.into(),
                value: adsr_time_to_cc(synth.envelope.release).into(),
            },
        },
    });

    // Detune as modulation (if significant)
    if synth.detune_cents.abs() > 0.1 {
        // Map detune (-100 to +100 cents typical) to modulation depth
        let mod_value = ((synth.detune_cents.abs() / 100.0) * 64.0).min(127.0) as u8;
        events.push(TrackEvent {
            delta: 0.into(),
            kind: TrackEventKind::Midi {
                channel: channel.into(),
                message: MidiMessage::Controller {
                    controller: CC_MODULATION.into(),
                    value: mod_value.into(),
                },
            },
        });
    }

    events
}

/// MIDI renderer
pub struct MidiRenderer {
    config: MidiConfig,
}

impl MidiRenderer {
    pub fn new(config: MidiConfig) -> Self {
        Self { config }
    }

    /// Render a song to MIDI
    pub fn render(&self, song: &SongValue) -> Vec<u8> {
        let mut tracks = Vec::new();

        // Meta track (tempo)
        let mut meta_track = Track::new();
        let tempo_microseconds = 60_000_000 / self.config.tempo;
        meta_track.push(TrackEvent {
            delta: 0.into(),
            kind: TrackEventKind::Meta(midly::MetaMessage::Tempo(tempo_microseconds.into())),
        });
        meta_track.push(TrackEvent {
            delta: 0.into(),
            kind: TrackEventKind::Meta(midly::MetaMessage::EndOfTrack),
        });
        tracks.push(meta_track);

        // Render each section
        for section in &song.sections {
            for (i, part) in section.parts.iter().enumerate() {
                let track = self.render_part(part, i as u8);
                tracks.push(track);
            }
        }

        // Create MIDI file
        let smf = Smf {
            header: Header {
                format: Format::Parallel,
                timing: Timing::Metrical(self.config.ticks_per_beat.into()),
            },
            tracks,
        };

        let mut buffer = Vec::new();
        smf.write_std(&mut buffer).unwrap();
        buffer
    }

    fn render_part(&self, part: &PartValue, channel: u8) -> Track<'static> {
        let mut track = Track::new();
        let mut time: u32 = 0;

        // Track name
        track.push(TrackEvent {
            delta: 0.into(),
            kind: TrackEventKind::Meta(midly::MetaMessage::TrackName(
                part.instrument.as_bytes().to_vec().leak(),
            )),
        });

        // Set volume level (CC#7 - Channel Volume)
        if let Some(volume_level) = part.volume_level {
            let cc_value = (volume_level * 127.0).round() as u8;
            track.push(TrackEvent {
                delta: 0.into(),
                kind: TrackEventKind::Midi {
                    channel: channel.into(),
                    message: MidiMessage::Controller {
                        controller: 7.into(), // CC#7 = Channel Volume
                        value: cc_value.into(),
                    },
                },
            });
        }

        // Set reverb level (CC#91 - Effects 1 Depth / Reverb Send Level)
        if let Some(reverb_level) = part.reverb_level {
            let cc_value = (reverb_level * 127.0).round() as u8;
            track.push(TrackEvent {
                delta: 0.into(),
                kind: TrackEventKind::Midi {
                    channel: channel.into(),
                    message: MidiMessage::Controller {
                        controller: 91.into(), // CC#91 = Reverb Send Level
                        value: cc_value.into(),
                    },
                },
            });
        }

        // Set synth parameters as MIDI CC messages
        if let Some(synth) = &part.synth {
            for event in synth_to_cc_events(synth, channel) {
                track.push(event);
            }
        }

        // Render blocks with volume scaling
        let velocity_scale = part.volume_level.unwrap_or(1.0);
        for block in &part.blocks {
            time = self.render_block(&mut track, block, time, channel, velocity_scale);
        }

        // End of track
        track.push(TrackEvent {
            delta: 0.into(),
            kind: TrackEventKind::Meta(midly::MetaMessage::EndOfTrack),
        });

        track
    }

    fn render_block(
        &self,
        track: &mut Track<'static>,
        block: &BlockValue,
        mut time: u32,
        channel: u8,
        velocity_scale: f64,
    ) -> u32 {
        // Default slot duration (relative rhythm: equal share of block duration)
        let slot_count = block.slots.len();
        let default_slot_duration = if slot_count > 0 {
            (block.beats * self.config.ticks_per_beat as f64).round() as u32 / slot_count as u32
        } else {
            0
        };

        for slot in &block.slots {
            // Use explicit duration if set, otherwise use default (relative rhythm)
            let slot_duration = slot
                .duration_beats()
                .map(|beats| (beats * self.config.ticks_per_beat as f64).round() as u32)
                .unwrap_or(default_slot_duration);

            match slot {
                SlotValue::Note {
                    interval,
                    articulations,
                    ..
                } => {
                    time += self.render_note(
                        track,
                        interval,
                        articulations,
                        slot_duration,
                        channel,
                        velocity_scale,
                    );
                }

                SlotValue::Rest { .. } => {
                    time += slot_duration;
                }

                SlotValue::Chord {
                    intervals,
                    articulations,
                    ..
                } => {
                    time += self.render_chord(
                        track,
                        intervals,
                        articulations,
                        slot_duration,
                        channel,
                        velocity_scale,
                    );
                }

                SlotValue::Tuplet {
                    slots,
                    target_beats,
                } => {
                    // Tuplets use their own duration calculation
                    let tuplet_duration =
                        (*target_beats as u32) * self.config.ticks_per_beat as u32;
                    let tuplet_slot_dur = tuplet_duration / slots.len().max(1) as u32;

                    for inner_slot in slots {
                        match inner_slot {
                            SlotValue::Note {
                                interval,
                                articulations,
                                ..
                            } => {
                                time += self.render_note(
                                    track,
                                    interval,
                                    articulations,
                                    tuplet_slot_dur,
                                    channel,
                                    velocity_scale,
                                );
                            }
                            SlotValue::Rest { .. } => {
                                time += tuplet_slot_dur;
                            }
                            SlotValue::Chord {
                                intervals,
                                articulations,
                                ..
                            } => {
                                time += self.render_chord(
                                    track,
                                    intervals,
                                    articulations,
                                    tuplet_slot_dur,
                                    channel,
                                    velocity_scale,
                                );
                            }
                            _ => {}
                        }
                    }
                }
            }
        }

        time
    }

    /// Render a single note with optional pitch bend for microtones
    fn render_note(
        &self,
        track: &mut Track<'static>,
        interval: &IntervalValue,
        articulations: &[Articulation],
        duration: u32,
        channel: u8,
        velocity_scale: f64,
    ) -> u32 {
        let (note, pitch_bend) = cents_to_midi(
            self.config.base_note,
            interval.cents,
            self.config.pitch_bend_range,
        );
        let velocity = ((100.0 * velocity_scale).round() as u8).clamp(1, 127);

        // Apply staccato: shorten note to 50% of duration
        let is_staccato = articulations.contains(&Articulation::Staccato);
        let note_duration = if is_staccato { duration / 2 } else { duration };
        let rest_duration = duration - note_duration;

        // Set pitch bend if not centered (for microtones)
        if pitch_bend != 8192 {
            track.push(TrackEvent {
                delta: 0.into(),
                kind: TrackEventKind::Midi {
                    channel: channel.into(),
                    message: MidiMessage::PitchBend {
                        bend: midly::PitchBend(pitch_bend.into()),
                    },
                },
            });
        }

        // Note on
        track.push(TrackEvent {
            delta: 0.into(),
            kind: TrackEventKind::Midi {
                channel: channel.into(),
                message: MidiMessage::NoteOn {
                    key: note.into(),
                    vel: velocity.into(),
                },
            },
        });

        // Note off (after note_duration, which may be shorter for staccato)
        track.push(TrackEvent {
            delta: note_duration.into(),
            kind: TrackEventKind::Midi {
                channel: channel.into(),
                message: MidiMessage::NoteOff {
                    key: note.into(),
                    vel: 0.into(),
                },
            },
        });

        // Reset pitch bend or add rest gap for staccato
        if pitch_bend != 8192 || is_staccato {
            track.push(TrackEvent {
                delta: rest_duration.into(),
                kind: TrackEventKind::Midi {
                    channel: channel.into(),
                    message: MidiMessage::PitchBend {
                        bend: midly::PitchBend(8192u16.into()),
                    },
                },
            });
        }

        duration
    }

    /// Render a chord (multiple simultaneous notes)
    fn render_chord(
        &self,
        track: &mut Track<'static>,
        intervals: &[IntervalValue],
        articulations: &[Articulation],
        duration: u32,
        channel: u8,
        velocity_scale: f64,
    ) -> u32 {
        let velocity = ((100.0 * velocity_scale).round() as u8).clamp(1, 127);

        // Apply staccato: shorten chord to 50% of duration
        let is_staccato = articulations.contains(&Articulation::Staccato);
        let note_duration = if is_staccato { duration / 2 } else { duration };
        let rest_duration = duration - note_duration;

        // For chords with microtones, we can only apply pitch bend to all notes equally
        // (MIDI limitation: one pitch bend per channel)
        // For simplicity, we use the pitch bend of the first note if it has microtones
        let first_bend = if let Some(first) = intervals.first() {
            let (_, bend) = cents_to_midi(
                self.config.base_note,
                first.cents,
                self.config.pitch_bend_range,
            );
            if bend != 8192 {
                track.push(TrackEvent {
                    delta: 0.into(),
                    kind: TrackEventKind::Midi {
                        channel: channel.into(),
                        message: MidiMessage::PitchBend {
                            bend: midly::PitchBend(bend.into()),
                        },
                    },
                });
            }
            bend
        } else {
            8192
        };

        // All notes on simultaneously
        for interval in intervals.iter() {
            let (note, _) = cents_to_midi(
                self.config.base_note,
                interval.cents,
                self.config.pitch_bend_range,
            );
            track.push(TrackEvent {
                delta: 0.into(),
                kind: TrackEventKind::Midi {
                    channel: channel.into(),
                    message: MidiMessage::NoteOn {
                        key: note.into(),
                        vel: velocity.into(),
                    },
                },
            });
        }

        // All notes off (after note_duration, which may be shorter for staccato)
        for (i, interval) in intervals.iter().enumerate() {
            let (note, _) = cents_to_midi(
                self.config.base_note,
                interval.cents,
                self.config.pitch_bend_range,
            );
            let delta = if i == 0 { note_duration } else { 0 };
            track.push(TrackEvent {
                delta: delta.into(),
                kind: TrackEventKind::Midi {
                    channel: channel.into(),
                    message: MidiMessage::NoteOff {
                        key: note.into(),
                        vel: 0.into(),
                    },
                },
            });
        }

        // Reset pitch bend or add rest gap for staccato
        if first_bend != 8192 || is_staccato {
            track.push(TrackEvent {
                delta: rest_duration.into(),
                kind: TrackEventKind::Midi {
                    channel: channel.into(),
                    message: MidiMessage::PitchBend {
                        bend: midly::PitchBend(8192u16.into()),
                    },
                },
            });
        }

        duration
    }
}

/// Render a song value to MIDI bytes
pub fn render_to_midi(song: &SongValue) -> Vec<u8> {
    let renderer = MidiRenderer::new(MidiConfig::default());
    renderer.render(song)
}
