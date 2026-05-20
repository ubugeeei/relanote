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
            pkgs.nodejs_22
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
              pnpm tasks     # list every task with its command
              pnpm check     # moon check
              pnpm test      # moon test
              pnpm web:build # compile the Vapor Moon playground component

            MoonBit toolchain is installed separately:
              curl -fsSL https://cli.moonbitlang.com/install/unix.sh | bash
            BANNER
          '';
        };

        formatter = pkgs.nixpkgs-fmt;
      });
}
