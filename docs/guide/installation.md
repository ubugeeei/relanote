# Installation

## With Nix (recommended)

The repo ships a Nix flake that pins every dev tool to the versions the
project was built against — Rust 1.83, Node 22, pnpm, `wasm-pack`,
`pnpm tasks` — so you get the same environment as CI.

```bash
git clone https://github.com/ubugeeei/relanote.git
cd relanote

# Enter the dev shell.
nix develop

# First-time setup: web + docs deps, build WASM, prepare Nuxt types.
pnpm setup
```

If you use [direnv](https://direnv.net/), `direnv allow` activates the
shell automatically every time you `cd` into the repo.

MoonBit isn't on nixpkgs yet — install it once with:

```bash
curl -fsSL https://cli.moonbitlang.com/install/unix.sh | bash
```

The dev shell adds `~/.moon/bin` to `PATH` automatically when MoonBit is
installed, so `moon check` and `moon test` just work.

## Without Nix

Make sure the following are on your `PATH`:

- [Rust](https://rustup.rs/) 1.83 or later, with the `wasm32-unknown-unknown` target.
- [Node.js](https://nodejs.org/) 22+ and [pnpm](https://pnpm.io/).
- [`wasm-pack`](https://rustwasm.github.io/wasm-pack/) for the playground WASM build.
- After cloning, the repo's `pnpm install` brings in `vite-node` so every workflow runs through `pnpm <task>` (see [`tasks/`](https://github.com/ubugeeei/relanote/tree/main/tasks)).
- [MoonBit](https://www.moonbitlang.com/) toolchain — `curl -fsSL https://cli.moonbitlang.com/install/unix.sh | bash`.

Then clone and set up:

```bash
git clone https://github.com/ubugeeei/relanote.git
cd relanote
pnpm setup
```

## Building just the CLI

If all you want is the `relanote` binary:

```bash
cargo install --path crates/relanote_cli
relanote --version
```

Or build from source:

```bash
cargo build --release        # → target/release/relanote
```

## Editor support

The CLI ships an LSP server (`relanote lsp`) over stdio. Wire it into
your editor as a language server for `.rela` files and you get
diagnostics, hover docs and completion.

## Web playground locally

```bash
pnpm dev
```

This builds the WASM module and starts Nuxt on `http://localhost:3000`.
