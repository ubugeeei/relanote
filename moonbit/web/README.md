# Vapor Moon playground (skeleton)

This directory will house the [Vapor Moon](https://github.com/moonbitlang/vapor-moon)
rewrite of the relanote playground that currently lives in `../../web/`.

For now the package exposes the JS-callable bridge functions Vapor Moon
components will need to wire up:

- `diagnose(source) -> Array[String]` — parser diagnostics
- `format(source) -> String` — pretty-printed source
- `render(source) -> Array[Byte]` — MIDI bytes from the evaluator + renderer

All three are wired against the MoonBit pipeline ports, which are
themselves skeletons today. As each upstream package's walker / writer
lands, these bridge functions get real behaviour without changes to the
Vapor Moon component layer.

The actual UI components (Monaco wrapper, staff preview, transport
controls) land alongside the upstream walker work — tracked in #14.
