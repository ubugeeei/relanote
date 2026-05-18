// Regenerate the OG card PNG from `assets/og-image.svg`. Requires
// `rsvg-convert` (provided by the Nix dev shell).

import { run } from "./_shell";

run("rsvg-convert", [
  "-w", "1200",
  "-h", "630",
  "assets/og-image.svg",
  "-o", "assets/og-image.png",
]);
