<script setup lang="ts">
const props = defineProps<{
  tool: "select" | "draw" | "erase";
  gridSnap: number;
  gridSnapOptions: Array<{ label: string; value: number }>;
}>();

const emit = defineEmits<{
  "update:tool": [tool: "select" | "draw" | "erase"];
  "update:gridSnap": [snap: number];
  zoomIn: [];
  zoomOut: [];
}>();
</script>

<template>
  <div class="toolbar">
    <div class="tool-group">
      <button
        class="tool-btn"
        :class="{ active: tool === 'select' }"
        @click="$emit('update:tool', 'select')"
        title="Select Tool (V)"
      >
        <svg viewBox="0 0 24 24" fill="currentColor">
          <path d="M7 2l12 11.2-5.8.5 3.3 7.3-2.2 1-3.2-7.4L7 18V2z" />
        </svg>
      </button>
      <button
        class="tool-btn"
        :class="{ active: tool === 'draw' }"
        @click="$emit('update:tool', 'draw')"
        title="Draw Tool (D)"
      >
        <svg viewBox="0 0 24 24" fill="currentColor">
          <path d="M3 17.25V21h3.75L17.81 9.94l-3.75-3.75L3 17.25zM20.71 7.04c.39-.39.39-1.02 0-1.41l-2.34-2.34a.9959.9959 0 0 0-1.41 0l-1.83 1.83 3.75 3.75 1.83-1.83z" />
        </svg>
      </button>
      <button
        class="tool-btn"
        :class="{ active: tool === 'erase' }"
        @click="$emit('update:tool', 'erase')"
        title="Erase Tool (E)"
      >
        <svg viewBox="0 0 24 24" fill="currentColor">
          <path d="M15.14 3c-.51 0-1.02.2-1.41.59L2.59 14.73c-.78.78-.78 2.05 0 2.83l4.24 4.24c.39.39.9.59 1.41.59h9.26c.53 0 1.04-.21 1.41-.59l2.59-2.59c.78-.78.78-2.05 0-2.83L12.72 7.6l5.05-5.05c.78-.78.78-2.05 0-2.83-.39-.39-.9-.58-1.41-.58-.51 0-1.02.2-1.41.59L13.14 2l1.41 1.41L17 5.86 6.17 16.69l-2.83-2.83L14.17 3l.97.97z" />
        </svg>
      </button>
    </div>

    <div class="separator" />

    <div class="grid-group">
      <span class="grid-label">Grid</span>
      <select
        class="grid-select"
        :value="gridSnap"
        @change="$emit('update:gridSnap', parseFloat(($event.target as HTMLSelectElement).value))"
      >
        <option
          v-for="option in gridSnapOptions"
          :key="option.value"
          :value="option.value"
        >
          {{ option.label }}
        </option>
      </select>
    </div>

    <div class="separator" />

    <div class="zoom-group">
      <button class="tool-btn small" @click="$emit('zoomOut')" title="Zoom Out">
        <svg viewBox="0 0 24 24" fill="currentColor">
          <path d="M19 13H5v-2h14v2z" />
        </svg>
      </button>
      <button class="tool-btn small" @click="$emit('zoomIn')" title="Zoom In">
        <svg viewBox="0 0 24 24" fill="currentColor">
          <path d="M19 13h-6v6h-2v-6H5v-2h6V5h2v6h6v2z" />
        </svg>
      </button>
    </div>

  </div>
</template>

<style scoped>
.toolbar {
  display: flex;
  align-items: center;
  gap: 8px;
  padding: 6px 12px;
  background: #2d2d2d;
  border-bottom: 1px solid #3c3c3c;
}

.tool-group {
  display: flex;
  gap: 2px;
  background: #1e1e1e;
  border-radius: 4px;
  padding: 2px;
}

.tool-btn {
  width: 28px;
  height: 28px;
  display: flex;
  align-items: center;
  justify-content: center;
  background: transparent;
  border: none;
  border-radius: 3px;
  color: #858585;
  cursor: pointer;
  transition: all 0.15s;
}

.tool-btn:hover {
  background: #3c3c3c;
  color: #cccccc;
}

.tool-btn.active {
  background: #0e639c;
  color: white;
}

.tool-btn svg {
  width: 16px;
  height: 16px;
}

.tool-btn.small {
  width: 24px;
  height: 24px;
}

.tool-btn.small svg {
  width: 14px;
  height: 14px;
}

.separator {
  width: 1px;
  height: 24px;
  background: #3c3c3c;
  margin: 0 4px;
}

.grid-group {
  display: flex;
  align-items: center;
  gap: 6px;
}

.grid-label {
  font-size: 11px;
  color: #858585;
}

.grid-select {
  height: 26px;
  padding: 0 8px;
  background: #3c3c3c;
  border: 1px solid #4c4c4c;
  border-radius: 4px;
  color: #cccccc;
  font-size: 12px;
  cursor: pointer;
}

.grid-select:focus {
  outline: none;
  border-color: #0e639c;
}

.zoom-group {
  display: flex;
  gap: 2px;
}
</style>
