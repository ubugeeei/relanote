# Installation

## With Nix

The repo ships a Nix flake for the local helper tools used by root
tasks and deployment.

```bash
git clone https://github.com/ubugeeei/relanote.git
cd relanote
nix develop
```

MoonBit is installed with the upstream compiler installer:

```bash
curl -fsSL https://cli.moonbitlang.com/install/unix.sh | bash
export PATH="$HOME/.moon/bin:$PATH"
```

The dev shell adds `~/.moon/bin` to `PATH` automatically when it exists.
Install Vite+ once for task running:

```bash
curl -fsSL https://vite.plus | bash
vp install
```

## Without Nix

Install:

- [MoonBit](https://www.moonbitlang.com/) toolchain.
- [Vite+](https://viteplus.dev/) for the root Vite Task workflow.
- Node.js 24, which Vite+ can pin from `.node-version`.

Then clone and check the workspace:

```bash
git clone https://github.com/ubugeeei/relanote.git
cd relanote
moon check
moon test
```

## Running the CLI

```bash
moon check
moon run src/cmd -- help
moon run src/cmd -- check examples/tutorials/01_hello.rela
moon run src/cmd -- render examples/tutorials/01_hello.rela output.mid
```

From the repository root, the same commands are available through Vite
Task:

```bash
vp run check
vp run test
vp run cli check examples/tutorials/01_hello.rela
vp run cli render examples/tutorials/01_hello.rela output.mid
```

## Editor Support

The CLI exposes an LSP entry point with `relanote lsp`. Configure your
editor to launch it as the language server for `.rela` files to get
diagnostics, hover docs, formatting, and completion as the MoonBit server
surface grows.

## Studio source

The Studio surface is temporarily hidden while it is rebuilt. The Vapor
Moon source still lives in `src/studio/App.mbtv` and can be compiled:

```bash
vp run studio:build
```

## Listen-through example

After the toolchain is installed, this tiny smoke test should render in
the CLI and play in docs previews. It uses only the first vocabulary you
need: a scale, relative rhythm, rests and concatenation.

```rela
scale Major = { R, M2, M3, P4, P5, M6, M7 }

let check  = | <1> <3> <5> <8> |:2
let breath = | <5> - <3> - |:2
let close  = | <1> |:2

check ++ breath ++ close
```
