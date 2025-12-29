//! MIDI rendering

use midly::{Format, Header, MidiMessage, Smf, Timing, Track, TrackEvent, TrackEventKind};
use relanote_eval::value::{BlockValue, PartValue, SlotValue, SongValue};

/// MIDI renderer configuration
pub struct MidiConfig {
    /// Ticks per quarter note
    pub ticks_per_beat: u16,
    /// Base tempo in BPM
    pub tempo: u32,
    /// Base key (MIDI note number, 60 = C4)
    pub base_note: u8,
}

impl Default for MidiConfig {
    fn default() -> Self {
        Self {
            ticks_per_beat: 480,
            tempo: 120,
            base_note: 60, // Middle C
        }
    }
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
            kind: TrackEventKind::Meta(midly::MetaMessage::Tempo(
                tempo_microseconds.into(),
            )),
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

        // Render blocks
        for block in &part.blocks {
            time = self.render_block(&mut track, block, time, channel);
        }

        // End of track
        track.push(TrackEvent {
            delta: 0.into(),
            kind: TrackEventKind::Meta(midly::MetaMessage::EndOfTrack),
        });

        track
    }

    fn render_block(&self, track: &mut Track<'static>, block: &BlockValue, mut time: u32, channel: u8) -> u32 {
        let slot_duration = self.config.ticks_per_beat as u32;

        for slot in &block.slots {
            match slot {
                SlotValue::Note { interval, .. } => {
                    let note = (self.config.base_note as i32 + interval.semitones) as u8;
                    let velocity = 100;

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

                    // Note off
                    track.push(TrackEvent {
                        delta: slot_duration.into(),
                        kind: TrackEventKind::Midi {
                            channel: channel.into(),
                            message: MidiMessage::NoteOff {
                                key: note.into(),
                                vel: 0.into(),
                            },
                        },
                    });

                    time += slot_duration;
                }

                SlotValue::Rest => {
                    time += slot_duration;
                }

                SlotValue::Chord { intervals, .. } => {
                    let velocity = 100;

                    // All notes on simultaneously
                    for interval in intervals.iter() {
                        let note = (self.config.base_note as i32 + interval.semitones) as u8;
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

                    // All notes off
                    for (i, interval) in intervals.iter().enumerate() {
                        let note = (self.config.base_note as i32 + interval.semitones) as u8;
                        let delta = if i == 0 { slot_duration } else { 0 };
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

                    time += slot_duration;
                }

                SlotValue::Tuplet { slots, target_beats } => {
                    let tuplet_duration = (*target_beats as u32) * self.config.ticks_per_beat as u32;
                    let slot_dur = tuplet_duration / slots.len() as u32;

                    for inner_slot in slots {
                        if let SlotValue::Note { interval, .. } = inner_slot {
                            let note = (self.config.base_note as i32 + interval.semitones) as u8;
                            let velocity = 100;

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

                            track.push(TrackEvent {
                                delta: slot_dur.into(),
                                kind: TrackEventKind::Midi {
                                    channel: channel.into(),
                                    message: MidiMessage::NoteOff {
                                        key: note.into(),
                                        vel: 0.into(),
                                    },
                                },
                            });

                            time += slot_dur;
                        } else if let SlotValue::Rest = inner_slot {
                            time += slot_dur;
                        }
                    }
                }
            }
        }

        time
    }
}

/// Render a song value to MIDI bytes
pub fn render_to_midi(song: &SongValue) -> Vec<u8> {
    let renderer = MidiRenderer::new(MidiConfig::default());
    renderer.render(song)
}
