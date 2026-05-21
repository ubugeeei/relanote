import { defineConfig } from "vite-plus";

const moonNative = "moon test --target native -p ubugeeei/relanote/src/lsp -p ubugeeei/relanote/src/cmd";
const vapor = "moon run .mooncakes/ubugeeei/vapor_moon/src/cmd/vapor_moon";

export default defineConfig({
  run: {
    tasks: {
      build: { command: "moon build" },
      check: { command: "moon check" },
      cli: { command: "moon run src/cmd --", cache: false },
      coverage: { command: "moon coverage analyze -- -f summary" },
      "coverage:html": {
        command: "moon coverage analyze -- -f html -o coverage.html",
        output: ["coverage.html"],
      },
      ci: {
        command: [
          "vp run check",
          "vp run line-limit",
          "vp run test",
          "vp run test:native",
          "vp run build",
          "vp run lsp:test",
          "vp run coverage",
          "vp run studio:build",
          "vp run docs:build",
        ].join(" && "),
        cache: false,
      },
      "deploy:void": {
        command: "vp run docs:build && vp dlx void deploy --project relanote --dir dist --spa",
        untrackedEnv: ["VOID_TOKEN", "VOID_PROJECT"],
      },
      "diagrams:regen": { command: "node scripts/generate_diagrams.mjs" },
      "docs:build": { command: "node src/site/build.mjs", output: ["dist/**"] },
      fmt: { command: "moon fmt", cache: false },
      "line-limit": { command: "bash scripts/line_limit.sh" },
      lsp: { command: "moon run src/cmd -- lsp", cache: false },
      "lsp:test": { command: "bash scripts/test_lsp_stdio.sh" },
      run: { command: "moon run src/cmd --", cache: false },
      "stdlib:regen": { command: "bash scripts/gen_stdlib.sh" },
      "studio:build": {
        command: `${vapor} -- compile src/studio/App.mbtv > /tmp/relanote-vapor-moon.snapshot`,
      },
      test: { command: "moon test" },
      "test:native": { command: moonNative },
    },
  },
});
