{
  description = "relanote — a pure functional, statically-typed language for music";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs { inherit system; };

        moonbitShellHook = ''
          if [ -d "$HOME/.moon/bin" ]; then
            export PATH="$HOME/.moon/bin:$PATH"
          fi
        '';
      in
      {
        devShells.default = pkgs.mkShell {
          packages = [
            pkgs.nodejs_24
            pkgs.pnpm
            pkgs.curl
            pkgs.git
            pkgs.gnumake
            pkgs.librsvg
          ];

          shellHook = ''
            ${moonbitShellHook}

            cat <<'BANNER'
            relanote dev shell
              node : `node --version`
              pnpm : `pnpm --version`

            Common tasks:
              vp run         # interactive Vite Task picker
              vp run ci      # full local CI task graph
              vp run check   # moon check
              vp run test    # moon test
              vp run studio:build # compile the Vapor Moon component

            Toolchains installed separately:
              curl -fsSL https://cli.moonbitlang.com/install/unix.sh | bash
              curl -fsSL https://vite.plus | bash
            BANNER
          '';
        };

        formatter = pkgs.nixpkgs-fmt;
      });
}
