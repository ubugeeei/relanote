{
  description = "relanote — a pure functional, statically-typed language for music";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    rust-overlay = {
      url = "github:oxalica/rust-overlay";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, flake-utils, rust-overlay }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs {
          inherit system;
          overlays = [ rust-overlay.overlays.default ];
        };

        # Pin the Rust toolchain to the version the workspace was developed
        # against. The wasm32 target is needed by `wasm-pack` until the
        # MoonBit port replaces `crates/relanote_wasm` (#15).
        rustToolchain = pkgs.rust-bin.stable."1.83.0".default.override {
          extensions = [ "rust-src" "rust-analyzer" "clippy" "rustfmt" ];
          targets = [ "wasm32-unknown-unknown" ];
        };

        # MoonBit toolchain — there is no nixpkgs derivation for it today,
        # so the README documents the one-line installer. The dev shell
        # adds `~/.moon/bin` to PATH if it exists so contributors who have
        # already installed MoonBit can use it without extra setup.
        moonbitShellHook = ''
          if [ -d "$HOME/.moon/bin" ]; then
            export PATH="$HOME/.moon/bin:$PATH"
          fi
        '';
      in
      {
        devShells.default = pkgs.mkShell {
          packages = [
            # Rust workspace (Cargo + clippy + rustfmt + rust-analyzer).
            rustToolchain

            # Web playground + docs site (Nuxt + VitePress, pnpm).
            # Also the runtime for `vite-node`, which drives every task in
            # `tasks/` (see `package.json`).
            pkgs.nodejs_22
            pkgs.pnpm

            # Rust → WebAssembly bridge for the existing playground.
            pkgs.wasm-pack

            # Convenience.
            pkgs.git
            pkgs.gnumake
            # SVG → PNG for regenerating the OG image after edits.
            pkgs.librsvg
          ];

          shellHook = ''
            ${moonbitShellHook}

            cat <<'BANNER'
            relanote dev shell
              rust : `rustc --version`
              node : `node --version`
              pnpm : `pnpm --version`

            Tasks live in `tasks/` and run via vite-node. Common ones:
              pnpm tasks    # list every task with its command
              pnpm setup    # install web + docs deps, build wasm
              pnpm dev      # build wasm and start the playground
              pnpm test     # cargo test + moon test
              pnpm docs:dev # docs preview server
              pnpm og:png   # regenerate the social card PNG

            First time only — install root deps so vite-node is on PATH:
              pnpm install

            MoonBit toolchain is not on nixpkgs — install with:
              curl -fsSL https://cli.moonbitlang.com/install/unix.sh | bash
            BANNER
          '';
        };

        # `nix fmt` formats this flake.
        formatter = pkgs.nixpkgs-fmt;
      });
}
