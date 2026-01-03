export interface RelaFile {
  id: string;
  name: string;
  content: string;
  createdAt: number;
  updatedAt: number;
}

const STORAGE_KEY = "relanote-files";
const ACTIVE_FILE_KEY = "relanote-active-file";

const files = ref<RelaFile[]>([]);
const activeFileId = ref<string | null>(null);

export function useFileManager() {
  const loadFromStorage = () => {
    if (typeof window === "undefined") return;

    const stored = localStorage.getItem(STORAGE_KEY);
    if (stored) {
      try {
        files.value = JSON.parse(stored);
      } catch {
        files.value = [];
      }
    }

    // Create default file if none exist
    if (files.value.length === 0) {
      const defaultFile: RelaFile = {
        id: generateId(),
        name: "main.rela",
        content: `; Welcome to Relanote!
; A functional music notation language where everything is relative.

scale Major = { R, M2, M3, P4, P5, M6, M7 }

; Relative Rhythm: slots are equally divided within a block
let fast = | <1> <2> <3> <4> <5> <4> <3> <2> |
let slow = | <1> <3> <5> <3> |

; Semitone modifiers
let chromatic = | P1 P1+ M2 M2+ M3 |

; Combine patterns
let melody = fast ++ slow ++ chromatic

melody
`,
        createdAt: Date.now(),
        updatedAt: Date.now(),
      };
      files.value = [defaultFile];
      saveToStorage();
    }

    // Restore active file
    const storedActive = localStorage.getItem(ACTIVE_FILE_KEY);
    if (storedActive && files.value.some((f) => f.id === storedActive)) {
      activeFileId.value = storedActive;
    } else if (files.value.length > 0) {
      activeFileId.value = files.value[0].id;
    }
  };

  const saveToStorage = () => {
    if (typeof window === "undefined") return;
    localStorage.setItem(STORAGE_KEY, JSON.stringify(files.value));
    if (activeFileId.value) {
      localStorage.setItem(ACTIVE_FILE_KEY, activeFileId.value);
    }
  };

  const generateId = () => {
    return `file-${Date.now()}-${Math.random().toString(36).substring(2, 9)}`;
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
    saveToStorage();
    return newFile;
  };

  const deleteFile = (id: string) => {
    const index = files.value.findIndex((f) => f.id === id);
    if (index === -1) return;

    files.value.splice(index, 1);

    if (activeFileId.value === id) {
      activeFileId.value = files.value[0]?.id || null;
    }

    saveToStorage();
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
    saveToStorage();
  };

  const updateContent = (id: string, content: string) => {
    const file = files.value.find((f) => f.id === id);
    if (!file) return;

    file.content = content;
    file.updatedAt = Date.now();
    saveToStorage();
  };

  const setActiveFile = (id: string) => {
    if (files.value.some((f) => f.id === id)) {
      activeFileId.value = id;
      saveToStorage();
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
        saveToStorage();
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
      saveToStorage();
    }
  };

  return {
    files,
    activeFile,
    activeFileId,
    loadFromStorage,
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
