# Presets

relanote ships a starter library of synths, effects, tunings and
grooves under
[`moonbit/relanote_stdlib/prelude/`](https://github.com/ubugeeei/relanote/tree/main/moonbit/relanote_stdlib/prelude).
They're plain `.rela` source — exactly what you'd write yourself —
embedded into the runtime via [`prelude_data.mbt`](https://github.com/ubugeeei/relanote/blob/main/moonbit/relanote_stdlib/prelude_data.mbt).

That means every preset is a reference example *and* a working
patch. Read [`pads_floating.rela`](https://github.com/ubugeeei/relanote/blob/main/moonbit/relanote_stdlib/prelude/pads_floating.rela)
to see how a Floating Points-style lush pad is built; pull a copy into
your project, change three numbers, get something new.

## Synthesis presets

| Module | Vibe | Headline patches |
| --- | --- | --- |
| `synths_basic.rela` | Building blocks — saws, squares, sines | `Lead`, `SoftPad`, `FatBass`, `Pluck` |
| `synths_fm.rela` | Yamaha-DX-style FM | `FMBell`, `FMRhodes`, `FMKalimba`, `FMBrass`, `FMBass`, `FMPluck` |
| `synths_wavetable.rela` | Modern wavetable | `WaveVapor`, `WaveDriftPad`, `WaveFormant`, `WaveBellPad`, `WaveAcid`, `WaveSupersaw` |
| `synths_granular.rela` | Granular textures | `GrainDrift`, `GrainVocal`, `GrainShimmer`, `GrainSlowmo`, `GrainStutter`, `GrainReverse` |
| `synths_modular.rela` | Analog modular palette (Caribou / Bicep / Floating Points) | `ModularEnsemble`, `ModularBreath`, `ModularLead`, `ModularBass`, `ModularSH`, `ModularString` |
| `synths_piano.rela` | Acoustic piano variants | `Piano`, `EPiano`, `Rhodes` |
| `synths_keys.rela` | Vintage electric pianos | `KeysRhodes`, `KeysWurly`, `KeysClav`, `KeysCP70`, `KeysOrgan`, `KeysUpright` |
| `synths_bass.rela` | Subs and synth bass | `Sub`, `AcidBass`, `WarmBass` |
| `bass_funk.rela` | Funk / dub / hip-hop bass | `BassRound`, `BassSlap`, `BassMoog`, `BassDubSub`, `BassReese`, `BassWobble`, `BassUpright` |
| `synths_brass.rela` | Brass impressions | `Brass`, `Horns`, `Trumpet` |
| `synths_leads.rela` | Lead voices | `Lead`, `Saw`, `Pulse` |
| `synths_pads.rela` | Generic pads | `WarmPad`, `Strings`, `Choir` |
| `pads_floating.rela` | Floating Points / Caribou-style lush pads | `FloatingBloom`, `FloatingCrush`, `FloatingChoir`, `FloatingGlass`, `FloatingDrone`, `FloatingDrift` |
| `synths_pluck.rela` | Plucked / percussive | `Pluck`, `Mute`, `Pizzicato` |
| `synths_drums.rela` | Drum kits — kick / snare / hat | `Kick`, `Snare`, `HiHat`, `Clap` |
| `drums_lofi.rela` | Flying Lotus-style dusty drums | `LofiKick`, `LofiSnare`, `LofiHat`, `LofiOpenHat`, `LofiRim`, `LofiBreak`, `LofiSub` |
| `synths_percussion.rela` | Mallet and tuned percussion | `Marimba`, `Vibraphone`, `Glock` |
| `synths_retro.rela` | 8-bit / chiptune | `Chiptune`, `NES`, `GameBoy` |
| `synths_clap.rela` | Hand-clap variants | `Clap`, `LoFiClap` |

## Effects

| Module | What's in it |
| --- | --- |
| `effects_reverb.rela` | `Hall`, `Plate`, `Room`, `Spring` |
| `effects_delay.rela` | `PingPong`, `Tape`, `Stereo`, `Slap` |
| `effects_phaser.rela` | `Phaser`, `Flanger`, `Chorus` |
| `effects_distortion.rela` | `Drive`, `Fuzz`, `BitCrush` |
| `effects_dub.rela` | Dub / spacey: `DubDelay`, `DottedDelay`, `TapeEcho`, `PlateLarge`, `SpringBright`, `DubRoom`, `PhaserSlow`, `Freeze` |
| `effects_mix.rela` | Mix stage: `BusGlue`, `DrumBus`, `ParallelSmash`, `MasterChain`, `DeEss`, `Tape`, `Drive`, `Vinyl` |

## Tunings

[`tunings.rela`](https://github.com/ubugeeei/relanote/blob/main/moonbit/relanote_stdlib/prelude/tunings.rela)
ships seven systems:

| Tuning | Description |
| --- | --- |
| `EDO24` | 24-tone equal temperament (quarter tones). |
| `EDO31` | 31-EDO — Fokker's tuning, good meantone approximation. |
| `EDO53` | 53-EDO — near-pure Pythagorean. |
| `JustIntonation` | 5-limit JI in C major. |
| `Pythagorean` | Stacked perfect fifths. |
| `WerckmeisterIII` | Bach-era well temperament. |
| `BohlenPierce` | 13-step equal division of 3:1. |

## Grooves

[`grooves.rela`](https://github.com/ubugeeei/relanote/blob/main/moonbit/relanote_stdlib/prelude/grooves.rela)
ships eight feels:

| Groove | Feel |
| --- | --- |
| `Straight` | Perfectly quantised. |
| `Swing67` | Classic 8th-note swing. |
| `Swing75` | Hard 16th-note swing. |
| `Dilla` | J Dilla's drunken hip-hop. |
| `Bossa` | Bossa nova pushed downbeats. |
| `Shuffle` | Hat-hat-snare boogie. |
| `HalfTimeLazy` | Lazy half-time crawl. |
| `Drunken` | Every slot jitters. |

## Rolling your own

Every preset above is a plain `.rela` declaration. To extend the
library, drop a new file into
`moonbit/relanote_stdlib/prelude/` and rerun the embed:

```bash
pnpm stdlib:regen
```

The generator (`moonbit/scripts/gen_stdlib.sh`) reads every `.rela`
under `prelude/`, emits a `pub const NAME : String = #|...` block per
file into `prelude_data.mbt`, and `prelude.mbt` concatenates the lot
into the combined `PRELUDE` string the runtime loads at startup.

If you add a new category, also extend `PRELUDE`'s ordering in
`prelude.mbt` so it ends up in the right place (theory before
synthesis before effects).
