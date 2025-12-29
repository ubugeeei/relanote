import * as vscode from "vscode";
import {
  LanguageClient,
  LanguageClientOptions,
  ServerOptions,
  TransportKind,
} from "vscode-languageclient/node";

let client: LanguageClient | undefined;

export async function startClient(
  context: vscode.ExtensionContext
): Promise<LanguageClient> {
  const config = vscode.workspace.getConfiguration("relanote");
  const serverPath = config.get<string>("lsp.path", "relanote");

  const serverOptions: ServerOptions = {
    run: {
      command: serverPath,
      args: ["lsp"],
      transport: TransportKind.stdio,
    },
    debug: {
      command: serverPath,
      args: ["lsp"],
      transport: TransportKind.stdio,
    },
  };

  const clientOptions: LanguageClientOptions = {
    documentSelector: [{ scheme: "file", language: "relanote" }],
    synchronize: {
      fileEvents: vscode.workspace.createFileSystemWatcher("**/*.rela"),
    },
    outputChannelName: "Relanote Language Server",
  };

  client = new LanguageClient(
    "relanote",
    "Relanote Language Server",
    serverOptions,
    clientOptions
  );

  await client.start();

  console.log("Relanote Language Server started");

  return client;
}

export async function stopClient(): Promise<void> {
  if (client) {
    await client.stop();
    client = undefined;
    console.log("Relanote Language Server stopped");
  }
}

export async function restartClient(
  context: vscode.ExtensionContext
): Promise<LanguageClient | undefined> {
  await stopClient();
  return startClient(context);
}

export function getClient(): LanguageClient | undefined {
  return client;
}
