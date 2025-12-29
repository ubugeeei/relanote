<script setup lang="ts">
import type { RelaFile } from "../composables/useFileManager";

const props = defineProps<{
  files: RelaFile[];
  activeFileId: string | null;
}>();

const emit = defineEmits<{
  selectFile: [id: string];
  createFile: [];
  deleteFile: [id: string];
  renameFile: [id: string, name: string];
  exportFile: [id: string];
  importFile: [file: File];
}>();

const editingId = ref<string | null>(null);
const editingName = ref("");
const contextMenuId = ref<string | null>(null);
const contextMenuPos = ref({ x: 0, y: 0 });
const fileInputRef = ref<HTMLInputElement | null>(null);

const startRename = (file: RelaFile) => {
  editingId.value = file.id;
  editingName.value = file.name.replace(".rela", "");
  contextMenuId.value = null;
};

const finishRename = () => {
  if (editingId.value && editingName.value.trim()) {
    emit("renameFile", editingId.value, editingName.value.trim());
  }
  editingId.value = null;
  editingName.value = "";
};

const cancelRename = () => {
  editingId.value = null;
  editingName.value = "";
};

const showContextMenu = (event: MouseEvent, fileId: string) => {
  event.preventDefault();
  contextMenuId.value = fileId;
  contextMenuPos.value = { x: event.clientX, y: event.clientY };
};

const closeContextMenu = () => {
  contextMenuId.value = null;
};

const handleDelete = (id: string) => {
  if (confirm("Are you sure you want to delete this file?")) {
    emit("deleteFile", id);
  }
  closeContextMenu();
};

const handleImportClick = () => {
  fileInputRef.value?.click();
};

const handleFileInput = (event: Event) => {
  const input = event.target as HTMLInputElement;
  const file = input.files?.[0];
  if (file) {
    emit("importFile", file);
  }
  input.value = "";
};

const formatDate = (timestamp: number) => {
  return new Date(timestamp).toLocaleDateString();
};

onMounted(() => {
  document.addEventListener("click", closeContextMenu);
});

onUnmounted(() => {
  document.removeEventListener("click", closeContextMenu);
});
</script>

<template>
  <div class="file-tree">
    <div class="file-tree-header">
      <span class="file-tree-title">Files</span>
      <div class="file-tree-actions">
        <button class="icon-btn" @click="handleImportClick" title="Import">
          <span>↓</span>
        </button>
        <button class="icon-btn" @click="$emit('createFile')" title="New File">
          <span>+</span>
        </button>
      </div>
    </div>

    <input
      ref="fileInputRef"
      type="file"
      accept=".rela,.json"
      style="display: none"
      @change="handleFileInput"
    />

    <div class="file-list">
      <div
        v-for="file in files"
        :key="file.id"
        class="file-item"
        :class="{ active: file.id === activeFileId }"
        @click="$emit('selectFile', file.id)"
        @contextmenu="showContextMenu($event, file.id)"
      >
        <span class="file-icon">📄</span>
        <template v-if="editingId === file.id">
          <input
            v-model="editingName"
            class="rename-input"
            @blur="finishRename"
            @keyup.enter="finishRename"
            @keyup.escape="cancelRename"
            @click.stop
            autofocus
          />
        </template>
        <template v-else>
          <span class="file-name">{{ file.name }}</span>
          <span class="file-date">{{ formatDate(file.updatedAt) }}</span>
        </template>
      </div>
    </div>

    <!-- Context Menu -->
    <Teleport to="body">
      <div
        v-if="contextMenuId"
        class="context-menu"
        :style="{ left: contextMenuPos.x + 'px', top: contextMenuPos.y + 'px' }"
        @click.stop
      >
        <button class="context-item" @click="startRename(files.find(f => f.id === contextMenuId)!)">
          Rename
        </button>
        <button class="context-item" @click="$emit('exportFile', contextMenuId!); closeContextMenu()">
          Export
        </button>
        <button
          class="context-item danger"
          @click="handleDelete(contextMenuId!)"
          :disabled="files.length <= 1"
        >
          Delete
        </button>
      </div>
    </Teleport>
  </div>
</template>

<style scoped>
.file-tree {
  display: flex;
  flex-direction: column;
  height: 100%;
  background: #252526;
  border-radius: 8px;
  overflow: hidden;
}

.file-tree-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 8px 12px;
  border-bottom: 1px solid #3c3c3c;
}

.file-tree-title {
  color: #cccccc;
  font-size: 13px;
  font-weight: 500;
}

.file-tree-actions {
  display: flex;
  gap: 4px;
}

.icon-btn {
  width: 24px;
  height: 24px;
  display: flex;
  align-items: center;
  justify-content: center;
  background: transparent;
  border: none;
  color: #cccccc;
  cursor: pointer;
  border-radius: 4px;
  font-size: 14px;
}

.icon-btn:hover {
  background: #3c3c3c;
}

.file-list {
  flex: 1;
  overflow-y: auto;
  padding: 4px 0;
}

.file-item {
  display: flex;
  align-items: center;
  gap: 8px;
  padding: 6px 12px;
  cursor: pointer;
  color: #cccccc;
}

.file-item:hover {
  background: #2a2d2e;
}

.file-item.active {
  background: #37373d;
}

.file-icon {
  font-size: 14px;
}

.file-name {
  flex: 1;
  font-size: 13px;
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
}

.file-date {
  font-size: 11px;
  color: #666666;
}

.rename-input {
  flex: 1;
  padding: 2px 4px;
  background: #3c3c3c;
  border: 1px solid #007acc;
  color: #cccccc;
  font-size: 13px;
  border-radius: 2px;
  outline: none;
}

.context-menu {
  position: fixed;
  background: #252526;
  border: 1px solid #454545;
  border-radius: 6px;
  box-shadow: 0 4px 12px rgba(0, 0, 0, 0.4);
  padding: 4px 0;
  min-width: 120px;
  z-index: 1000;
}

.context-item {
  display: block;
  width: 100%;
  padding: 6px 12px;
  background: transparent;
  border: none;
  color: #cccccc;
  font-size: 13px;
  text-align: left;
  cursor: pointer;
}

.context-item:hover:not(:disabled) {
  background: #094771;
}

.context-item.danger {
  color: #f14c4c;
}

.context-item:disabled {
  color: #666666;
  cursor: not-allowed;
}
</style>
