# Installation

## Prerequisites

- [Rust](https://rustup.rs/) 1.75 or later
- [Node.js](https://nodejs.org/) 20+ (for web playground)
- [mise](https://mise.jdx.dev/) (recommended for environment management)

## Using mise (Recommended)

The easiest way to get started is using mise:

```bash
# Clone the repository
git clone https://github.com/ubugeeei/relanote.git
cd relanote

# Trust the mise configuration
mise trust

# Install all dependencies and build
mise run setup
```

This will:
1. Install the correct Rust and Node.js versions
2. Install web dependencies
3. Build the WASM module
4. Prepare the development environment

## Manual Installation

### CLI Tool

Build and install the CLI:

```bash
cargo install --path crates/relanote-cli
```

Or build from source:

```bash
cargo build --release
# Binary will be at target/release/relanote
```

### Verify Installation

```bash
relanote --version
# relanote 0.1.0
```

## Editor Support

### VS Code

The Relanote LSP provides:
- Syntax highlighting
- Real-time error checking
- Hover documentation
- Auto-completion

Start the LSP server:

```bash
relanote lsp
```

Configure your editor to use it as a language server for `.rela` files.

## Web Playground

Run the web-based IDE locally:

```bash
# Using mise
mise run dev

# Or manually
cd web
pnpm install
pnpm dev
```

Open `http://localhost:3000` in your browser.
