# Vapor Moon playground

`App.mbtv` is the playground view. It is authored as a Vapor Moon Single
File Component and calls the MoonBit bridge functions in
`playground.mbt`.

The bridge exposes the operations the UI needs:

- `diagnose(source) -> Array[String]`
- `format(source) -> String`
- `run(source) -> String`
- `render(source) -> Array[Byte]`

Build the component snapshot from the workspace root:

```bash
vp run studio:build
```
