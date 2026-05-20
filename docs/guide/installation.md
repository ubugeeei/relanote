# Installation

## With Nix

The repo ships a Nix flake for the local helper tools used by root
scripts and deployment.

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

## Without Nix

Install:

- [MoonBit](https://www.moonbitlang.com/) toolchain.
- [Node.js](https://nodejs.org/) 22+ and [pnpm](https://pnpm.io/) if you want the root task aliases.

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
moon run cmd/relanote -- help
moon run cmd/relanote -- check examples/tutorials/01_hello.rela
moon run cmd/relanote -- render examples/tutorials/01_hello.rela output.mid
```

From the repository root, the same commands are available through pnpm:

```bash
pnpm check
pnpm test
pnpm cli -- check examples/tutorials/01_hello.rela
pnpm cli -- render examples/tutorials/01_hello.rela output.mid
```

## Editor Support

The CLI exposes an LSP entry point with `relanote lsp`. Configure your
editor to launch it as the language server for `.rela` files to get
diagnostics, hover docs, formatting, and completion as the MoonBit server
surface grows.

## Web Playground

The view lives in `web/App.mbtv` and is built with Vapor Moon:

```bash
pnpm web:build
```
