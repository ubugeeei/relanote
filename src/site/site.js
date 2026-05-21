let previewRuntime;

async function runtime() {
  if (!previewRuntime) {
    previewRuntime = fetch("/preview.wasm")
      .then((res) => res.arrayBuffer())
      .then((bytes) => WebAssembly.instantiate(bytes, {}, {
        builtins: ["js-string"],
        importedStringConstants: "_",
      }))
      .then(({ instance }) => instance.exports)
      .catch(() => null);
  }
  return previewRuntime;
}

function sourceOf(kit) {
  return kit?.querySelector("code")?.innerText ?? "";
}

async function events(source) {
  const wasm = await runtime();
  if (!wasm) return [];
  try { return JSON.parse(wasm.events_json(source)); } catch { return []; }
}

async function summary(source) {
  const wasm = await runtime();
  if (!wasm) return "preview runtime unavailable";
  return wasm.playground_summary(source);
}

async function tempo(source) {
  const wasm = await runtime();
  if (!wasm) return 120;
  const bpm = wasm.preview_tempo(source);
  return bpm > 0 ? bpm : 120;
}

function draw(preview, notes, text) {
  const kit = preview.closest(".code-kit");
  const empty = notes.length === 0;
  preview.hidden = empty;
  kit?.classList.toggle("no-preview", empty);
  if (empty) return;
  const end = Math.max(1, ...notes.map((note) => note.start + note.duration));
  preview.querySelector(".preview-roll").innerHTML = notes.map((note) => {
    const x = 7 + note.start / end * 78;
    const y = 82 - (note.pitch - 54) * 2.35;
    const w = Math.max(8, note.duration / end * 72);
    return `<i style="--x:${x}%;--y:${Math.max(8, Math.min(84, y))}%;--w:${w}%"></i>`;
  }).join("");
  preview.querySelector("span").textContent = text;
}

async function renderPreview(kit) {
  const preview = kit?.querySelector(".code-preview");
  if (!preview) return;
  const source = sourceOf(kit);
  draw(preview, await events(source), await summary(source));
}

function play(kit) {
  return window.RelanoteAudio?.playSource(sourceOf(kit), events, tempo);
}

function drawStudioRoll(frame, notes) {
  const roll = frame.querySelector("[data-studio-roll]");
  if (!roll) return;
  const end = Math.max(1, ...notes.map((note) => note.start + note.duration));
  roll.innerHTML = notes.map((note) => {
    const left = 7 + note.start / end * 78;
    const top = 80 - (note.pitch - 54) * 2.2;
    const width = Math.max(9, note.duration / end * 70);
    return `<i style="left:${left}%;top:${Math.max(10, Math.min(80, top))}%;width:${width}%"></i>`;
  }).join("");
}

async function renderStudio(frame) {
  const source = frame.querySelector(".studio-editor code")?.innerText ?? "";
  const notes = await events(source);
  frame.querySelector("[data-studio-summary]").textContent = await summary(source);
  frame.querySelector("[data-studio-diag]").textContent = notes.length ? "Clean: wasm preview rendered" : "No playable notes";
  drawStudioRoll(frame, notes);
}

document.querySelectorAll(".language-rela code").forEach((code) => {
  code.contentEditable = "true";
  code.spellcheck = false;
  renderPreview(code.closest(".code-kit"));
  code.addEventListener("input", () => renderPreview(code.closest(".code-kit")));
});

document.querySelectorAll(".studio-frame").forEach((frame) => {
  renderStudio(frame);
  frame.querySelector(".studio-editor code")?.addEventListener("input", () => renderStudio(frame));
});

document.addEventListener("click", async (event) => {
  const playButton = event.target.closest(".preview-play");
  if (playButton) return play(playButton.closest(".code-kit"));
  const studioPlay = event.target.closest(".studio-play");
  if (studioPlay) {
    const source = studioPlay.closest(".studio-frame").querySelector(".studio-editor code")?.innerText ?? "";
    return window.RelanoteAudio?.playSource(source, events, tempo);
  }
  const button = event.target.closest(".code-copy");
  if (!button) return;
  const code = sourceOf(button.closest(".code-kit"));
  try {
    await navigator.clipboard.writeText(code);
    button.textContent = "Copied";
    setTimeout(() => { button.textContent = "Copy"; }, 1200);
  } catch {
    button.textContent = "Select";
  }
});
