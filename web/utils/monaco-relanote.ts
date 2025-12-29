import type * as Monaco from "monaco-editor";

// Relanote language configuration
export const languageConfiguration: Monaco.languages.LanguageConfiguration = {
  comments: {
    lineComment: ";",
  },
  brackets: [
    ["{", "}"],
    ["[", "]"],
    ["(", ")"],
    ["<", ">"],
  ],
  autoClosingPairs: [
    { open: "{", close: "}" },
    { open: "[", close: "]" },
    { open: "(", close: ")" },
    { open: "<", close: ">" },
    { open: '"', close: '"' },
    { open: "'", close: "'" },
  ],
  surroundingPairs: [
    { open: "{", close: "}" },
    { open: "[", close: "]" },
    { open: "(", close: ")" },
    { open: "<", close: ">" },
    { open: '"', close: '"' },
    { open: "'", close: "'" },
  ],
  folding: {
    markers: {
      start: /^\s*(section|part|layer)\s/,
      end: /^\s*$/,
    },
  },
  indentationRules: {
    increaseIndentPattern: /^\s*(let|section|part|layer|if|match)\b.*$/,
    decreaseIndentPattern: /^\s*(in|else|with)\b.*$/,
  },
};

// Relanote token provider (Monarch syntax)
export const monarchTokensProvider: Monaco.languages.IMonarchLanguage = {
  defaultToken: "invalid",
  tokenPostfix: ".rela",

  keywords: [
    "let",
    "in",
    "if",
    "then",
    "else",
    "match",
    "with",
    "scale",
    "chord",
    "section",
    "layer",
    "part",
    "env",
    "import",
    "export",
    "from",
    "as",
    "true",
    "false",
    "render",
    "context",
    "key",
  ],

  dynamics: ["pp", "p", "mp", "mf", "f", "ff", "ppp", "fff", "sfz", "fp"],

  articulations: ["staccato", "accent", "portamento", "legato", "tenuto"],

  operators: ["|>", "|", "->", "=>", "=", ":", ",", ".", "+", "-", "*", "/"],

  symbols: /[=><!~?:&|+\-*\/\^%]+/,

  escapes: /\\(?:[abfnrtv\\"']|x[0-9A-Fa-f]{1,4}|u[0-9A-Fa-f]{4}|U[0-9A-Fa-f]{8})/,

  tokenizer: {
    root: [
      // Identifiers and keywords
      [
        /[a-zA-Z_][a-zA-Z0-9_]*/,
        {
          cases: {
            "@keywords": "keyword",
            "@dynamics": "constant.dynamics",
            "@articulations": "constant.articulations",
            "@default": "identifier",
          },
        },
      ],

      // Intervals (P1, M3, m7, A4, d5, etc.)
      [/[PMmAd][1-9][0-9]?[+\-]*/, "constant.interval"],

      // Scale index <n>
      [/<[0-9]+>/, "constant.scaleindex"],

      // Rest
      [/~/, "constant.rest"],

      // Whitespace
      { include: "@whitespace" },

      // Delimiters and operators
      [/[{}()\[\]]/, "@brackets"],
      [/<|>/, "@brackets"],
      [/\|>/, "operator.pipe"],
      [/\|/, "delimiter.bar"],
      [/->/, "operator.arrow"],
      [/=>/, "operator.lambda"],
      [/:([0-9]+)?/, "constant.duration"],
      [/[@#]/, "delimiter"],

      // Numbers
      [/\d*\.\d+([eE][\-+]?\d+)?/, "number.float"],
      [/\d+/, "number"],

      // Strings
      [/"([^"\\]|\\.)*$/, "string.invalid"],
      [/'([^'\\]|\\.)*$/, "string.invalid"],
      [/"/, "string", "@string_double"],
      [/'/, "string", "@string_single"],

      // Operators
      [
        /@symbols/,
        {
          cases: {
            "@operators": "operator",
            "@default": "",
          },
        },
      ],
    ],

    whitespace: [
      [/[ \t\r\n]+/, "white"],
      [/;.*$/, "comment"],
    ],

    string_double: [
      [/[^\\"]+/, "string"],
      [/@escapes/, "string.escape"],
      [/\\./, "string.escape.invalid"],
      [/"/, "string", "@pop"],
    ],

    string_single: [
      [/[^\\']+/, "string"],
      [/@escapes/, "string.escape"],
      [/\\./, "string.escape.invalid"],
      [/'/, "string", "@pop"],
    ],
  },
};

// Theme definition for Relanote
export const relanoteTheme: Monaco.editor.IStandaloneThemeData = {
  base: "vs-dark",
  inherit: true,
  rules: [
    { token: "keyword", foreground: "569CD6", fontStyle: "bold" },
    { token: "identifier", foreground: "9CDCFE" },
    { token: "constant.interval", foreground: "4EC9B0", fontStyle: "bold" },
    { token: "constant.scaleindex", foreground: "CE9178" },
    { token: "constant.rest", foreground: "808080" },
    { token: "constant.duration", foreground: "B5CEA8" },
    { token: "constant.dynamics", foreground: "DCDCAA", fontStyle: "italic" },
    { token: "constant.articulations", foreground: "C586C0", fontStyle: "italic" },
    { token: "operator", foreground: "D4D4D4" },
    { token: "operator.pipe", foreground: "4FC1FF", fontStyle: "bold" },
    { token: "operator.arrow", foreground: "4FC1FF" },
    { token: "operator.lambda", foreground: "C586C0" },
    { token: "delimiter.bar", foreground: "FFD700", fontStyle: "bold" },
    { token: "string", foreground: "CE9178" },
    { token: "string.escape", foreground: "D7BA7D" },
    { token: "number", foreground: "B5CEA8" },
    { token: "number.float", foreground: "B5CEA8" },
    { token: "comment", foreground: "6A9955", fontStyle: "italic" },
    { token: "@brackets", foreground: "FFD700" },
  ],
  colors: {
    "editor.background": "#1E1E1E",
    "editor.foreground": "#D4D4D4",
    "editorLineNumber.foreground": "#858585",
    "editorLineNumber.activeForeground": "#C6C6C6",
    "editor.lineHighlightBackground": "#2A2D2E",
    "editorCursor.foreground": "#AEAFAD",
    "editor.selectionBackground": "#264F78",
    "editor.inactiveSelectionBackground": "#3A3D41",
  },
};

// Completion items for Relanote
export const createCompletionProvider = (
  monaco: typeof Monaco
): Monaco.languages.CompletionItemProvider => ({
  triggerCharacters: ["<", "|", ".", " "],

  provideCompletionItems: (model, position) => {
    const word = model.getWordUntilPosition(position);
    const range: Monaco.IRange = {
      startLineNumber: position.lineNumber,
      endLineNumber: position.lineNumber,
      startColumn: word.startColumn,
      endColumn: word.endColumn,
    };

    const suggestions: Monaco.languages.CompletionItem[] = [
      // Keywords
      {
        label: "let",
        kind: monaco.languages.CompletionItemKind.Keyword,
        insertText: "let ${1:name} = ${2:value}",
        insertTextRules: monaco.languages.CompletionItemInsertTextRule.InsertAsSnippet,
        documentation: "Define a variable",
        range,
      },
      {
        label: "let...in",
        kind: monaco.languages.CompletionItemKind.Snippet,
        insertText: "let ${1:name} = ${2:value} in\n  ${3:expr}",
        insertTextRules: monaco.languages.CompletionItemInsertTextRule.InsertAsSnippet,
        documentation: "Define a local variable",
        range,
      },
      {
        label: "scale",
        kind: monaco.languages.CompletionItemKind.Keyword,
        insertText: "scale [${1:P1, M3, P5}]",
        insertTextRules: monaco.languages.CompletionItemInsertTextRule.InsertAsSnippet,
        documentation: "Define a scale",
        range,
      },
      {
        label: "chord",
        kind: monaco.languages.CompletionItemKind.Keyword,
        insertText: "chord [${1:P1, M3, P5}]",
        insertTextRules: monaco.languages.CompletionItemInsertTextRule.InsertAsSnippet,
        documentation: "Define a chord",
        range,
      },
      {
        label: "section",
        kind: monaco.languages.CompletionItemKind.Keyword,
        insertText: 'section "${1:name}"\n  ${2:parts}',
        insertTextRules: monaco.languages.CompletionItemInsertTextRule.InsertAsSnippet,
        documentation: "Define a section",
        range,
      },
      {
        label: "part",
        kind: monaco.languages.CompletionItemKind.Keyword,
        insertText: 'part "${1:instrument}"\n  ${2:blocks}',
        insertTextRules: monaco.languages.CompletionItemInsertTextRule.InsertAsSnippet,
        documentation: "Define a part",
        range,
      },
      {
        label: "layer",
        kind: monaco.languages.CompletionItemKind.Keyword,
        insertText: "layer\n  ${1:block1}\n  ${2:block2}",
        insertTextRules: monaco.languages.CompletionItemInsertTextRule.InsertAsSnippet,
        documentation: "Layer multiple blocks",
        range,
      },
      {
        label: "if...then...else",
        kind: monaco.languages.CompletionItemKind.Snippet,
        insertText: "if ${1:condition} then\n  ${2:true_expr}\nelse\n  ${3:false_expr}",
        insertTextRules: monaco.languages.CompletionItemInsertTextRule.InsertAsSnippet,
        documentation: "Conditional expression",
        range,
      },
      {
        label: "match...with",
        kind: monaco.languages.CompletionItemKind.Snippet,
        insertText: "match ${1:expr} with\n  | ${2:pattern} -> ${3:result}",
        insertTextRules: monaco.languages.CompletionItemInsertTextRule.InsertAsSnippet,
        documentation: "Pattern matching",
        range,
      },

      // Common scales
      {
        label: "Major",
        kind: monaco.languages.CompletionItemKind.Variable,
        insertText: "scale [P1, M2, M3, P4, P5, M6, M7]",
        documentation: "Major scale",
        range,
      },
      {
        label: "Minor",
        kind: monaco.languages.CompletionItemKind.Variable,
        insertText: "scale [P1, M2, m3, P4, P5, m6, m7]",
        documentation: "Natural minor scale",
        range,
      },
      {
        label: "Pentatonic",
        kind: monaco.languages.CompletionItemKind.Variable,
        insertText: "scale [P1, M2, M3, P5, M6]",
        documentation: "Major pentatonic scale",
        range,
      },

      // Intervals
      ...["P1", "m2", "M2", "m3", "M3", "P4", "A4", "d5", "P5", "m6", "M6", "m7", "M7", "P8"].map(
        (interval) => ({
          label: interval,
          kind: monaco.languages.CompletionItemKind.Constant,
          insertText: interval,
          documentation: getIntervalName(interval),
          range,
        })
      ),

      // Dynamics
      ...["ppp", "pp", "p", "mp", "mf", "f", "ff", "fff", "sfz", "fp"].map((dynamic) => ({
        label: dynamic,
        kind: monaco.languages.CompletionItemKind.Property,
        insertText: dynamic,
        documentation: getDynamicName(dynamic),
        range,
      })),
    ];

    return { suggestions };
  },
});

function getIntervalName(interval: string): string {
  const names: Record<string, string> = {
    P1: "Perfect Unison",
    m2: "Minor Second",
    M2: "Major Second",
    m3: "Minor Third",
    M3: "Major Third",
    P4: "Perfect Fourth",
    A4: "Augmented Fourth (Tritone)",
    d5: "Diminished Fifth (Tritone)",
    P5: "Perfect Fifth",
    m6: "Minor Sixth",
    M6: "Major Sixth",
    m7: "Minor Seventh",
    M7: "Major Seventh",
    P8: "Perfect Octave",
  };
  return names[interval] || interval;
}

function getDynamicName(dynamic: string): string {
  const names: Record<string, string> = {
    ppp: "Pianississimo (very very soft)",
    pp: "Pianissimo (very soft)",
    p: "Piano (soft)",
    mp: "Mezzo-piano (moderately soft)",
    mf: "Mezzo-forte (moderately loud)",
    f: "Forte (loud)",
    ff: "Fortissimo (very loud)",
    fff: "Fortississimo (very very loud)",
    sfz: "Sforzando (sudden accent)",
    fp: "Forte-piano (loud then soft)",
  };
  return names[dynamic] || dynamic;
}

// Hover provider for Relanote
export const createHoverProvider = (
  monaco: typeof Monaco
): Monaco.languages.HoverProvider => ({
  provideHover: (model, position) => {
    const word = model.getWordAtPosition(position);
    if (!word) return null;

    const content = getHoverContent(word.word);
    if (!content) return null;

    return {
      range: new monaco.Range(
        position.lineNumber,
        word.startColumn,
        position.lineNumber,
        word.endColumn
      ),
      contents: [{ value: content }],
    };
  },
});

function getHoverContent(word: string): string | null {
  const docs: Record<string, string> = {
    let: "**let** - Define a variable binding\n\n```rela\nlet name = value\nlet name = value in expr\n```",
    scale: "**scale** - Define a musical scale from intervals\n\n```rela\nlet Major = scale [P1, M2, M3, P4, P5, M6, M7]\n```",
    chord: "**chord** - Define a chord from intervals\n\n```rela\nlet CMajor = chord [P1, M3, P5]\n```",
    section: '**section** - Define a named section of music\n\n```rela\nsection "Verse"\n  part "Piano" [...]\n```',
    part: '**part** - Define an instrument part\n\n```rela\npart "Piano"\n  [<1>, <3>, <5>]\n```',
    layer: "**layer** - Combine multiple blocks vertically (polyphony)\n\n```rela\nlayer\n  [<1>, <3>]\n  [<5>, <7>]\n```",
    P1: "**Perfect Unison** - 0 semitones",
    m2: "**Minor Second** - 1 semitone",
    M2: "**Major Second** - 2 semitones",
    m3: "**Minor Third** - 3 semitones",
    M3: "**Major Third** - 4 semitones",
    P4: "**Perfect Fourth** - 5 semitones",
    A4: "**Augmented Fourth** - 6 semitones (Tritone)",
    d5: "**Diminished Fifth** - 6 semitones (Tritone)",
    P5: "**Perfect Fifth** - 7 semitones",
    m6: "**Minor Sixth** - 8 semitones",
    M6: "**Major Sixth** - 9 semitones",
    m7: "**Minor Seventh** - 10 semitones",
    M7: "**Major Seventh** - 11 semitones",
    P8: "**Perfect Octave** - 12 semitones",
  };

  return docs[word] || null;
}

// Register the Relanote language with Monaco
export function registerRelanoteLanguage(monaco: typeof Monaco) {
  // Register language
  monaco.languages.register({ id: "relanote", extensions: [".rela"] });

  // Set language configuration
  monaco.languages.setLanguageConfiguration("relanote", languageConfiguration);

  // Set Monarch token provider
  monaco.languages.setMonarchTokensProvider("relanote", monarchTokensProvider);

  // Register theme
  monaco.editor.defineTheme("relanote-dark", relanoteTheme);

  // Register completion provider
  monaco.languages.registerCompletionItemProvider("relanote", createCompletionProvider(monaco));

  // Register hover provider
  monaco.languages.registerHoverProvider("relanote", createHoverProvider(monaco));
}
