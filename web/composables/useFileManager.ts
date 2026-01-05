export interface RelaFile {
  id: string;
  name: string;
  content: string;
  createdAt: number;
  updatedAt: number;
}

const STORAGE_KEY = "relanote-files";
const ACTIVE_FILE_KEY = "relanote-active-file";

// Default content: Drum & Bass showcase
const DEFAULT_CONTENT = `; ============================================
; "VOID PROTOCOL" - Dark Neurofunk
; Aggressive, dark, industrial D&B
; ============================================

set tempo = 174

; Custom dark scale with M7 for tension
scale Dark = { R, m2, m3, P4, P5, m6, M7 }

; ============================================
; Custom Dark Synths
; ============================================

synth DarkReese = {
  osc: Saw,
  detune: 30,
  env: envelope 0.01 0.15 0.9 0.25,
  filter: LowPass(300, 0.8)
}

synth DeepSub = {
  osc: Sine,
  env: envelope 0.01 0.2 0.95 0.3,
  filter: LowPass(80, 0.0)
}

synth HeavyBass = {
  osc: Square,
  detune: 20,
  env: envelope 0.005 0.1 0.85 0.2,
  filter: LowPass(200, 0.6)
}

synth NeuroLead = {
  osc: Square,
  detune: 15,
  env: envelope 0.002 0.1 0.5 0.15,
  filter: LowPass(1500, 0.6)
}

synth DarkPad = {
  osc: Saw,
  detune: 20,
  env: envelope 0.3 0.2 0.6 0.5,
  filter: LowPass(800, 0.3)
}

synth AggroStab = {
  osc: Square,
  env: envelope 0.001 0.08 0.0 0.05,
  filter: LowPass(2500, 0.8)
}

synth EDMKick = {
  osc: Sine,
  env: envelope 0.001 0.15 0.0 0.1,
  filter: LowPass(50, 0.0)
}

synth KickClick = {
  osc: Square,
  env: envelope 0.0005 0.015 0.0 0.008,
  filter: LowPass(5000, 0.7)
}

synth KickAttack = {
  osc: Noise,
  env: envelope 0.0001 0.01 0.0 0.005,
  filter: LowPass(8000, 0.5)
}

synth KickBody = {
  osc: Triangle,
  env: envelope 0.001 0.18 0.0 0.12,
  filter: LowPass(80, 0.2)
}

synth KickSub = {
  osc: Sine,
  env: envelope 0.001 0.25 0.0 0.15,
  filter: LowPass(40, 0.0)
}

; ============================================
; AMEN BREAK - Aggressive patterns
; ============================================

let amen_kick = |
  R^ - - - - - R - - - R^ - - - - -
  R^ - - - - - R - - - - - R^ - R -
|:8

let kick_double = |
  R^ - R - R^ - R - R^ - R - R^ - R -
  R^ - R - R^ - R R R^ - R - R^ R R -
|:8

let kick_rolling = |
  R R - R R - R R R - R R - R R -
  R^ - R R^ - R R^ - R R^ - R R R R
|:8

let kick_offbeat = |
  R^ - - R R^ - - R R^ - - R R^ - R -
  R^ - R - R^ - R - R^ R - R R^ R R -
|:8

let amen_snare = |
  - - - - R^ - - - - - - - R^ - - -
  - - - - R^ - - - - - - - R^ - R^ -
|:8

let hihat_chaos = |
  R R - R R - R R R - R R - R R -
  R - R R - R R - R R R - R - R R
|:8

let hihat_roll = | R R R R R R R R R R R R R R R R |:4

let ghost_snare = |
  - R - - - R - - - R - - - R - R
  R - - R - - R - - R - - R - - -
|:8

; ============================================
; DARK BASS - Heavy, distorted
; ============================================

let bass_dark = |
  <1>^ - - - <3> - - <7>^ - - - - <3> - - -
  - - <1>^ - - <7> - - <3>^ - - - - <1> - -
|:8

let bass_rolling = |
  <1> - <3> - - <7> - <1> - <3> - - <7> - <1> -
  <7> - - <3> - <1> - - <7> - <3> - - <1> - -
|:8

let bass_stab = |
  <1>^ - - - - - - - - - - - <7>^ - - -
  - - - - <3>^ - - - - - - - - - <1>^ -
|:8

let sub_bass = |
  <1>~ - - - - - - - - - - - - - - -
  - - - - - - - - <7>~ - - - - - - -
|:8

; ============================================
; NEURO LEAD - Dark, aggressive
; ============================================

let neuro_riff = |
  <1>^ - - <3> - - <7>^ - - - <3> - - <1> - -
  - - <7>^ - - <3> - - <1>^ - - - <7> <3> <1> -
|:8

let neuro_dark = |
  - <1> - - <3>^ - - <7> - - - <3> - <1>^ - -
  <7>^ - - - - <3> - - <1> - <7>^ - - - <3> -
|:8

let neuro_stab = |
  [R, m3, M7]^ - - - - - - - - - - - - - - -
  - - - - - - [m3, M7]^ - - - - - [R, M7]^ - - -
|:8

let neuro_glitch = |
  <1> - - <7> - <3> - - <1> - - <7>^ - - - -
  - <3> - - <7> - - <1>^ - - <3> - <7> - - -
|:8

let scream_lead = |
  <7>~ - - - - - - - - - <3> - - <1>^ - -
  - - - <7>~ - - - - <3> - - - <1> - <7>^ -
|:8

; ============================================
; DARK ARPS - Tension building
; ============================================

let arp_dark = |
  <1> - <3> <7> - <3> - <7> <1> - <7> <3> - <1> - <7>
  <3> - <1> - <7> - <3> <1> - <7> - <3> <7> - <1> -
|:8

let arp_broken = |
  <1> - - <7> - - <3> - <1> - - <7> - - <3> -
  - <7> - - <3> - - <1> - <7> - - <3> - - <1>
|:8

let arp_tension = |
  <1> <7> - <3> - <7> <1> - - <3> <7> - <1> - <7> <3>
  - <1> <7> - <3> - - <7> <1> - <3> <7> - <1> - -
|:8

; ============================================
; DARK PAD - Atmosphere
; ============================================

let dark_pad = |
  [R, m3, M7]~ - - - - - - - - - - - - - - -
  [m3, M7]~ - - - - - - - - - - - - - - -
|:16

; ============================================
; FILLS - Crescendo rolls
; ============================================

; Short 1-bar fill with crescendo (32nd notes)
let fill_snare_short = | R R R R R R R R R R R R R R R R |:2

; Medium 2-bar fill - building intensity
let fill_snare_med = |
  - - - - - - - - R R R R R R R R
  R R R R R R R R R R R R R R R R
|:4

; Long 4-bar crescendo fill
let fill_snare_long = |
  - - - - - - - - - - - - R - R -
  - - - - - - - - R - R - R R R -
  - - - - R - R - R R R - R R R R
  R - R R R R R R R R R R R R R R
|:8

; Hi-hat machine gun fill (gradual)
let fill_hat_roll = |
  - - - - R - - - R - - - R - R -
  R - R - R - R R R R R R R R R R
|:4

; Hi-hat crescendo (very sparse to dense)
let fill_hat_crescendo = |
  - - - - - - - - R - - - - - - -
  - - - - R - - - - - R - R - - -
  - - R - - - R - R - R - R - R -
  R - R - R R R R R R R R R R R R
|:8

; Kick fill - rapid fire
let fill_kick_rapid = |
  - - - - - - - - R R R R R R R R
  R R R R R R R R R R R R R R R R
|:4

; Combined drum fill (kick + snare alternating)
let fill_combo = |
  - - - - - - - - R - R - R R R R
  R R R R R R R R R R R R R R R R
|:4

; ============================================
; BUILD UP
; ============================================

let snare_roll = |
  R - - - R - - - R - R - R - R -
  R - R - R R R - R R R R R R R R
|:8

let riser = |
  <1> - - - <1> - - - <1> - <1> - <1> - <1> -
  <1> <1> <1> <1> <1> <1> <1> <1> <1> <1> <1> <1> <1> <1> <1> <1>
|:8

; ============================================
; SECTIONS
; ============================================

let intro_kick = amen_kick ++ kick_offbeat
let intro_snare = amen_snare
let intro_hat = hihat_chaos
let intro_bass = sub_bass ++ sub_bass

let drop_kick = kick_double ++ kick_rolling ++ amen_kick ++ kick_offbeat
let drop_snare = amen_snare ++ ghost_snare
let drop_hat = hihat_chaos ++ hihat_roll ++ hihat_chaos ++ hihat_roll
let drop_bass = bass_dark ++ bass_rolling ++ bass_dark ++ bass_stab

let break_kick = kick_rolling ++ kick_double
let break_snare = snare_roll
let break_riser = riser

; ============================================
; FULL ARRANGEMENT (clean - fills are separate)
; ============================================

; Main patterns without fills
let full_kick = intro_kick ++ drop_kick ++ break_kick ++ drop_kick
let full_snare = intro_snare ++ drop_snare ++ break_snare ++ drop_snare
let full_ghost = | - |:8 ++ ghost_snare ++ | - |:8 ++ ghost_snare
let full_hat = intro_hat ++ drop_hat ++ intro_hat ++ drop_hat

; Fill tracks - all at consistent timing
let fill_snare_track = | - |:14 ++ fill_snare_med ++ | - |:28 ++ fill_snare_long ++ | - |:12 ++ fill_snare_med ++ | - |:28
let fill_hat_track = | - |:14 ++ fill_hat_crescendo ++ | - |:28 ++ fill_hat_crescendo ++ | - |:12 ++ fill_hat_crescendo ++ | - |:28
let fill_kick_track = | - |:14 ++ fill_kick_rapid ++ | - |:28 ++ fill_combo ++ | - |:12 ++ fill_kick_rapid ++ | - |:28

; Bass
let full_bass = intro_bass ++ drop_bass ++ intro_bass ++ drop_bass
let full_sub = sub_bass |> repeat 8

let neuro_part1 = | - |:16 ++ neuro_riff ++ neuro_stab ++ neuro_glitch
let neuro_part2 = | - |:16 ++ neuro_dark ++ neuro_stab ++ scream_lead
let full_neuro = neuro_part1 ++ neuro_part2

let full_arp = | - |:32 ++ arp_dark ++ arp_broken ++ arp_tension
let full_pad = dark_pad ++ dark_pad ++ | - |:32 ++ dark_pad

; ============================================
; OUTPUT - DARK CHAOS
; ============================================

layer [
  ; ========== KICKS - Layered for punch ==========
  ; Sub layer (20-50Hz) - Pure weight
  full_kick |> transpose (R - P8 - P8 - P8 - P8) |> voice KickSub |> volume 2.0,
  ; Low layer (50-100Hz) - Body
  full_kick |> transpose (R - P8 - P8 - P8) |> voice EDMKick |> volume 2.0,
  ; Mid layer (80-200Hz) - Punch
  full_kick |> transpose (R - P8 - P8) |> voice KickBody |> volume 1.8,
  ; High layer (4-5kHz) - Click
  full_kick |> voice KickClick |> volume 1.5,
  ; Attack layer (noise transient)
  full_kick |> voice KickAttack |> volume 1.0,

  ; ========== SNARE & HATS ==========
  full_snare |> voice Snare |> reverb 0.25 |> volume 0.7,
  full_ghost |> voice Snare |> reverb 0.15 |> volume 0.25,
  full_hat |> voice HiHat |> reverb 0.3 |> volume 0.35,

  ; ========== FILLS - Crescendo rolls (consistent volumes) ==========
  fill_snare_track |> voice Snare |> reverb 0.2 |> volume 0.7,
  fill_hat_track |> voice HiHat |> reverb 0.2 |> volume 0.35,
  fill_kick_track |> transpose (R - P8 - P8) |> voice KickBody |> volume 0.9,

  ; ========== BASS - Heavy & Deep ==========
  ; Sub bass (30-80Hz) - Foundation
  full_sub |> transpose (R - P8 - P8 - P8 - P8) |> voice DeepSub |> volume 1.0,
  ; Low bass (60-150Hz) - Weight
  full_sub |> transpose (R - P8 - P8 - P8) |> voice HeavyBass |> cutoff 120.0 |> volume 0.85,
  ; Mid bass (100-300Hz) - Character
  full_bass |> transpose (R - P8 - P8) |> voice DarkReese |> reverb 0.15 |> volume 0.95,
  ; High bass (200-400Hz) - Growl
  full_bass |> transpose (R - P8) |> voice HeavyBass |> cutoff 350.0 |> reverb 0.2 |> volume 0.5,

  ; ========== SYNTHS ==========
  full_neuro |> transpose (R - P8) |> voice NeuroLead |> reverb 0.4 |> volume 0.55,
  full_arp |> voice AggroStab |> cutoff 2000.0 |> reverb 0.5 |> volume 0.35,

  ; ========== ATMOSPHERE ==========
  full_pad |> transpose (R - P8) |> voice DarkPad |> hall_reverb |> volume 0.35
]
`;

const files = ref<RelaFile[]>([]);
const activeFileId = ref<string | null>(null);

export function useFileManager() {
  const generateId = () => {
    return `file-${Date.now()}-${Math.random().toString(36).substring(2, 9)}`;
  };

  // Initialize with default content (no LocalStorage)
  const initDefault = () => {
    if (files.value.length > 0) return;

    const defaultFile: RelaFile = {
      id: generateId(),
      name: "showcase_dnb.rela",
      content: DEFAULT_CONTENT,
      createdAt: Date.now(),
      updatedAt: Date.now(),
    };
    files.value = [defaultFile];
    activeFileId.value = defaultFile.id;
  };

  // Explicitly load from LocalStorage (user action)
  const loadFromLocalStorage = () => {
    if (typeof window === "undefined") return false;

    const stored = localStorage.getItem(STORAGE_KEY);
    if (stored) {
      try {
        const loadedFiles = JSON.parse(stored) as RelaFile[];
        if (loadedFiles.length > 0) {
          files.value = loadedFiles;

          // Restore active file
          const storedActive = localStorage.getItem(ACTIVE_FILE_KEY);
          if (storedActive && files.value.some((f) => f.id === storedActive)) {
            activeFileId.value = storedActive;
          } else {
            activeFileId.value = files.value[0].id;
          }
          return true;
        }
      } catch {
        return false;
      }
    }
    return false;
  };

  // Explicitly save to LocalStorage (user action)
  const saveToLocalStorage = () => {
    if (typeof window === "undefined") return;
    localStorage.setItem(STORAGE_KEY, JSON.stringify(files.value));
    if (activeFileId.value) {
      localStorage.setItem(ACTIVE_FILE_KEY, activeFileId.value);
    }
  };

  const activeFile = computed(() => {
    return files.value.find((f) => f.id === activeFileId.value) || null;
  });

  const createFile = (name?: string) => {
    const baseName = name || "untitled";
    let fileName = `${baseName}.rela`;
    let counter = 1;

    while (files.value.some((f) => f.name === fileName)) {
      fileName = `${baseName}-${counter}.rela`;
      counter++;
    }

    const newFile: RelaFile = {
      id: generateId(),
      name: fileName,
      content: "",
      createdAt: Date.now(),
      updatedAt: Date.now(),
    };

    files.value.push(newFile);
    activeFileId.value = newFile.id;
    return newFile;
  };

  const deleteFile = (id: string) => {
    const index = files.value.findIndex((f) => f.id === id);
    if (index === -1) return;

    files.value.splice(index, 1);

    if (activeFileId.value === id) {
      activeFileId.value = files.value[0]?.id || null;
    }
  };

  const renameFile = (id: string, newName: string) => {
    const file = files.value.find((f) => f.id === id);
    if (!file) return;

    let name = newName.endsWith(".rela") ? newName : `${newName}.rela`;

    // Check for duplicate names
    if (files.value.some((f) => f.id !== id && f.name === name)) {
      console.warn("File with this name already exists");
      return;
    }

    file.name = name;
    file.updatedAt = Date.now();
  };

  const updateContent = (id: string, content: string) => {
    const file = files.value.find((f) => f.id === id);
    if (!file) return;

    file.content = content;
    file.updatedAt = Date.now();
  };

  const setActiveFile = (id: string) => {
    if (files.value.some((f) => f.id === id)) {
      activeFileId.value = id;
    }
  };

  const exportFile = (id: string) => {
    const file = files.value.find((f) => f.id === id);
    if (!file) return;

    const blob = new Blob([file.content], { type: "text/plain" });
    const url = URL.createObjectURL(blob);
    const a = document.createElement("a");
    a.href = url;
    a.download = file.name;
    a.click();
    URL.revokeObjectURL(url);
  };

  const exportAllFiles = () => {
    const data = JSON.stringify(files.value, null, 2);
    const blob = new Blob([data], { type: "application/json" });
    const url = URL.createObjectURL(blob);
    const a = document.createElement("a");
    a.href = url;
    a.download = "relanote-project.json";
    a.click();
    URL.revokeObjectURL(url);
  };

  const importFiles = async (file: File) => {
    const text = await file.text();

    if (file.name.endsWith(".json")) {
      try {
        const imported = JSON.parse(text) as RelaFile[];
        for (const f of imported) {
          // Generate new IDs to avoid conflicts
          f.id = generateId();
          if (files.value.some((existing) => existing.name === f.name)) {
            f.name = f.name.replace(".rela", `-imported.rela`);
          }
          files.value.push(f);
        }
      } catch {
        console.error("Invalid JSON file");
      }
    } else if (file.name.endsWith(".rela")) {
      const newFile: RelaFile = {
        id: generateId(),
        name: file.name,
        content: text,
        createdAt: Date.now(),
        updatedAt: Date.now(),
      };
      files.value.push(newFile);
      activeFileId.value = newFile.id;
    }
  };

  return {
    files,
    activeFile,
    activeFileId,
    initDefault,
    loadFromLocalStorage,
    saveToLocalStorage,
    createFile,
    deleteFile,
    renameFile,
    updateContent,
    setActiveFile,
    exportFile,
    exportAllFiles,
    importFiles,
  };
}
