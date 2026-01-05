<script setup lang="ts">
import type { WasmDiagnostic, StaffData, RenderResult, AudioPlaybackData, ViewMode } from "../types/relanote";
import { DawView } from "../features/daw";

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
const { showCopied, getCodeFromUrl, share, clearShare } = useShare();

const diagnostics = ref<WasmDiagnostic[]>([]);
const staffData = ref<StaffData | null>(null);
const audioData = ref<AudioPlaybackData | null>(null);
const midiResult = ref<RenderResult | null>(null);
const currentBeat = ref(0);
const analysisDebounce = ref<ReturnType<typeof setTimeout> | null>(null);

// View mode state
const viewMode = ref<ViewMode>("pianoroll");

// Resizable panels (for split view)
const splitRatio = ref(0.6); // 60% top, 40% bottom
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
  const newRatio = (e.clientY - containerRect.top) / containerRect.height;

  // Clamp between 30% and 80%
  splitRatio.value = Math.min(Math.max(newRatio, 0.3), 0.8);
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

const handleCodeUpdate = (newCode: string) => {
  code.value = newCode;
};

const handleShare = async () => {
  await share(code.value);
};

// Track if code was loaded from URL
const loadedFromUrl = ref(false);

onMounted(async () => {
  // Check for shared code in URL first
  const sharedCode = getCodeFromUrl();
  if (sharedCode) {
    loadedFromUrl.value = true;
  }

  loadFromStorage();

  // If we have shared code, update the active file
  if (sharedCode && activeFile.value) {
    updateContent(activeFile.value.id, sharedCode);
  }

  await init();
  if (isReady.value) {
    analyzeCode();
  }
});

// Clear share state when code changes (user is editing)
watch(code, () => {
  if (!loadedFromUrl.value) {
    clearShare();
  }
  loadedFromUrl.value = false;
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
        <img src="/logo-transparent.svg" alt="Relanote" class="app-logo" />
        <h1 class="app-title">Relanote</h1>
        <span class="app-subtitle">Functional Music Notation</span>
      </div>
      <div class="header-right">
        <button class="header-btn share-btn" @click="handleShare" title="Share code via URL">
          <svg viewBox="0 0 24 24" fill="currentColor" class="share-icon">
            <path d="M18 16.08c-.76 0-1.44.3-1.96.77L8.91 12.7c.05-.23.09-.46.09-.7s-.04-.47-.09-.7l7.05-4.11c.54.5 1.25.81 2.04.81 1.66 0 3-1.34 3-3s-1.34-3-3-3-3 1.34-3 3c0 .24.04.47.09.7L8.04 9.81C7.5 9.31 6.79 9 6 9c-1.66 0-3 1.34-3 3s1.34 3 3 3c.79 0 1.5-.31 2.04-.81l7.12 4.16c-.05.21-.08.43-.08.65 0 1.61 1.31 2.92 2.92 2.92s2.92-1.31 2.92-2.92-1.31-2.92-2.92-2.92z"/>
          </svg>
          {{ showCopied ? 'Copied!' : 'Share' }}
        </button>
        <button class="header-btn" @click="handleExportMidi" :disabled="!midiResult?.midi_data">
          Export MIDI
        </button>
        <button class="header-btn" @click="exportAllFiles" title="Export All Files">
          Export Project
        </button>
        <a
          class="header-link"
          href="https://github.com/ubugeeei/relanote/tree/main/examples"
          target="_blank"
          rel="noopener"
        >
          Examples
        </a>
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
      <!-- DAW View (Top Panel) -->
      <div class="daw-panel" :style="{ height: `${splitRatio * 100}%` }">
        <DawView
          :code="code"
          :audio-data="audioData"
          @update:code="handleCodeUpdate"
        />
      </div>

      <!-- Resize Handle -->
      <div class="resize-handle-h" @mousedown="startResize">
        <div class="resize-grip-h" />
      </div>

      <!-- Code Editor Panel (Bottom Panel - like VS Code terminal) -->
      <div class="editor-panel" :style="{ height: `${(1 - splitRatio) * 100}%` }">
        <div class="editor-header">
          <div class="editor-tabs">
            <div class="editor-tab active">
              <span class="tab-icon">{ }</span>
              <span class="tab-name">{{ activeFile?.name || 'untitled.rela' }}</span>
            </div>
          </div>
          <div class="editor-actions">
            <button class="editor-action-btn" @click="handleFormat" title="Format Code">
              <svg viewBox="0 0 24 24" fill="currentColor">
                <path d="M3 21h18v-2H3v2zm0-4h18v-2H3v2zm0-4h18v-2H3v2zm0-4h18V7H3v2zm0-6v2h18V3H3z"/>
              </svg>
            </button>
          </div>
        </div>
        <div class="editor-content">
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

          <!-- Editor -->
          <div class="code-editor-wrapper">
            <CodeEditor
              v-model="code"
              :diagnostics="diagnostics"
              :file-name="activeFile?.name"
              @format="handleFormat"
            />
          </div>
        </div>
      </div>
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
  flex-shrink: 0;
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
  gap: 12px;
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

.header-btn:hover:not(:disabled) {
  background: #4c4c4c;
}

.header-btn:disabled {
  opacity: 0.5;
  cursor: not-allowed;
}

.share-btn {
  display: flex;
  align-items: center;
  gap: 6px;
}

.share-btn .share-icon {
  width: 14px;
  height: 14px;
}

.share-btn:hover {
  background: #d97706;
  color: #ffffff;
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
  flex-direction: column;
  overflow: hidden;
}

.main-content.resizing {
  cursor: row-resize;
  user-select: none;
}

.daw-panel {
  min-height: 200px;
  overflow: hidden;
}

.resize-handle-h {
  height: 8px;
  flex-shrink: 0;
  cursor: row-resize;
  display: flex;
  align-items: center;
  justify-content: center;
  background: #252526;
  transition: background 0.15s;
}

.resize-handle-h:hover {
  background: rgba(55, 148, 255, 0.2);
}

.resize-grip-h {
  width: 40px;
  height: 4px;
  background: #3c3c3c;
  border-radius: 2px;
  transition: background 0.15s;
}

.resize-handle-h:hover .resize-grip-h {
  background: #3794ff;
}

.editor-panel {
  display: flex;
  flex-direction: column;
  min-height: 100px;
  background: #1e1e1e;
  border-top: 1px solid #3c3c3c;
}

.editor-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 0 8px;
  background: #252526;
  border-bottom: 1px solid #3c3c3c;
  height: 35px;
}

.editor-tabs {
  display: flex;
  gap: 1px;
}

.editor-tab {
  display: flex;
  align-items: center;
  gap: 6px;
  padding: 6px 12px;
  background: #2d2d2d;
  color: #858585;
  font-size: 12px;
  cursor: pointer;
  border-top: 2px solid transparent;
}

.editor-tab.active {
  background: #1e1e1e;
  color: #cccccc;
  border-top-color: #d97706;
}

.tab-icon {
  font-size: 11px;
  opacity: 0.7;
}

.tab-name {
  max-width: 150px;
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
}

.editor-actions {
  display: flex;
  gap: 4px;
}

.editor-action-btn {
  width: 28px;
  height: 28px;
  display: flex;
  align-items: center;
  justify-content: center;
  background: transparent;
  border: none;
  border-radius: 4px;
  color: #858585;
  cursor: pointer;
}

.editor-action-btn:hover {
  background: #3c3c3c;
  color: #cccccc;
}

.editor-action-btn svg {
  width: 16px;
  height: 16px;
}

.editor-content {
  flex: 1;
  display: flex;
  overflow: hidden;
}

.sidebar {
  width: 180px;
  flex-shrink: 0;
  border-right: 1px solid #3c3c3c;
}

.code-editor-wrapper {
  flex: 1;
  min-width: 0;
}

@media (max-width: 1000px) {
  .main-content {
    flex-direction: column;
  }

  .daw-panel {
    height: 60% !important;
  }

  .preview-panel {
    height: 40% !important;
  }
}
</style>
