// https://nuxt.com/docs/api/configuration/nuxt-config
export default defineNuxtConfig({
  compatibilityDate: "2025-05-15",
  devtools: { enabled: true },

  ssr: false,

  vite: {
    optimizeDeps: {
      exclude: ["relanote-wasm"],
      include: ["monaco-editor"],
    },
  },

  app: {
    head: {
      title: "Relanote Playground",
      meta: [
        { name: "description", content: "Functional music notation language" },
      ],
    },
  },

  modules: [],
});
