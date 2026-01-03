<script setup lang="ts">
import type * as Monaco from "monaco-editor";
import type { WasmDiagnostic } from "../types/relanote";
import { registerRelanoteLanguage } from "../utils/monaco-relanote";

const props = defineProps<{
  modelValue: string;
  diagnostics: WasmDiagnostic[];
  fileName?: string;
}>();

const emit = defineEmits<{
  "update:modelValue": [value: string];
  format: [];
}>();

const editorContainer = ref<HTMLDivElement | null>(null);
let editor: Monaco.editor.IStandaloneCodeEditor | null = null;
let monaco: typeof Monaco | null = null;

const initMonaco = async () => {
  if (!editorContainer.value) return;

  // Dynamically import Monaco to avoid SSR issues
  monaco = await import("monaco-editor");

  // Register Relanote language
  registerRelanoteLanguage(monaco);

  // Create editor
  editor = monaco.editor.create(editorContainer.value, {
    value: props.modelValue,
    language: "relanote",
    theme: "relanote-dark",
    automaticLayout: true,
    minimap: { enabled: false },
    fontSize: 14,
    fontFamily: "'Fira Code', 'Consolas', 'Monaco', monospace",
    fontLigatures: true,
    lineNumbers: "on",
    renderLineHighlight: "all",
    scrollBeyondLastLine: false,
    padding: { top: 12, bottom: 12 },
    tabSize: 2,
    insertSpaces: true,
    wordWrap: "off",
    bracketPairColorization: { enabled: true },
    cursorBlinking: "smooth",
    cursorSmoothCaretAnimation: "on",
    smoothScrolling: true,
    formatOnPaste: true,
    quickSuggestions: {
      other: true,
      comments: false,
      strings: false,
    },
    suggestOnTriggerCharacters: true,
    acceptSuggestionOnEnter: "on",
    snippetSuggestions: "top",
  });

  // Listen for content changes
  editor.onDidChangeModelContent(() => {
    const value = editor?.getValue() || "";
    emit("update:modelValue", value);
  });

  // Add format command
  editor.addAction({
    id: "relanote.format",
    label: "Format Document",
    keybindings: [monaco.KeyMod.CtrlCmd | monaco.KeyCode.KeyS],
    run: () => {
      emit("format");
    },
  });
};

// Update diagnostics (markers) in the editor
const updateMarkers = () => {
  if (!editor || !monaco) return;

  const model = editor.getModel();
  if (!model) return;

  const markers: Monaco.editor.IMarkerData[] = props.diagnostics.map((diag) => {
    const startPos = model.getPositionAt(diag.start);
    const endPos = model.getPositionAt(diag.end);

    return {
      severity:
        diag.severity === "error"
          ? monaco!.MarkerSeverity.Error
          : diag.severity === "warning"
            ? monaco!.MarkerSeverity.Warning
            : monaco!.MarkerSeverity.Info,
      message: diag.message,
      startLineNumber: startPos.lineNumber,
      startColumn: startPos.column,
      endLineNumber: endPos.lineNumber,
      endColumn: endPos.column,
    };
  });

  monaco.editor.setModelMarkers(model, "relanote", markers);
};

// Update editor content when modelValue changes externally
watch(
  () => props.modelValue,
  (newValue) => {
    if (editor && editor.getValue() !== newValue) {
      const position = editor.getPosition();
      editor.setValue(newValue);
      if (position) {
        editor.setPosition(position);
      }
    }
  }
);

// Update markers when diagnostics change
watch(
  () => props.diagnostics,
  () => updateMarkers(),
  { deep: true }
);

onMounted(() => {
  initMonaco();
});

onUnmounted(() => {
  editor?.dispose();
});
</script>

<template>
  <div class="editor-container">
    <div class="editor-header">
      <span class="editor-title">{{ fileName || "editor.rela" }}</span>
      <div class="editor-actions">
        <button class="format-btn" @click="$emit('format')" title="Format (Ctrl+S)">
          Format
        </button>
      </div>
    </div>
    <div ref="editorContainer" class="monaco-editor-container" />
    <div v-if="diagnostics.length > 0" class="diagnostics-panel">
      <div class="diagnostics-header">
        Problems ({{ diagnostics.length }})
      </div>
      <div class="diagnostics-list">
        <div
          v-for="(diag, i) in diagnostics"
          :key="i"
          class="diagnostic-item"
          :class="diag.severity"
        >
          <span class="diagnostic-icon">{{
            diag.severity === "error" ? "✕" : diag.severity === "warning" ? "⚠" : "ℹ"
          }}</span>
          <span class="diagnostic-message">{{ diag.message }}</span>
          <span class="diagnostic-pos">[{{ diag.start }}-{{ diag.end }}]</span>
        </div>
      </div>
    </div>
  </div>
</template>

<style scoped>
.editor-container {
  display: flex;
  flex-direction: column;
  height: 100%;
  background: #1e1e1e;
  border-radius: 8px;
  overflow: hidden;
}

.editor-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 8px 12px;
  background: #252526;
  border-bottom: 1px solid #3c3c3c;
}

.editor-title {
  color: #cccccc;
  font-size: 13px;
}

.editor-actions {
  display: flex;
  gap: 8px;
}

.format-btn {
  padding: 4px 12px;
  background: #0e639c;
  color: white;
  border: none;
  border-radius: 4px;
  cursor: pointer;
  font-size: 12px;
  transition: background 0.2s;
}

.format-btn:hover {
  background: #1177bb;
}

.monaco-editor-container {
  flex: 1;
  min-height: 200px;
}

.diagnostics-panel {
  max-height: 150px;
  display: flex;
  flex-direction: column;
  background: #1e1e1e;
  border-top: 1px solid #3c3c3c;
}

.diagnostics-header {
  padding: 6px 12px;
  background: #252526;
  color: #cccccc;
  font-size: 12px;
  font-weight: 500;
  border-bottom: 1px solid #3c3c3c;
}

.diagnostics-list {
  overflow-y: auto;
  padding: 4px 0;
}

.diagnostic-item {
  display: flex;
  align-items: flex-start;
  gap: 8px;
  padding: 4px 12px;
  font-size: 12px;
  color: #cccccc;
  cursor: pointer;
}

.diagnostic-item:hover {
  background: #2a2d2e;
}

.diagnostic-item.error {
  color: #f14c4c;
}

.diagnostic-item.warning {
  color: #cca700;
}

.diagnostic-item.info {
  color: #3794ff;
}

.diagnostic-icon {
  flex-shrink: 0;
  width: 16px;
  text-align: center;
}

.diagnostic-message {
  flex: 1;
  word-break: break-word;
}

.diagnostic-pos {
  flex-shrink: 0;
  color: #666666;
  font-family: monospace;
  font-size: 11px;
}
</style>
