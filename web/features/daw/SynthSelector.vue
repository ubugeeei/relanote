<script setup lang="ts">
const props = defineProps<{
  selectedSynth: string;
}>();

const emit = defineEmits<{
  "update:selectedSynth": [synth: string];
  preview: [synth: string];
}>();

const isOpen = ref(false);
const searchQuery = ref("");
const dropdownRef = ref<HTMLElement | null>(null);

// Synth categories and presets
const synthCategories = [
  {
    name: "Piano & Keys",
    synths: [
      "AcousticPiano",
      "BrightPiano",
      "MellowPiano",
      "Rhodes",
      "Wurlitzer",
      "DXPiano",
      "Clavinet",
      "Organ",
    ],
  },
  {
    name: "Bass",
    synths: [
      "WoodBass",
      "ElectricBass",
      "SynthBass",
      "SubBass",
      "AcidBass",
      "ReeseBass",
      "FatBass",
    ],
  },
  {
    name: "Brass & Winds",
    synths: [
      "Trumpet",
      "MutedTrumpet",
      "Trombone",
      "FrenchHorn",
      "Brass",
      "BrassSection",
    ],
  },
  {
    name: "Leads",
    synths: ["Lead", "SoftPad", "Strings", "Pluck"],
  },
  {
    name: "Drums - Kick",
    synths: ["Kick", "DeepKick", "PunchyKick", "SubKick", "HardKick", "SoftKick"],
  },
  {
    name: "Drums - Snare",
    synths: ["Snare", "TightSnare", "FatSnare", "CrispSnare", "RimShot", "SideStick"],
  },
  {
    name: "Drums - Hi-Hat",
    synths: ["HiHat", "OpenHat", "ClosedHat", "OpenHiHat", "PedalHat", "TightHat"],
  },
  {
    name: "Drums - Tom & Cymbal",
    synths: ["Tom", "HighTom", "MidTom", "FloorTom", "LowTom", "CrashCymbal", "Clap"],
  },
  {
    name: "Retro / 8-bit",
    synths: ["Chiptune", "Chip8bit", "NES", "GameBoy", "Kick8bit", "Snare8bit", "HiHat8bit"],
  },
];

const filteredCategories = computed(() => {
  if (!searchQuery.value) return synthCategories;

  const query = searchQuery.value.toLowerCase();
  return synthCategories
    .map((cat) => ({
      ...cat,
      synths: cat.synths.filter((s) => s.toLowerCase().includes(query)),
    }))
    .filter((cat) => cat.synths.length > 0);
});

const selectSynth = (synth: string) => {
  emit("update:selectedSynth", synth);
  isOpen.value = false;
  searchQuery.value = "";
};

const handlePreview = (synth: string, e: MouseEvent) => {
  e.stopPropagation();
  emit("preview", synth);
};

// Close on click outside
const handleClickOutside = (e: MouseEvent) => {
  if (dropdownRef.value && !dropdownRef.value.contains(e.target as Node)) {
    isOpen.value = false;
  }
};

onMounted(() => {
  document.addEventListener("click", handleClickOutside);
});

onUnmounted(() => {
  document.removeEventListener("click", handleClickOutside);
});
</script>

<template>
  <div ref="dropdownRef" class="synth-selector">
    <button class="selector-button" @click="isOpen = !isOpen">
      <span class="synth-name">{{ selectedSynth }}</span>
      <svg class="chevron" :class="{ open: isOpen }" viewBox="0 0 24 24" fill="currentColor">
        <path d="M7 10l5 5 5-5H7z" />
      </svg>
    </button>

    <div v-if="isOpen" class="dropdown">
      <div class="search-box">
        <input
          v-model="searchQuery"
          type="text"
          placeholder="Search synths..."
          class="search-input"
          @click.stop
        />
      </div>

      <div class="synth-list">
        <div
          v-for="category in filteredCategories"
          :key="category.name"
          class="category"
        >
          <div class="category-name">{{ category.name }}</div>
          <div class="synth-items">
            <div
              v-for="synth in category.synths"
              :key="synth"
              class="synth-item"
              :class="{ selected: synth === selectedSynth }"
              @click="selectSynth(synth)"
            >
              <span class="item-name">{{ synth }}</span>
              <button
                class="preview-btn"
                @click="handlePreview(synth, $event)"
                title="Preview"
              >
                <svg viewBox="0 0 24 24" fill="currentColor">
                  <path d="M8 5v14l11-7L8 5z" />
                </svg>
              </button>
            </div>
          </div>
        </div>

        <div v-if="filteredCategories.length === 0" class="no-results">
          No synths found
        </div>
      </div>
    </div>
  </div>
</template>

<style scoped>
.synth-selector {
  position: relative;
}

.selector-button {
  display: flex;
  align-items: center;
  gap: 8px;
  padding: 6px 12px;
  background: #3c3c3c;
  border: 1px solid #4c4c4c;
  border-radius: 4px;
  color: #cccccc;
  font-size: 12px;
  cursor: pointer;
  min-width: 140px;
}

.selector-button:hover {
  background: #4c4c4c;
}

.synth-name {
  flex: 1;
  text-align: left;
}

.chevron {
  width: 16px;
  height: 16px;
  transition: transform 0.15s;
}

.chevron.open {
  transform: rotate(180deg);
}

.dropdown {
  position: absolute;
  top: 100%;
  left: 0;
  margin-top: 4px;
  width: 280px;
  max-height: 400px;
  background: #252526;
  border: 1px solid #3c3c3c;
  border-radius: 6px;
  box-shadow: 0 8px 24px rgba(0, 0, 0, 0.4);
  z-index: 100;
  overflow: hidden;
}

.search-box {
  padding: 8px;
  border-bottom: 1px solid #3c3c3c;
}

.search-input {
  width: 100%;
  padding: 6px 10px;
  background: #3c3c3c;
  border: 1px solid #4c4c4c;
  border-radius: 4px;
  color: #cccccc;
  font-size: 12px;
}

.search-input:focus {
  outline: none;
  border-color: #0e639c;
}

.synth-list {
  max-height: 340px;
  overflow-y: auto;
}

.category {
  padding: 8px 0;
  border-bottom: 1px solid #2d2d2d;
}

.category:last-child {
  border-bottom: none;
}

.category-name {
  padding: 4px 12px;
  font-size: 10px;
  font-weight: 600;
  text-transform: uppercase;
  color: #858585;
  letter-spacing: 0.5px;
}

.synth-items {
  display: flex;
  flex-direction: column;
}

.synth-item {
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding: 6px 12px;
  cursor: pointer;
  transition: background 0.1s;
}

.synth-item:hover {
  background: #2d2d2d;
}

.synth-item.selected {
  background: #37373d;
}

.synth-item.selected .item-name {
  color: #d97706;
}

.item-name {
  font-size: 12px;
  color: #cccccc;
}

.preview-btn {
  width: 22px;
  height: 22px;
  display: flex;
  align-items: center;
  justify-content: center;
  background: transparent;
  border: none;
  border-radius: 3px;
  color: #666666;
  cursor: pointer;
  opacity: 0;
  transition: opacity 0.1s, background 0.1s;
}

.synth-item:hover .preview-btn {
  opacity: 1;
}

.preview-btn:hover {
  background: #3c3c3c;
  color: #d97706;
}

.preview-btn svg {
  width: 12px;
  height: 12px;
}

.no-results {
  padding: 16px;
  text-align: center;
  color: #666666;
  font-size: 12px;
}
</style>
