import type * as Monaco from "monaco-editor";
import type { CompletionItem as WasmCompletionItem, HoverResult } from "../types/relanote";

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
        insertText: "scale ${1:Name} = { ${2:R, M2, M3, P4, P5, M6, M7} }",
        insertTextRules: monaco.languages.CompletionItemInsertTextRule.InsertAsSnippet,
        documentation: "Define a named scale",
        range,
      },
      {
        label: "chord",
        kind: monaco.languages.CompletionItemKind.Keyword,
        insertText: "chord ${1:Name} = { ${2:R, M3, P5} }",
        insertTextRules: monaco.languages.CompletionItemInsertTextRule.InsertAsSnippet,
        documentation: "Define a named chord",
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
        insertText: "layer [\n  ${1:block1},\n  ${2:block2}\n]",
        insertTextRules: monaco.languages.CompletionItemInsertTextRule.InsertAsSnippet,
        documentation: "Layer multiple blocks (polyphony)",
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
      {
        label: "in",
        kind: monaco.languages.CompletionItemKind.Keyword,
        insertText: "in",
        documentation: "Use in let...in or apply scale",
        range,
      },
      {
        label: "then",
        kind: monaco.languages.CompletionItemKind.Keyword,
        insertText: "then",
        documentation: "Then branch in if expression",
        range,
      },
      {
        label: "else",
        kind: monaco.languages.CompletionItemKind.Keyword,
        insertText: "else",
        documentation: "Else branch in if expression",
        range,
      },
      {
        label: "with",
        kind: monaco.languages.CompletionItemKind.Keyword,
        insertText: "with",
        documentation: "Pattern matching cases",
        range,
      },
      {
        label: "env",
        kind: monaco.languages.CompletionItemKind.Keyword,
        insertText: "env",
        documentation: "Envelope definition",
        range,
      },
      {
        label: "import",
        kind: monaco.languages.CompletionItemKind.Keyword,
        insertText: 'import ${1:module} from "${2:path}"',
        insertTextRules: monaco.languages.CompletionItemInsertTextRule.InsertAsSnippet,
        documentation: "Import from another file",
        range,
      },
      {
        label: "export",
        kind: monaco.languages.CompletionItemKind.Keyword,
        insertText: "export",
        documentation: "Export a definition",
        range,
      },
      {
        label: "from",
        kind: monaco.languages.CompletionItemKind.Keyword,
        insertText: "from",
        documentation: "Import source path",
        range,
      },
      {
        label: "as",
        kind: monaco.languages.CompletionItemKind.Keyword,
        insertText: "as",
        documentation: "Alias for import",
        range,
      },
      {
        label: "true",
        kind: monaco.languages.CompletionItemKind.Keyword,
        insertText: "true",
        documentation: "Boolean true",
        range,
      },
      {
        label: "false",
        kind: monaco.languages.CompletionItemKind.Keyword,
        insertText: "false",
        documentation: "Boolean false",
        range,
      },
      {
        label: "render",
        kind: monaco.languages.CompletionItemKind.Keyword,
        insertText: "render",
        documentation: "Render output",
        range,
      },
      {
        label: "context",
        kind: monaco.languages.CompletionItemKind.Keyword,
        insertText: "context",
        documentation: "Context definition",
        range,
      },

      // Set statements
      {
        label: "set tempo",
        kind: monaco.languages.CompletionItemKind.Snippet,
        insertText: "set tempo = ${1:120}",
        insertTextRules: monaco.languages.CompletionItemInsertTextRule.InsertAsSnippet,
        documentation: "Set the tempo in BPM",
        range,
      },
      {
        label: "set key",
        kind: monaco.languages.CompletionItemKind.Snippet,
        insertText: "set key = ${1:C4}",
        insertTextRules: monaco.languages.CompletionItemInsertTextRule.InsertAsSnippet,
        documentation: "Set the key/root note",
        range,
      },

      // Functions
      {
        label: "transpose",
        kind: monaco.languages.CompletionItemKind.Function,
        insertText: "transpose ${1:P8}",
        insertTextRules: monaco.languages.CompletionItemInsertTextRule.InsertAsSnippet,
        documentation: "Transpose by interval (e.g., P8 for octave up)",
        range,
      },
      {
        label: "voice",
        kind: monaco.languages.CompletionItemKind.Function,
        insertText: "voice ${1:Sine}",
        insertTextRules: monaco.languages.CompletionItemInsertTextRule.InsertAsSnippet,
        documentation: "Set voice/instrument",
        range,
      },
      {
        label: "reverb",
        kind: monaco.languages.CompletionItemKind.Function,
        insertText: "reverb ${1:0.3}",
        insertTextRules: monaco.languages.CompletionItemInsertTextRule.InsertAsSnippet,
        documentation: "Add reverb (0.0-1.0)",
        range,
      },
      {
        label: "delay",
        kind: monaco.languages.CompletionItemKind.Function,
        insertText: "delay ${1:0.3}",
        insertTextRules: monaco.languages.CompletionItemInsertTextRule.InsertAsSnippet,
        documentation: "Add delay effect (0.0-1.0)",
        range,
      },
      {
        label: "volume",
        kind: monaco.languages.CompletionItemKind.Function,
        insertText: "volume ${1:0.8}",
        insertTextRules: monaco.languages.CompletionItemInsertTextRule.InsertAsSnippet,
        documentation: "Set volume (0.0-1.0)",
        range,
      },
      {
        label: "pan",
        kind: monaco.languages.CompletionItemKind.Function,
        insertText: "pan ${1:0.0}",
        insertTextRules: monaco.languages.CompletionItemInsertTextRule.InsertAsSnippet,
        documentation: "Set stereo pan (-1.0 left to 1.0 right)",
        range,
      },
      {
        label: "repeat",
        kind: monaco.languages.CompletionItemKind.Function,
        insertText: "repeat ${1:4}",
        insertTextRules: monaco.languages.CompletionItemInsertTextRule.InsertAsSnippet,
        documentation: "Repeat block N times",
        range,
      },
      {
        label: "reverse",
        kind: monaco.languages.CompletionItemKind.Function,
        insertText: "reverse",
        documentation: "Reverse the note sequence",
        range,
      },
      {
        label: "shuffle",
        kind: monaco.languages.CompletionItemKind.Function,
        insertText: "shuffle",
        documentation: "Shuffle notes randomly",
        range,
      },
      {
        label: "invert",
        kind: monaco.languages.CompletionItemKind.Function,
        insertText: "invert",
        documentation: "Invert intervals",
        range,
      },
      {
        label: "retrograde",
        kind: monaco.languages.CompletionItemKind.Function,
        insertText: "retrograde",
        documentation: "Retrograde (reverse) the melody",
        range,
      },
      {
        label: "stretch",
        kind: monaco.languages.CompletionItemKind.Function,
        insertText: "stretch ${1:2.0}",
        insertTextRules: monaco.languages.CompletionItemInsertTextRule.InsertAsSnippet,
        documentation: "Time stretch (2.0 = double length)",
        range,
      },
      {
        label: "compress",
        kind: monaco.languages.CompletionItemKind.Function,
        insertText: "compress ${1:0.5}",
        insertTextRules: monaco.languages.CompletionItemInsertTextRule.InsertAsSnippet,
        documentation: "Time compress (0.5 = half length)",
        range,
      },
      {
        label: "quantize",
        kind: monaco.languages.CompletionItemKind.Function,
        insertText: "quantize ${1:16}",
        insertTextRules: monaco.languages.CompletionItemInsertTextRule.InsertAsSnippet,
        documentation: "Quantize to note value (16 = 16th note)",
        range,
      },
      {
        label: "swing",
        kind: monaco.languages.CompletionItemKind.Function,
        insertText: "swing ${1:0.6}",
        insertTextRules: monaco.languages.CompletionItemInsertTextRule.InsertAsSnippet,
        documentation: "Apply swing feel (0.5 = straight, 0.67 = triplet)",
        range,
      },

      // Voices/Instruments
      ...voiceCompletions.map((v) => ({
        label: v.name,
        kind: monaco.languages.CompletionItemKind.EnumMember,
        insertText: v.name,
        documentation: v.doc,
        range,
      })),

      // Intervals (basic and compound)
      ...intervalCompletions.map((i) => ({
        label: i.name,
        kind: monaco.languages.CompletionItemKind.Constant,
        insertText: i.name,
        documentation: i.doc,
        range,
      })),

      // Scales
      ...scaleCompletions.map((s) => ({
        label: s.name,
        kind: monaco.languages.CompletionItemKind.Variable,
        insertText: s.insert,
        documentation: s.doc,
        range,
      })),

      // Chords
      ...chordCompletions.map((c) => ({
        label: c.name,
        kind: monaco.languages.CompletionItemKind.Variable,
        insertText: c.insert,
        documentation: c.doc,
        range,
      })),

      // Dynamics
      ...["ppp", "pp", "p", "mp", "mf", "f", "ff", "fff", "sfz", "fp"].map((dynamic) => ({
        label: dynamic,
        kind: monaco.languages.CompletionItemKind.Property,
        insertText: dynamic,
        documentation: getDynamicName(dynamic),
        range,
      })),

      // Articulations
      ...articulationCompletions.map((a) => ({
        label: a.name,
        kind: monaco.languages.CompletionItemKind.Property,
        insertText: a.name,
        documentation: a.doc,
        range,
      })),
    ];

    return { suggestions };
  },
});

// Voice/Instrument completions
const voiceCompletions = [
  // Basic waveforms
  { name: "Sine", doc: "Pure sine wave" },
  { name: "Square", doc: "Square wave" },
  { name: "Sawtooth", doc: "Sawtooth wave" },
  { name: "Triangle", doc: "Triangle wave" },
  { name: "Noise", doc: "White noise" },
  // Chiptune voices
  { name: "Chiptune", doc: "Classic 8-bit sound" },
  { name: "NES", doc: "NES-style pulse wave" },
  { name: "GameBoy", doc: "GameBoy-style sound" },
  { name: "C64", doc: "Commodore 64 SID style" },
  { name: "Chip8bit", doc: "Generic 8-bit chip sound" },
  { name: "Retro", doc: "Retro game sound" },
  { name: "Arcade", doc: "Arcade game sound" },
  // Synth voices
  { name: "Synth", doc: "Basic synthesizer" },
  { name: "SynthLead", doc: "Lead synthesizer" },
  { name: "SynthPad", doc: "Pad synthesizer" },
  { name: "SynthBass", doc: "Bass synthesizer" },
  { name: "FMSynth", doc: "FM synthesis" },
  { name: "AnalogSynth", doc: "Analog-style synth" },
  // Bass voices
  { name: "Bass", doc: "Basic bass" },
  { name: "FatBass", doc: "Fat/thick bass sound" },
  { name: "SubBass", doc: "Sub bass (low frequency)" },
  { name: "AcidBass", doc: "303-style acid bass" },
  // Keyboard
  { name: "Piano", doc: "Acoustic piano" },
  { name: "ElectricPiano", doc: "Electric piano (Rhodes-style)" },
  { name: "Organ", doc: "Organ sound" },
  { name: "Harpsichord", doc: "Harpsichord" },
  // Plucked
  { name: "Guitar", doc: "Acoustic guitar" },
  { name: "ElectricGuitar", doc: "Electric guitar" },
  { name: "Pluck", doc: "Plucked string" },
  // Drums (8-bit)
  { name: "Kick8bit", doc: "8-bit kick drum" },
  { name: "Snare8bit", doc: "8-bit snare drum" },
  { name: "HiHat8bit", doc: "8-bit hi-hat" },
  { name: "Clap8bit", doc: "8-bit clap" },
  // Other
  { name: "Bell", doc: "Bell/chime sound" },
  { name: "Marimba", doc: "Marimba" },
];

// Interval completions (basic and compound)
const intervalCompletions = [
  // Basic intervals
  { name: "R", doc: "Root/Unison (0 semitones)" },
  { name: "P1", doc: "Perfect Unison (0 semitones)" },
  { name: "m2", doc: "Minor Second (1 semitone)" },
  { name: "M2", doc: "Major Second (2 semitones)" },
  { name: "m3", doc: "Minor Third (3 semitones)" },
  { name: "M3", doc: "Major Third (4 semitones)" },
  { name: "P4", doc: "Perfect Fourth (5 semitones)" },
  { name: "A4", doc: "Augmented Fourth/Tritone (6 semitones)" },
  { name: "d5", doc: "Diminished Fifth/Tritone (6 semitones)" },
  { name: "P5", doc: "Perfect Fifth (7 semitones)" },
  { name: "m6", doc: "Minor Sixth (8 semitones)" },
  { name: "M6", doc: "Major Sixth (9 semitones)" },
  { name: "m7", doc: "Minor Seventh (10 semitones)" },
  { name: "M7", doc: "Major Seventh (11 semitones)" },
  { name: "P8", doc: "Perfect Octave (12 semitones)" },
  // Compound intervals
  { name: "m9", doc: "Minor Ninth (13 semitones)" },
  { name: "M9", doc: "Major Ninth (14 semitones)" },
  { name: "m10", doc: "Minor Tenth (15 semitones)" },
  { name: "M10", doc: "Major Tenth (16 semitones)" },
  { name: "P11", doc: "Perfect Eleventh (17 semitones)" },
  { name: "P12", doc: "Perfect Twelfth (19 semitones)" },
  { name: "M14", doc: "Major Fourteenth (23 semitones)" },
  { name: "P15", doc: "Perfect Fifteenth/Double Octave (24 semitones)" },
];

// Scale completions
const scaleCompletions = [
  { name: "Major", insert: "scale Major = { R, M2, M3, P4, P5, M6, M7 }", doc: "Major scale (Ionian mode)" },
  { name: "Minor", insert: "scale Minor = { R, M2, m3, P4, P5, m6, m7 }", doc: "Natural minor scale (Aeolian mode)" },
  { name: "HarmonicMinor", insert: "scale HarmonicMinor = { R, M2, m3, P4, P5, m6, M7 }", doc: "Harmonic minor scale" },
  { name: "MelodicMinor", insert: "scale MelodicMinor = { R, M2, m3, P4, P5, M6, M7 }", doc: "Melodic minor scale (ascending)" },
  { name: "Pentatonic", insert: "scale Pentatonic = { R, M2, M3, P5, M6 }", doc: "Major pentatonic scale" },
  { name: "MinorPentatonic", insert: "scale MinorPentatonic = { R, m3, P4, P5, m7 }", doc: "Minor pentatonic scale" },
  { name: "Blues", insert: "scale Blues = { R, m3, P4, A4, P5, m7 }", doc: "Blues scale" },
  { name: "Dorian", insert: "scale Dorian = { R, M2, m3, P4, P5, M6, m7 }", doc: "Dorian mode" },
  { name: "Phrygian", insert: "scale Phrygian = { R, m2, m3, P4, P5, m6, m7 }", doc: "Phrygian mode" },
  { name: "Lydian", insert: "scale Lydian = { R, M2, M3, A4, P5, M6, M7 }", doc: "Lydian mode" },
  { name: "Mixolydian", insert: "scale Mixolydian = { R, M2, M3, P4, P5, M6, m7 }", doc: "Mixolydian mode" },
  { name: "Locrian", insert: "scale Locrian = { R, m2, m3, P4, d5, m6, m7 }", doc: "Locrian mode" },
  { name: "WholeTone", insert: "scale WholeTone = { R, M2, M3, A4, m6, m7 }", doc: "Whole tone scale" },
  { name: "Chromatic", insert: "scale Chromatic = { R, m2, M2, m3, M3, P4, A4, P5, m6, M6, m7, M7 }", doc: "Chromatic scale" },
];

// Chord completions
const chordCompletions = [
  // Triads
  { name: "MajorTriad", insert: "chord Maj = { R, M3, P5 }", doc: "Major triad" },
  { name: "MinorTriad", insert: "chord Min = { R, m3, P5 }", doc: "Minor triad" },
  { name: "Diminished", insert: "chord Dim = { R, m3, d5 }", doc: "Diminished triad" },
  { name: "Augmented", insert: "chord Aug = { R, M3, m6 }", doc: "Augmented triad" },
  { name: "Sus2", insert: "chord Sus2 = { R, M2, P5 }", doc: "Suspended 2nd" },
  { name: "Sus4", insert: "chord Sus4 = { R, P4, P5 }", doc: "Suspended 4th" },
  // Seventh chords
  { name: "Major7", insert: "chord Maj7 = { R, M3, P5, M7 }", doc: "Major 7th chord" },
  { name: "Minor7", insert: "chord Min7 = { R, m3, P5, m7 }", doc: "Minor 7th chord" },
  { name: "Dominant7", insert: "chord Dom7 = { R, M3, P5, m7 }", doc: "Dominant 7th chord" },
  { name: "Diminished7", insert: "chord Dim7 = { R, m3, d5, M6 }", doc: "Diminished 7th chord" },
  { name: "HalfDim7", insert: "chord HalfDim7 = { R, m3, d5, m7 }", doc: "Half-diminished 7th (m7b5)" },
  { name: "MinorMaj7", insert: "chord MinMaj7 = { R, m3, P5, M7 }", doc: "Minor-major 7th chord" },
  // Extended chords
  { name: "Add9", insert: "chord Add9 = { R, M3, P5, M9 }", doc: "Add 9 chord" },
  { name: "Ninth", insert: "chord Ninth = { R, M3, P5, m7, M9 }", doc: "Dominant 9th chord" },
  { name: "PowerChord", insert: "chord Power = { R, P5 }", doc: "Power chord (root + fifth)" },
];

// Articulation completions
const articulationCompletions = [
  { name: "staccato", doc: "Short, detached notes" },
  { name: "legato", doc: "Smooth, connected notes" },
  { name: "accent", doc: "Emphasized attack" },
  { name: "tenuto", doc: "Held for full value" },
  { name: "portamento", doc: "Slide between notes" },
];

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

// WASM-based completion provider (uses Rust completions)
export const createWasmCompletionProvider = (
  monaco: typeof Monaco,
  getCompletions: () => WasmCompletionItem[] | null
): Monaco.languages.CompletionItemProvider => ({
  triggerCharacters: ["<", "|", ".", " "],

  provideCompletionItems: (model, position) => {
    const wasmCompletions = getCompletions();
    if (!wasmCompletions) {
      // Fall back to static completions if WASM not ready
      return createCompletionProvider(monaco).provideCompletionItems(model, position, {} as Monaco.languages.CompletionContext, {} as Monaco.CancellationToken);
    }

    const word = model.getWordUntilPosition(position);
    const range: Monaco.IRange = {
      startLineNumber: position.lineNumber,
      endLineNumber: position.lineNumber,
      startColumn: word.startColumn,
      endColumn: word.endColumn,
    };

    const kindMap: Record<string, Monaco.languages.CompletionItemKind> = {
      keyword: monaco.languages.CompletionItemKind.Keyword,
      function: monaco.languages.CompletionItemKind.Function,
      constant: monaco.languages.CompletionItemKind.Constant,
      property: monaco.languages.CompletionItemKind.Property,
      class: monaco.languages.CompletionItemKind.Class,
      enum_member: monaco.languages.CompletionItemKind.EnumMember,
      snippet: monaco.languages.CompletionItemKind.Snippet,
    };

    const suggestions: Monaco.languages.CompletionItem[] = wasmCompletions.map((item) => ({
      label: item.label,
      kind: kindMap[item.kind] || monaco.languages.CompletionItemKind.Text,
      insertText: item.insert_text || item.label,
      insertTextRules: item.insert_text
        ? monaco.languages.CompletionItemInsertTextRule.InsertAsSnippet
        : undefined,
      documentation: item.detail,
      range,
    }));

    return { suggestions };
  },
});

// WASM-based hover provider (uses Rust hover)
export const createWasmHoverProvider = (
  monaco: typeof Monaco,
  getHover: (source: string, offset: number) => HoverResult | null
): Monaco.languages.HoverProvider => ({
  provideHover: (model, position) => {
    const source = model.getValue();

    // Convert line/column to byte offset
    let offset = 0;
    for (let i = 0; i < position.lineNumber - 1; i++) {
      offset += model.getLineContent(i + 1).length + 1; // +1 for newline
    }
    offset += position.column - 1;

    const result = getHover(source, offset);
    if (!result || !result.found || !result.content) {
      return null;
    }

    // Convert byte offsets back to line/column for range
    let startLine = 1;
    let startCol = 1;
    let endLine = 1;
    let endCol = 1;
    let currentOffset = 0;
    const lines = source.split('\n');

    for (let i = 0; i < lines.length; i++) {
      const lineLen = lines[i].length + 1;
      if (currentOffset + lineLen > result.start && startLine === 1 && startCol === 1) {
        startLine = i + 1;
        startCol = result.start - currentOffset + 1;
      }
      if (currentOffset + lineLen >= result.end) {
        endLine = i + 1;
        endCol = result.end - currentOffset + 1;
        break;
      }
      currentOffset += lineLen;
    }

    return {
      range: new monaco.Range(startLine, startCol, endLine, endCol),
      contents: [{ value: result.content }],
    };
  },
});

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

  // Register completion provider (static fallback)
  monaco.languages.registerCompletionItemProvider("relanote", createCompletionProvider(monaco));

  // Register hover provider (static fallback)
  monaco.languages.registerHoverProvider("relanote", createHoverProvider(monaco));
}

// Register with WASM-based providers
export function registerRelanoteLanguageWithWasm(
  monaco: typeof Monaco,
  getCompletions: () => WasmCompletionItem[] | null,
  getHover: (source: string, offset: number) => HoverResult | null
) {
  // Register language
  monaco.languages.register({ id: "relanote", extensions: [".rela"] });

  // Set language configuration
  monaco.languages.setLanguageConfiguration("relanote", languageConfiguration);

  // Set Monarch token provider
  monaco.languages.setMonarchTokensProvider("relanote", monarchTokensProvider);

  // Register theme
  monaco.editor.defineTheme("relanote-dark", relanoteTheme);

  // Register WASM-based completion provider
  monaco.languages.registerCompletionItemProvider("relanote", createWasmCompletionProvider(monaco, getCompletions));

  // Register WASM-based hover provider
  monaco.languages.registerHoverProvider("relanote", createWasmHoverProvider(monaco, getHover));
}
