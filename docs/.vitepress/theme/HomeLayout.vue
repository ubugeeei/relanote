<script setup lang="ts">
import DefaultTheme from 'vitepress/theme'
import HeroAnimation from './HeroAnimation.vue'

const { Layout } = DefaultTheme
</script>

<template>
  <Layout>
    <template #home-hero-before>
      <div class="hero-background">
        <HeroAnimation />
      </div>
    </template>
  </Layout>
</template>

<style scoped>
.hero-background {
  position: absolute;
  top: 60px;
  left: 50%;
  transform: translateX(-50%);
  width: 100%;
  max-width: 1400px;
  pointer-events: none;
  z-index: 0;
}

.hero-background :deep(.hero-animation) {
  width: 100%;
  opacity: 0.1;
}

@media (max-width: 960px) {
  .hero-background {
    top: 50px;
    max-width: 100%;
  }
  .hero-background :deep(.hero-animation) {
    opacity: 0.08;
  }
}

@media (max-width: 640px) {
  .hero-background {
    top: 40px;
    max-width: 100%;
    padding: 0 10px;
  }
  .hero-background :deep(.hero-animation) {
    opacity: 0.06;
  }
}
</style>

<style>
/* Dark mode - non-scoped to avoid :global() issues */
html.dark .hero-background .hero-animation {
  opacity: 0.15;
}
</style>
