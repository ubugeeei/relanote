// https://nuxt.com/docs/api/configuration/nuxt-config
export default defineNuxtConfig({
  compatibilityDate: "2025-05-15",
  devtools: { enabled: true },

  ssr: false,

  dir: {
    public: "../assets",
  },

  app: {
    baseURL: process.env.NUXT_APP_BASE_URL || "/",
    head: {
      title: "Relanote Playground",
      meta: [
        {
          name: "description",
          content: "Functional music notation language",
        },
      ],
      link: [{ rel: "icon", href: "/logo-icon-transparent.svg" }],
    },
  },

  vite: {
    optimizeDeps: {
      exclude: ["relanote-wasm"],
      include: ["monaco-editor"],
    },
  },

  nitro: {
    preset: "static",
  },

  modules: [],
});
