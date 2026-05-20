# FAQ

[[toc]]

## What is relanote *actually* good for?

Code that produces music. The killer feature is that the *shape* of a
piece — the melodic contour, the rhythmic feel, the harmonic
relationships — survives transposition, mode swaps, tempo changes,
and instrument changes. You write the *idea*; the runtime turns it
into pitches.

It's not a replacement for a DAW. It's the layer *above* a DAW: the
file you commit, branch and review while the DAW stays a renderer.

## Why "relative" everywhere?

Because that's how music is described informally. "The third of the
chord", "two beats", "double tempo", "drop a fifth" — every one of
these is *relative*. Notation tied to absolute frequencies and
absolute durations forces you to recompute every time something
changes. relanote keeps the relative description and resolves it
when the runtime asks for sound.

## Can I bend pitches between the 12-tone slots?

Yes, three ways:

- Per-note: `M3 -13.7c`, `<3 +5c>`, `C4 +50c`.
- Per-passage: `melody |> in_tuning JustIntonation`.
- Globally: `set tuning = EDO24` and every `<n>` resolves through 24-EDO.

See [Microtones](/guide/microtones).

## Can I write hip-hop / Flying Lotus / Floating Points-style stuff?

Yes — that was a deliberate goal. The stdlib ships granular
oscillators, FM operators, wavetables, modulation matrices, swing /
Dilla / shuffle grooves, polyrhythm via `over`, dub-style send
busses, sidechain. See:

- [`showcase_floating_points.rela`](https://github.com/ubugeeei/relanote/blob/main/examples/showcases/showcase_floating_points.rela)
- [`showcase_flying_lotus.rela`](https://github.com/ubugeeei/relanote/blob/main/examples/showcases/showcase_flying_lotus.rela)
- [`showcase_dub.rela`](https://github.com/ubugeeei/relanote/blob/main/examples/showcases/showcase_dub.rela)
- [Presets reference](/guide/presets)

## How is rhythm not just "a bunch of durations"?

A block divides its slot equally among the notes inside it. The slot
defaults to one beat; you can pin it with `:n`. Tempo changes the
*length* of the slot. Density changes what's *inside* it. That
separation is what makes `++` so cheap: gluing two blocks of
different densities is one operator, not a duration-recomputation
exercise.

For grooves and polyrhythm, see [Rhythm and
polyrhythm](/guide/rhythm).

## Is the type checker actually useful?

Yes. Common mistakes that catch at compile time:

- Adding a `Scale` to an `Interval`.
- Applying a transformation that expects a `Block` to a `Synth`.
- Calling a function with the wrong number of arguments.
- Forgetting to handle a `match` arm.

Hindley-Milner inference means you don't have to annotate every
binding — annotations are useful at API boundaries and for
documentation.

## Can I share data with a DAW?

`relanote render <file>.rela -o <file>.mid` produces a standard MIDI
file you can import into any DAW for mixing, mastering and
instrument replacement. The MIDI mapping covers velocity, pitch
bend (for microtones), and the common CC numbers for cutoff /
resonance / envelope.

In the other direction: a Reaper / Logic / Ableton project can
*launch* `relanote render` as a build step and reimport the MIDI
when the source changes.

## How do I install the toolchain?

The Nix flake gives you everything:

```bash
nix develop
pnpm install
pnpm setup
```

If you don't have Nix, see the [Installation
guide](/guide/installation) for the per-tool manual setup.

## Where does the implementation live?

The implementation lives under `src/`. Each package owns one part of
the language pipeline, from source handling and tokenization through
type-checking, evaluation, formatting, rendering, and editor support.

Status:

- `core`, `lexer`, `ast`, `stdlib` — foundational packages.
- `types`, `parser`, `resolver`, `eval`, `format`, `render`, `lsp`,
  `cmd`, `studio` — user-facing pipeline and tooling packages.

See the package map in the
[main README](https://github.com/ubugeeei/relanote/blob/main/README.md).

## Why MoonBit?

Three reasons that compound:

- **Modern type system + value semantics** for small compiler passes and
  musical transformations.
- **A single source tree** for the command-line tool, editor bridge, and
  playground-facing functions.
- **Fast compiles, small binaries.** The whole workspace builds in
  seconds; the playground bundle is small.

## Can I contribute a preset?

Yes — drop a new `.rela` file into
[`src/stdlib/prelude/`](https://github.com/ubugeeei/relanote/tree/main/src/stdlib/prelude),
run `pnpm stdlib:regen`, commit the regenerated `prelude_data_*.mbt`
files.
That's the whole flow.

## What if I want a feature that isn't in the language?

Open an issue with a short example showing what you'd write. The
language surface is still evolving — the recent sound-design wave
(microtones, grooves, polyrhythm, mixing) started as a feature
request.

## Is this fast enough to be useful?

For composing: yes. The compiler runs in single-digit milliseconds
for a typical piece, the LSP responds in real time, and MIDI render
is offline (no realtime constraint).

For *playback* — that's the audio engine's problem. The CLI's
internal renderer is fine for previews; for production you usually
want to render to MIDI and drive a real synth or sampler.
