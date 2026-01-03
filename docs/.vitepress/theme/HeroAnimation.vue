<script setup lang="ts">
import { onMounted, ref } from 'vue'

const isVisible = ref(false)

onMounted(() => {
  setTimeout(() => {
    isVisible.value = true
  }, 300)
})
</script>

<template>
  <div class="hero-animation" :class="{ visible: isVisible }">
    <svg viewBox="0 0 600 260" xmlns="http://www.w3.org/2000/svg">
      <defs>
        <!-- Gradients -->
        <linearGradient id="bgBlockGradient" x1="0%" y1="0%" x2="100%" y2="100%">
          <stop offset="0%" class="block-stop-1" />
          <stop offset="100%" class="block-stop-2" />
        </linearGradient>
        <linearGradient id="bgNoteGradient" x1="0%" y1="0%" x2="0%" y2="100%">
          <stop offset="0%" class="note-stop-1" />
          <stop offset="100%" class="note-stop-2" />
        </linearGradient>
        <linearGradient id="bgFlowGradient" x1="0%" y1="0%" x2="100%" y2="0%">
          <stop offset="0%" class="flow-stop-1" />
          <stop offset="50%" class="flow-stop-2" />
          <stop offset="100%" class="flow-stop-3" />
        </linearGradient>

        <!-- Glow filter -->
        <filter id="bgGlow" x="-50%" y="-50%" width="200%" height="200%">
          <feGaussianBlur stdDeviation="6" result="coloredBlur"/>
          <feMerge>
            <feMergeNode in="coloredBlur"/>
            <feMergeNode in="SourceGraphic"/>
          </feMerge>
        </filter>
      </defs>

      <!-- Rhythm bars (top) -->
      <g class="rhythm-indicator">
        <rect x="110" y="25" width="70" height="6" rx="3" class="rhythm-bar rhythm-1"/>
        <rect x="190" y="25" width="70" height="6" rx="3" class="rhythm-bar rhythm-2"/>
        <rect x="270" y="25" width="70" height="6" rx="3" class="rhythm-bar rhythm-3"/>
        <rect x="350" y="25" width="70" height="6" rx="3" class="rhythm-bar rhythm-4"/>
      </g>

      <!-- Interval labels -->
      <g class="interval-labels">
        <text x="170" y="60" text-anchor="middle" class="interval-text">M3</text>
        <text x="255" y="55" text-anchor="middle" class="interval-text">M3</text>
        <text x="345" y="55" text-anchor="middle" class="interval-text">m3</text>
        <text x="430" y="60" text-anchor="middle" class="interval-text">m3</text>
      </g>

      <!-- Background staff lines -->
      <g class="staff-lines">
        <line x1="50" y1="100" x2="550" y2="100" stroke-width="1.5"/>
        <line x1="50" y1="130" x2="550" y2="130" stroke-width="1.5"/>
        <line x1="50" y1="160" x2="550" y2="160" stroke-width="1.5"/>
        <line x1="50" y1="190" x2="550" y2="190" stroke-width="1.5"/>
        <line x1="50" y1="220" x2="550" y2="220" stroke-width="1.5"/>
      </g>

      <!-- Block pipes -->
      <g class="block-container">
        <rect x="70" y="85" width="10" height="150" rx="5" fill="url(#bgBlockGradient)" class="pipe-left"/>
        <rect x="520" y="85" width="10" height="150" rx="5" fill="url(#bgBlockGradient)" class="pipe-right"/>
      </g>

      <!-- Large flowing notes -->
      <g class="notes" filter="url(#bgGlow)">
        <g class="note note-1">
          <ellipse cx="130" cy="200" rx="20" ry="16" fill="url(#bgNoteGradient)"/>
          <text x="130" y="206" text-anchor="middle" class="note-text">1</text>
        </g>

        <g class="note note-2">
          <ellipse cx="210" cy="155" rx="20" ry="16" fill="url(#bgNoteGradient)"/>
          <text x="210" y="161" text-anchor="middle" class="note-text">3</text>
        </g>

        <g class="note note-3">
          <ellipse cx="300" cy="110" rx="20" ry="16" fill="url(#bgNoteGradient)"/>
          <text x="300" y="116" text-anchor="middle" class="note-text">5</text>
        </g>

        <g class="note note-4">
          <ellipse cx="390" cy="155" rx="20" ry="16" fill="url(#bgNoteGradient)"/>
          <text x="390" y="161" text-anchor="middle" class="note-text">3</text>
        </g>

        <g class="note note-5">
          <ellipse cx="470" cy="200" rx="20" ry="16" fill="url(#bgNoteGradient)"/>
          <text x="470" y="206" text-anchor="middle" class="note-text">1</text>
        </g>
      </g>

      <!-- Flow curves -->
      <g class="flow-lines">
        <path class="flow-path flow-1" d="M150 198 Q180 175 190 157" fill="none" stroke="url(#bgFlowGradient)" stroke-width="3" stroke-linecap="round"/>
        <path class="flow-path flow-2" d="M230 153 Q260 130 280 112" fill="none" stroke="url(#bgFlowGradient)" stroke-width="3" stroke-linecap="round"/>
        <path class="flow-path flow-3" d="M320 112 Q350 130 370 153" fill="none" stroke="url(#bgFlowGradient)" stroke-width="3" stroke-linecap="round"/>
        <path class="flow-path flow-4" d="M410 157 Q430 175 450 198" fill="none" stroke="url(#bgFlowGradient)" stroke-width="3" stroke-linecap="round"/>
      </g>

      <!-- Floating particles -->
      <g class="particles">
        <circle class="particle p1" cx="140" cy="170" r="4"/>
        <circle class="particle p2" cx="220" cy="130" r="4"/>
        <circle class="particle p3" cx="310" cy="85" r="4"/>
        <circle class="particle p4" cx="400" cy="130" r="4"/>
        <circle class="particle p5" cx="460" cy="170" r="4"/>
        <circle class="particle p6" cx="180" cy="210" r="3"/>
        <circle class="particle p7" cx="260" cy="140" r="3"/>
        <circle class="particle p8" cx="340" cy="140" r="3"/>
        <circle class="particle p9" cx="420" cy="210" r="3"/>
      </g>
    </svg>
  </div>
</template>

<style scoped>
.hero-animation {
  width: 100%;
  height: 100%;
  opacity: 0;
  transition: opacity 1.2s ease;
}

.hero-animation.visible {
  opacity: 1;
}

.hero-animation svg {
  width: 100%;
  height: auto;
}

/* Color definitions - Light mode */
.block-stop-1 { stop-color: #d97706; stop-opacity: 0.9; }
.block-stop-2 { stop-color: #b45309; stop-opacity: 0.9; }
.note-stop-1 { stop-color: #fbbf24; stop-opacity: 1; }
.note-stop-2 { stop-color: #d97706; stop-opacity: 1; }
.flow-stop-1 { stop-color: #78716c; stop-opacity: 0.1; }
.flow-stop-2 { stop-color: #d97706; stop-opacity: 0.6; }
.flow-stop-3 { stop-color: #78716c; stop-opacity: 0.1; }

.staff-lines line {
  stroke: #a8a29e;
  opacity: 0.4;
}

.note-text {
  fill: #fff;
  font-size: 16px;
  font-weight: 700;
  font-family: system-ui, -apple-system, sans-serif;
}

.interval-text {
  fill: #78716c;
  font-size: 14px;
  font-family: ui-monospace, monospace;
  opacity: 0.8;
}

.rhythm-bar {
  fill: #d97706;
  opacity: 0.5;
}

.particle {
  fill: #fbbf24;
  opacity: 0.6;
}

/* Dark mode */
:global(.dark) .block-stop-1 { stop-color: #f59e0b; }
:global(.dark) .block-stop-2 { stop-color: #d97706; }
:global(.dark) .note-stop-1 { stop-color: #fcd34d; }
:global(.dark) .note-stop-2 { stop-color: #f59e0b; }
:global(.dark) .flow-stop-1 { stop-color: #a8a29e; stop-opacity: 0.1; }
:global(.dark) .flow-stop-2 { stop-color: #f59e0b; stop-opacity: 0.7; }
:global(.dark) .flow-stop-3 { stop-color: #a8a29e; stop-opacity: 0.1; }

:global(.dark) .staff-lines line {
  stroke: #d6d3d1;
  opacity: 0.2;
}

:global(.dark) .interval-text {
  fill: #a8a29e;
  opacity: 0.9;
}

:global(.dark) .rhythm-bar {
  fill: #f59e0b;
  opacity: 0.6;
}

:global(.dark) .particle {
  fill: #fcd34d;
  opacity: 0.7;
}

/* Animations */
.note {
  animation: noteFloat 4s ease-in-out infinite;
  transform-origin: center;
}

.note-1 { animation-delay: 0s; }
.note-2 { animation-delay: 0.2s; }
.note-3 { animation-delay: 0.4s; }
.note-4 { animation-delay: 0.6s; }
.note-5 { animation-delay: 0.8s; }

@keyframes noteFloat {
  0%, 100% { transform: translateY(0); }
  50% { transform: translateY(-10px); }
}

/* Flow path animation */
.flow-path {
  stroke-dasharray: 80;
  stroke-dashoffset: 80;
  animation: drawFlow 3s ease-in-out infinite;
}

.flow-1 { animation-delay: 0s; }
.flow-2 { animation-delay: 0.3s; }
.flow-3 { animation-delay: 0.6s; }
.flow-4 { animation-delay: 0.9s; }

@keyframes drawFlow {
  0% { stroke-dashoffset: 80; opacity: 0.2; }
  50% { stroke-dashoffset: 0; opacity: 1; }
  100% { stroke-dashoffset: -80; opacity: 0.2; }
}

/* Pipe animation */
.pipe-left, .pipe-right {
  animation: pipePulse 3s ease-in-out infinite;
}

.pipe-right { animation-delay: 0.5s; }

@keyframes pipePulse {
  0%, 100% { opacity: 0.8; }
  50% { opacity: 1; }
}

/* Interval labels */
.interval-text {
  animation: labelFloat 5s ease-in-out infinite;
}

.interval-labels text:nth-child(1) { animation-delay: 0s; }
.interval-labels text:nth-child(2) { animation-delay: 0.5s; }
.interval-labels text:nth-child(3) { animation-delay: 1s; }
.interval-labels text:nth-child(4) { animation-delay: 1.5s; }

@keyframes labelFloat {
  0%, 100% { transform: translateY(0); opacity: 0.6; }
  50% { transform: translateY(-6px); opacity: 0.9; }
}

/* Rhythm bars */
.rhythm-bar {
  animation: rhythmPulse 1.5s ease-in-out infinite;
  transform-origin: left center;
}

.rhythm-1 { animation-delay: 0s; }
.rhythm-2 { animation-delay: 0.375s; }
.rhythm-3 { animation-delay: 0.75s; }
.rhythm-4 { animation-delay: 1.125s; }

@keyframes rhythmPulse {
  0%, 100% { opacity: 0.4; transform: scaleX(1); }
  50% { opacity: 0.8; transform: scaleX(1.1); }
}

/* Particles */
.particle {
  animation: particleDrift 5s ease-in-out infinite;
}

.p1 { animation-delay: 0s; }
.p2 { animation-delay: 0.5s; }
.p3 { animation-delay: 1s; }
.p4 { animation-delay: 1.5s; }
.p5 { animation-delay: 2s; }
.p6 { animation-delay: 2.5s; }
.p7 { animation-delay: 3s; }
.p8 { animation-delay: 3.5s; }
.p9 { animation-delay: 4s; }

@keyframes particleDrift {
  0%, 100% {
    transform: translate(0, 0) scale(1);
    opacity: 0.4;
  }
  25% {
    transform: translate(12px, -18px) scale(1.4);
    opacity: 0.8;
  }
  50% {
    transform: translate(18px, -8px) scale(1);
    opacity: 0.6;
  }
  75% {
    transform: translate(6px, 6px) scale(0.6);
    opacity: 0.3;
  }
}

/* Staff lines subtle pulse */
.staff-lines line {
  animation: staffGlow 8s ease-in-out infinite;
}

@keyframes staffGlow {
  0%, 100% { opacity: 0.3; }
  50% { opacity: 0.5; }
}
</style>
