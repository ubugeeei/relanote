<script setup lang="ts">
import type { WasmDiagnostic, StaffData, RenderResult, AudioPlaybackData } from "../types/relanote";

const { isReady, error: wasmError, init, analyze, format, renderMidi, getStaffData, getAudioData } = useRelanote();
const {
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
} = useFileManager();

const diagnostics = ref<WasmDiagnostic[]>([]);
const staffData = ref<StaffData | null>(null);
const audioData = ref<AudioPlaybackData | null>(null);
const midiResult = ref<RenderResult | null>(null);
const currentBeat = ref(0);
const analysisDebounce = ref<ReturnType<typeof setTimeout> | null>(null);

// Resizable panels
const previewWidth = ref(400);
const isResizing = ref(false);
const containerRef = ref<HTMLElement | null>(null);

const startResize = (e: MouseEvent) => {
  isResizing.value = true;
  document.addEventListener("mousemove", onResize);
  document.addEventListener("mouseup", stopResize);
  e.preventDefault();
};

const onResize = (e: MouseEvent) => {
  if (!isResizing.value || !containerRef.value) return;

  const containerRect = containerRef.value.getBoundingClientRect();
  const newWidth = containerRect.right - e.clientX - 8; // 8px for padding

  // Clamp between 250px and 600px
  previewWidth.value = Math.min(Math.max(newWidth, 250), 600);
};

const stopResize = () => {
  isResizing.value = false;
  document.removeEventListener("mousemove", onResize);
  document.removeEventListener("mouseup", stopResize);
};

const code = computed({
  get: () => activeFile.value?.content || "",
  set: (value: string) => {
    if (activeFile.value) {
      updateContent(activeFile.value.id, value);
    }
  },
});

const analyzeCode = () => {
  if (!isReady.value) return;

  const result = analyze(code.value);
  if (result) {
    diagnostics.value = result.diagnostics;
  }

  const staff = getStaffData(code.value);
  if (staff) {
    staffData.value = staff;
  }

  const audio = getAudioData(code.value);
  if (audio) {
    audioData.value = audio;
  }

  const midi = renderMidi(code.value);
  if (midi) {
    midiResult.value = midi;
  }
};

const debouncedAnalyze = () => {
  if (analysisDebounce.value) {
    clearTimeout(analysisDebounce.value);
  }
  analysisDebounce.value = setTimeout(analyzeCode, 300);
};

watch(code, debouncedAnalyze);

const handleFormat = () => {
  if (!isReady.value) return;

  const result = format(code.value);
  if (result && result.success) {
    code.value = result.formatted;
  }
};

const handleExportMidi = () => {
  if (!midiResult.value?.midi_data) return;

  const bytes = new Uint8Array(midiResult.value.midi_data);
  const blob = new Blob([bytes], { type: "audio/midi" });
  const url = URL.createObjectURL(blob);
  const a = document.createElement("a");
  a.href = url;
  a.download = activeFile.value?.name.replace(".rela", ".mid") || "output.mid";
  a.click();
  URL.revokeObjectURL(url);
};

onMounted(async () => {
  loadFromStorage();
  await init();
  if (isReady.value) {
    analyzeCode();
  }
});

watch(isReady, (ready) => {
  if (ready) {
    analyzeCode();
  }
});
</script>

<template>
  <div class="app-container">
    <!-- Header -->
    <header class="app-header">
      <div class="header-left">
        <img src="/logo.svg" alt="Relanote" class="app-logo" />
        <h1 class="app-title">Relanote</h1>
        <span class="app-subtitle">Functional Music Notation</span>
      </div>
      <div class="header-right">
        <button class="header-btn" @click="exportAllFiles" title="Export All Files">
          Export Project
        </button>
        <a
          class="header-link"
          href="https://github.com/ubugeeei/relanote"
          target="_blank"
          rel="noopener"
        >
          GitHub
        </a>
      </div>
    </header>

    <!-- Loading State -->
    <div v-if="!isReady" class="loading-overlay">
      <div class="loading-spinner" />
      <p>Loading Relanote...</p>
    </div>

    <!-- Error State -->
    <div v-else-if="wasmError" class="error-overlay">
      <p>Failed to load Relanote: {{ wasmError }}</p>
    </div>

    <!-- Main Content -->
    <div v-else ref="containerRef" class="main-content" :class="{ resizing: isResizing }">
      <!-- Sidebar -->
      <aside class="sidebar">
        <FileTree
          :files="files"
          :active-file-id="activeFileId"
          @select-file="setActiveFile"
          @create-file="createFile()"
          @delete-file="deleteFile"
          @rename-file="renameFile"
          @export-file="exportFile"
          @import-file="importFiles"
        />
      </aside>

      <!-- Editor Panel -->
      <main class="editor-panel">
        <CodeEditor
          v-model="code"
          :diagnostics="diagnostics"
          :file-name="activeFile?.name"
          @format="handleFormat"
        />
      </main>

      <!-- Resize Handle -->
      <div class="resize-handle" @mousedown="startResize">
        <div class="resize-grip" />
      </div>

      <!-- Preview Panel -->
      <aside class="preview-panel" :style="{ width: previewWidth + 'px' }">
        <div class="staff-section">
          <StaffRenderer :staff-data="staffData" :current-beat="currentBeat" />
        </div>
        <div class="player-section">
          <MidiPlayer
            :notes="audioData?.notes || []"
            :midi-data="midiResult?.midi_data || null"
            :tempo="audioData?.tempo || 120"
            :total-beats="audioData?.total_beats || 0"
            @update:current-beat="currentBeat = $event"
            @export-midi="handleExportMidi"
          />
        </div>
      </aside>
    </div>
  </div>
</template>

<style>
* {
  margin: 0;
  padding: 0;
  box-sizing: border-box;
}

body {
  font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, Oxygen,
    Ubuntu, Cantarell, sans-serif;
  background: #1e1e1e;
  color: #cccccc;
  overflow: hidden;
}
</style>

<style scoped>
.app-container {
  display: flex;
  flex-direction: column;
  height: 100vh;
  overflow: hidden;
}

.app-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 8px 16px;
  background: #323233;
  border-bottom: 1px solid #3c3c3c;
}

.header-left {
  display: flex;
  align-items: center;
  gap: 12px;
}

.app-logo {
  width: 32px;
  height: 32px;
}

.app-title {
  font-size: 18px;
  font-weight: 600;
  color: #ffffff;
}

.app-subtitle {
  font-size: 12px;
  color: #858585;
}

.header-right {
  display: flex;
  align-items: center;
  gap: 16px;
}

.header-btn {
  padding: 6px 12px;
  background: #3c3c3c;
  border: none;
  border-radius: 4px;
  color: #cccccc;
  font-size: 12px;
  cursor: pointer;
}

.header-btn:hover {
  background: #4c4c4c;
}

.header-link {
  color: #3794ff;
  text-decoration: none;
  font-size: 13px;
}

.header-link:hover {
  text-decoration: underline;
}

.loading-overlay,
.error-overlay {
  flex: 1;
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  gap: 16px;
}

.loading-spinner {
  width: 40px;
  height: 40px;
  border: 3px solid #3c3c3c;
  border-top-color: #0e639c;
  border-radius: 50%;
  animation: spin 1s linear infinite;
}

@keyframes spin {
  to {
    transform: rotate(360deg);
  }
}

.error-overlay {
  color: #f14c4c;
}

.main-content {
  flex: 1;
  display: flex;
  overflow: hidden;
  gap: 8px;
  padding: 8px;
}

.sidebar {
  width: 200px;
  flex-shrink: 0;
}

.editor-panel {
  flex: 1;
  min-width: 300px;
}

.resize-handle {
  width: 8px;
  flex-shrink: 0;
  cursor: col-resize;
  display: flex;
  align-items: center;
  justify-content: center;
  background: transparent;
  transition: background 0.15s;
}

.resize-handle:hover {
  background: rgba(55, 148, 255, 0.2);
}

.resize-grip {
  width: 4px;
  height: 40px;
  background: #3c3c3c;
  border-radius: 2px;
  transition: background 0.15s;
}

.resize-handle:hover .resize-grip {
  background: #3794ff;
}

.main-content.resizing {
  cursor: col-resize;
  user-select: none;
}

.main-content.resizing .resize-handle {
  background: rgba(55, 148, 255, 0.3);
}

.main-content.resizing .resize-grip {
  background: #3794ff;
}

.preview-panel {
  flex-shrink: 0;
  display: flex;
  flex-direction: column;
  gap: 8px;
}

.staff-section {
  flex: 1;
  min-height: 200px;
}

.player-section {
  flex-shrink: 0;
}

@media (max-width: 1000px) {
  .main-content {
    flex-direction: column;
  }

  .sidebar {
    width: 100%;
    height: 150px;
  }

  .editor-panel {
    min-width: auto;
    flex: 1;
  }

  .resize-handle {
    display: none;
  }

  .preview-panel {
    width: 100% !important;
    height: 250px;
  }
}
</style>
