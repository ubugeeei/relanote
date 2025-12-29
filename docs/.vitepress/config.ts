import { defineConfig } from "vitepress";

const relaLanguage = {
  name: "rela",
  aliases: ["relanote"],
  scopeName: "source.rela",
  patterns: [
    { include: "#comments" },
    { include: "#keywords" },
    { include: "#intervals" },
    { include: "#scale-degrees" },
    { include: "#strings" },
    { include: "#numbers" },
    { include: "#operators" },
    { include: "#punctuation" },
    { include: "#identifiers" },
  ],
  repository: {
    comments: {
      patterns: [
        {
          name: "comment.line.double-dash.rela",
          match: "--.*$",
        },
      ],
    },
    keywords: {
      patterns: [
        {
          name: "keyword.control.rela",
          match: "\\b(if|then|else|match|with|let|in)\\b",
        },
        {
          name: "keyword.declaration.rela",
          match: "\\b(scale|chord|part|section|layer|render)\\b",
        },
        {
          name: "constant.language.boolean.rela",
          match: "\\b(true|false)\\b",
        },
        {
          name: "keyword.operator.logical.rela",
          match: "\\b(and|or|not)\\b",
        },
      ],
    },
    intervals: {
      patterns: [
        {
          name: "constant.numeric.interval.rela",
          match: "\\b(R|[PMmAd][1-9][0-9]?[+-]*)\\b",
        },
      ],
    },
    "scale-degrees": {
      patterns: [
        {
          name: "variable.other.scale-degree.rela",
          match: "<[0-9]+>",
        },
      ],
    },
    strings: {
      patterns: [
        {
          name: "string.quoted.double.rela",
          begin: '"',
          end: '"',
          patterns: [
            {
              name: "constant.character.escape.rela",
              match: "\\\\.",
            },
          ],
        },
      ],
    },
    numbers: {
      patterns: [
        {
          name: "constant.numeric.float.rela",
          match: "\\b[0-9]+\\.[0-9]+\\b",
        },
        {
          name: "constant.numeric.integer.rela",
          match: "\\b[0-9]+\\b",
        },
      ],
    },
    operators: {
      patterns: [
        {
          name: "keyword.operator.pipe.rela",
          match: "\\|>",
        },
        {
          name: "keyword.operator.compose.rela",
          match: ">>",
        },
        {
          name: "keyword.operator.concat.rela",
          match: "\\+\\+",
        },
        {
          name: "keyword.operator.arrow.rela",
          match: "->",
        },
        {
          name: "keyword.operator.comparison.rela",
          match: "(==|!=|<=|>=|<|>)",
        },
        {
          name: "keyword.operator.assignment.rela",
          match: "=",
        },
        {
          name: "keyword.operator.arithmetic.rela",
          match: "[+\\-*/]",
        },
        {
          name: "keyword.operator.lambda.rela",
          match: "\\\\",
        },
      ],
    },
    punctuation: {
      patterns: [
        {
          name: "punctuation.definition.block.rela",
          match: "\\|",
        },
        {
          name: "punctuation.separator.rela",
          match: ",",
        },
        {
          name: "punctuation.bracket.rela",
          match: "[\\[\\]\\{\\}\\(\\)]",
        },
        {
          name: "punctuation.articulation.rela",
          match: "['\\^]",
        },
        {
          name: "punctuation.duration.rela",
          match: ":[0-9]+",
        },
      ],
    },
    identifiers: {
      patterns: [
        {
          name: "entity.name.type.rela",
          match: "\\b[A-Z][a-zA-Z0-9]*\\b",
        },
        {
          name: "variable.other.rela",
          match: "\\b[a-z_][a-zA-Z0-9_]*\\b",
        },
      ],
    },
  },
};

export default defineConfig({
  title: "Relanote",
  description: "A pure functional, statically-typed music notation language",

  head: [
    ["link", { rel: "icon", href: "/logo-icon.svg" }],
    ["meta", { name: "theme-color", content: "#6366f1" }],
  ],

  markdown: {
    languages: [relaLanguage as any],
    theme: {
      light: "github-light",
      dark: "github-dark",
    },
  },

  themeConfig: {
    logo: "/logo-icon.svg",

    nav: [
      { text: "Guide", link: "/guide/introduction" },
      { text: "Tutorial", link: "/tutorial/getting-started" },
      { text: "Reference", link: "/reference/syntax" },
      { text: "Playground", link: "https://relanote.dev/playground" },
    ],

    sidebar: {
      "/guide/": [
        {
          text: "Introduction",
          items: [
            { text: "What is Relanote?", link: "/guide/introduction" },
            { text: "Installation", link: "/guide/installation" },
            { text: "Quick Start", link: "/guide/quick-start" },
          ],
        },
        {
          text: "Core Concepts",
          items: [
            { text: "Intervals", link: "/guide/intervals" },
            { text: "Scales & Chords", link: "/guide/scales-and-chords" },
            { text: "Blocks", link: "/guide/blocks" },
            { text: "Pipes & Composition", link: "/guide/pipes" },
          ],
        },
        {
          text: "Advanced",
          items: [
            { text: "Parts & Sections", link: "/guide/parts-and-sections" },
            { text: "Layers", link: "/guide/layers" },
            { text: "Functions", link: "/guide/functions" },
            { text: "Pattern Matching", link: "/guide/pattern-matching" },
          ],
        },
      ],
      "/tutorial/": [
        {
          text: "Tutorial",
          items: [
            { text: "Getting Started", link: "/tutorial/getting-started" },
            { text: "Your First Melody", link: "/tutorial/first-melody" },
            { text: "Building Chords", link: "/tutorial/building-chords" },
            { text: "Creating a Song", link: "/tutorial/creating-a-song" },
          ],
        },
      ],
      "/reference/": [
        {
          text: "Reference",
          items: [
            { text: "Syntax", link: "/reference/syntax" },
            { text: "Types", link: "/reference/types" },
            { text: "Intervals", link: "/reference/intervals" },
            { text: "Built-in Functions", link: "/reference/builtins" },
            { text: "CLI", link: "/reference/cli" },
          ],
        },
      ],
    },

    socialLinks: [
      { icon: "github", link: "https://github.com/ubugeeei/relanote" },
    ],

    footer: {
      message: "Released under the MIT License.",
      copyright: "Copyright (c) 2025 ubugeeei",
    },

    search: {
      provider: "local",
    },
  },
});
