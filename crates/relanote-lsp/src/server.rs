//! LSP server implementation

use std::collections::HashMap;
use std::sync::Arc;

use tokio::sync::RwLock;
use tower_lsp::jsonrpc::Result;
use tower_lsp::lsp_types::*;
use tower_lsp::{Client, LanguageServer};

use relanote_core::{Source, SourceDb};
use relanote_format::{format, FormatConfig};
use relanote_parser::parse_source;
use relanote_types::TypeChecker;

/// Document state
struct Document {
    content: String,
    version: i32,
}

/// The relanote language server
pub struct RelanoteLanguageServer {
    client: Client,
    documents: Arc<RwLock<HashMap<Url, Document>>>,
    #[allow(dead_code)]
    source_db: Arc<RwLock<SourceDb>>,
}

impl RelanoteLanguageServer {
    pub fn new(client: Client) -> Self {
        Self {
            client,
            documents: Arc::new(RwLock::new(HashMap::new())),
            source_db: Arc::new(RwLock::new(SourceDb::new())),
        }
    }

    async fn analyze_document(&self, uri: &Url) {
        let documents = self.documents.read().await;
        let doc = match documents.get(uri) {
            Some(d) => d,
            None => return,
        };

        // Parse the document
        let source = Source::from_string(
            uri.path().to_string(),
            doc.content.clone(),
        );
        let (program, parse_diagnostics) = parse_source(&source);

        // Type check
        let mut type_checker = TypeChecker::new();
        let type_diagnostics = type_checker.check_program(&program);

        // Convert to LSP diagnostics
        let mut lsp_diagnostics = Vec::new();

        for diag in parse_diagnostics.iter() {
            let start_loc = source.location(diag.span.start);
            let end_loc = source.location(diag.span.end);

            lsp_diagnostics.push(Diagnostic {
                range: Range {
                    start: Position {
                        line: (start_loc.line - 1) as u32,
                        character: (start_loc.column - 1) as u32,
                    },
                    end: Position {
                        line: (end_loc.line - 1) as u32,
                        character: (end_loc.column - 1) as u32,
                    },
                },
                severity: Some(DiagnosticSeverity::ERROR),
                message: diag.message.clone(),
                ..Default::default()
            });
        }

        for diag in type_diagnostics.iter() {
            let start_loc = source.location(diag.span.start);
            let end_loc = source.location(diag.span.end);

            lsp_diagnostics.push(Diagnostic {
                range: Range {
                    start: Position {
                        line: (start_loc.line - 1) as u32,
                        character: (start_loc.column - 1) as u32,
                    },
                    end: Position {
                        line: (end_loc.line - 1) as u32,
                        character: (end_loc.column - 1) as u32,
                    },
                },
                severity: Some(DiagnosticSeverity::ERROR),
                message: diag.message.clone(),
                ..Default::default()
            });
        }

        // Publish diagnostics
        self.client
            .publish_diagnostics(uri.clone(), lsp_diagnostics, Some(doc.version))
            .await;
    }
}

#[tower_lsp::async_trait]
impl LanguageServer for RelanoteLanguageServer {
    async fn initialize(&self, _: InitializeParams) -> Result<InitializeResult> {
        Ok(InitializeResult {
            capabilities: ServerCapabilities {
                text_document_sync: Some(TextDocumentSyncCapability::Kind(
                    TextDocumentSyncKind::FULL,
                )),
                completion_provider: Some(CompletionOptions {
                    trigger_characters: Some(vec![".".to_string(), "<".to_string()]),
                    ..Default::default()
                }),
                hover_provider: Some(HoverProviderCapability::Simple(true)),
                definition_provider: Some(OneOf::Left(true)),
                document_formatting_provider: Some(OneOf::Left(true)),
                ..Default::default()
            },
            ..Default::default()
        })
    }

    async fn initialized(&self, _: InitializedParams) {
        self.client
            .log_message(MessageType::INFO, "Relanote language server initialized")
            .await;
    }

    async fn shutdown(&self) -> Result<()> {
        Ok(())
    }

    async fn did_open(&self, params: DidOpenTextDocumentParams) {
        let uri = params.text_document.uri;
        let content = params.text_document.text;
        let version = params.text_document.version;

        {
            let mut documents = self.documents.write().await;
            documents.insert(uri.clone(), Document { content, version });
        }

        self.analyze_document(&uri).await;
    }

    async fn did_change(&self, params: DidChangeTextDocumentParams) {
        let uri = params.text_document.uri;
        let version = params.text_document.version;

        if let Some(change) = params.content_changes.into_iter().next() {
            {
                let mut documents = self.documents.write().await;
                if let Some(doc) = documents.get_mut(&uri) {
                    doc.content = change.text;
                    doc.version = version;
                }
            }

            self.analyze_document(&uri).await;
        }
    }

    async fn did_close(&self, params: DidCloseTextDocumentParams) {
        let uri = params.text_document.uri;
        let mut documents = self.documents.write().await;
        documents.remove(&uri);
    }

    async fn completion(&self, _params: CompletionParams) -> Result<Option<CompletionResponse>> {
        // Basic keyword completion
        let completions = vec![
            CompletionItem {
                label: "scale".to_string(),
                kind: Some(CompletionItemKind::KEYWORD),
                detail: Some("Define a scale".to_string()),
                ..Default::default()
            },
            CompletionItem {
                label: "chord".to_string(),
                kind: Some(CompletionItemKind::KEYWORD),
                detail: Some("Define a chord".to_string()),
                ..Default::default()
            },
            CompletionItem {
                label: "let".to_string(),
                kind: Some(CompletionItemKind::KEYWORD),
                detail: Some("Define a binding".to_string()),
                ..Default::default()
            },
            CompletionItem {
                label: "section".to_string(),
                kind: Some(CompletionItemKind::KEYWORD),
                detail: Some("Define a section".to_string()),
                ..Default::default()
            },
            CompletionItem {
                label: "layer".to_string(),
                kind: Some(CompletionItemKind::KEYWORD),
                detail: Some("Define a layer".to_string()),
                ..Default::default()
            },
            CompletionItem {
                label: "Part".to_string(),
                kind: Some(CompletionItemKind::KEYWORD),
                detail: Some("Define a part".to_string()),
                ..Default::default()
            },
            // Built-in functions
            CompletionItem {
                label: "reverse".to_string(),
                kind: Some(CompletionItemKind::FUNCTION),
                detail: Some("Reverse a block".to_string()),
                ..Default::default()
            },
            CompletionItem {
                label: "transpose".to_string(),
                kind: Some(CompletionItemKind::FUNCTION),
                detail: Some("Transpose a block by an interval".to_string()),
                ..Default::default()
            },
            CompletionItem {
                label: "repeat".to_string(),
                kind: Some(CompletionItemKind::FUNCTION),
                detail: Some("Repeat a block n times".to_string()),
                ..Default::default()
            },
        ];

        Ok(Some(CompletionResponse::Array(completions)))
    }

    async fn hover(&self, params: HoverParams) -> Result<Option<Hover>> {
        let uri = params.text_document_position_params.text_document.uri;
        let _position = params.text_document_position_params.position;

        let documents = self.documents.read().await;
        if let Some(_doc) = documents.get(&uri) {
            // TODO: Implement proper hover based on AST
            return Ok(Some(Hover {
                contents: HoverContents::Markup(MarkupContent {
                    kind: MarkupKind::Markdown,
                    value: "Relanote hover info".to_string(),
                }),
                range: None,
            }));
        }

        Ok(None)
    }

    async fn formatting(&self, params: DocumentFormattingParams) -> Result<Option<Vec<TextEdit>>> {
        let uri = params.text_document.uri;

        let documents = self.documents.read().await;
        if let Some(doc) = documents.get(&uri) {
            let source = Source::from_string(uri.path().to_string(), doc.content.clone());
            let (program, diagnostics) = parse_source(&source);

            if !diagnostics.has_errors() {
                let config = FormatConfig::default();
                let formatted = format(&program, &config);

                let lines: Vec<&str> = doc.content.lines().collect();
                let last_line = lines.len().saturating_sub(1) as u32;
                let last_char = lines.last().map(|l| l.len()).unwrap_or(0) as u32;

                return Ok(Some(vec![TextEdit {
                    range: Range {
                        start: Position { line: 0, character: 0 },
                        end: Position {
                            line: last_line,
                            character: last_char,
                        },
                    },
                    new_text: formatted,
                }]));
            }
        }

        Ok(None)
    }
}
