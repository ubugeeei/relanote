import * as vscode from "vscode";
import { startClient, stopClient, restartClient, getClient } from "./client";

export async function activate(
  context: vscode.ExtensionContext
): Promise<void> {
  console.log("Relanote extension activated");

  const config = vscode.workspace.getConfiguration("relanote");

  if (config.get<boolean>("lsp.enabled", true)) {
    try {
      await startClient(context);
    } catch (error) {
      console.error("Failed to start Relanote Language Server:", error);
      vscode.window.showWarningMessage(
        "Failed to start Relanote Language Server. Make sure 'relanote' CLI is installed and in your PATH."
      );
    }
  }

  context.subscriptions.push(
    vscode.commands.registerCommand("relanote.restartServer", async () => {
      const client = getClient();
      if (client) {
        try {
          await restartClient(context);
          vscode.window.showInformationMessage(
            "Relanote Language Server restarted"
          );
        } catch (error) {
          vscode.window.showErrorMessage(
            "Failed to restart Relanote Language Server"
          );
        }
      } else {
        try {
          await startClient(context);
          vscode.window.showInformationMessage(
            "Relanote Language Server started"
          );
        } catch (error) {
          vscode.window.showErrorMessage(
            "Failed to start Relanote Language Server"
          );
        }
      }
    })
  );

  context.subscriptions.push(
    vscode.workspace.onDidChangeConfiguration(async (e) => {
      if (e.affectsConfiguration("relanote.lsp")) {
        const enabled = vscode.workspace
          .getConfiguration("relanote")
          .get<boolean>("lsp.enabled", true);
        const client = getClient();

        if (enabled && !client) {
          try {
            await startClient(context);
          } catch (error) {
            console.error("Failed to start Relanote Language Server:", error);
          }
        } else if (!enabled && client) {
          await stopClient();
        } else if (enabled && client) {
          await restartClient(context);
        }
      }
    })
  );
}

export async function deactivate(): Promise<void> {
  await stopClient();
}
