const SEMI = { R: 0, m2: 1, M2: 2, m3: 3, M3: 4, P4: 5, A4: 6, d5: 6, P5: 7, m6: 8, M6: 9, m7: 10, M7: 11, P8: 12 };
const ABS = { C: 0, D: 2, E: 4, F: 5, G: 7, A: 9, B: 11 };

function pitch(token) {
  if (token.startsWith("<")) return 60 + [0, 0, 2, 4, 5, 7, 9, 11][Number(token.match(/\d+/)?.[0] ?? 1)];
  if (SEMI[token] !== undefined) return 60 + SEMI[token];
  const note = token.match(/^([A-G])([#b]?)(\d)$/);
  if (!note) return 60;
  return 12 * (Number(note[3]) + 1) + ABS[note[1]] + (note[2] === "#" ? 1 : note[2] === "b" ? -1 : 0);
}

function tokens(source) {
  const block = [...source.matchAll(/\|([^|]+)\|/g)].at(-1)?.[1] ?? source;
  return [...block.matchAll(/<\d+>|\b[A-G][#b]?\d\b|\b(?:R|m2|M2|m3|M3|P4|A4|d5|P5|m6|M6|m7|M7|P8)\b/g)].map((m) => m[0]);
}

function events(source) {
  const found = tokens(source).slice(0, 16);
  const step = found.length ? 4 / found.length : 1;
  return found.map((token, i) => ({ pitch: pitch(token), start: i * step, duration: step * .82 }));
}

function renderPreview(kit) {
  const preview = kit?.querySelector(".code-preview");
  if (!preview) return;
  const notes = events(kit.querySelector("code")?.innerText ?? "");
  preview.querySelector(".preview-roll").innerHTML = notes.map((note) => {
    const x = 7 + note.start * 20;
    const y = 78 - (note.pitch - 56) * 2.6;
    const w = Math.max(9, note.duration * 18);
    return `<i style="--x:${x}%;--y:${Math.max(10, Math.min(80, y))}%;--w:${w}%"></i>`;
  }).join("");
  preview.querySelector("span").textContent = `${notes.length} notes / 4 beats`;
}

function play(kit) {
  const Audio = window.AudioContext || window.webkitAudioContext;
  if (!Audio) return;
  const ctx = new Audio();
  events(kit.querySelector("code")?.innerText ?? "").forEach((note) => {
    const osc = ctx.createOscillator();
    const gain = ctx.createGain();
    const t0 = ctx.currentTime + .04 + note.start * .32;
    const t1 = t0 + note.duration * .32;
    osc.type = "triangle";
    osc.frequency.value = 440 * Math.pow(2, (note.pitch - 69) / 12);
    gain.gain.setValueAtTime(.0001, t0);
    gain.gain.exponentialRampToValueAtTime(.14, t0 + .01);
    gain.gain.exponentialRampToValueAtTime(.0001, t1);
    osc.connect(gain).connect(ctx.destination);
    osc.start(t0);
    osc.stop(t1 + .03);
  });
}

document.querySelectorAll(".language-rela code").forEach((code) => {
  code.contentEditable = "true";
  code.spellcheck = false;
  renderPreview(code.closest(".code-kit"));
  code.addEventListener("input", () => renderPreview(code.closest(".code-kit")));
});

document.addEventListener("click", async (event) => {
  const playButton = event.target.closest(".preview-play");
  if (playButton) return play(playButton.closest(".code-kit"));
  const button = event.target.closest(".code-copy");
  if (!button) return;
  const code = button.closest(".code-kit")?.querySelector("code")?.innerText ?? "";
  try {
    await navigator.clipboard.writeText(code);
    button.textContent = "Copied";
    setTimeout(() => { button.textContent = "Copy"; }, 1200);
  } catch {
    button.textContent = "Select";
  }
});
