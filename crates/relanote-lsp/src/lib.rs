//! Language Server Protocol implementation for relanote

mod server;

pub use server::RelanoteLanguageServer;

use tower_lsp::{LspService, Server};

/// Start the LSP server on stdio
pub async fn run_server() {
    let stdin = tokio::io::stdin();
    let stdout = tokio::io::stdout();

    let (service, socket) = LspService::new(RelanoteLanguageServer::new);

    Server::new(stdin, stdout, socket).serve(service).await;
}
