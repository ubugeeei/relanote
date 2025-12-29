"use strict";
var __createBinding = (this && this.__createBinding) || (Object.create ? (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    var desc = Object.getOwnPropertyDescriptor(m, k);
    if (!desc || ("get" in desc ? !m.__esModule : desc.writable || desc.configurable)) {
      desc = { enumerable: true, get: function() { return m[k]; } };
    }
    Object.defineProperty(o, k2, desc);
}) : (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    o[k2] = m[k];
}));
var __setModuleDefault = (this && this.__setModuleDefault) || (Object.create ? (function(o, v) {
    Object.defineProperty(o, "default", { enumerable: true, value: v });
}) : function(o, v) {
    o["default"] = v;
});
var __importStar = (this && this.__importStar) || (function () {
    var ownKeys = function(o) {
        ownKeys = Object.getOwnPropertyNames || function (o) {
            var ar = [];
            for (var k in o) if (Object.prototype.hasOwnProperty.call(o, k)) ar[ar.length] = k;
            return ar;
        };
        return ownKeys(o);
    };
    return function (mod) {
        if (mod && mod.__esModule) return mod;
        var result = {};
        if (mod != null) for (var k = ownKeys(mod), i = 0; i < k.length; i++) if (k[i] !== "default") __createBinding(result, mod, k[i]);
        __setModuleDefault(result, mod);
        return result;
    };
})();
Object.defineProperty(exports, "__esModule", { value: true });
exports.activate = activate;
exports.deactivate = deactivate;
const vscode = __importStar(require("vscode"));
const client_1 = require("./client");
async function activate(context) {
    console.log("Relanote extension activated");
    const config = vscode.workspace.getConfiguration("relanote");
    if (config.get("lsp.enabled", true)) {
        try {
            await (0, client_1.startClient)(context);
        }
        catch (error) {
            console.error("Failed to start Relanote Language Server:", error);
            vscode.window.showWarningMessage("Failed to start Relanote Language Server. Make sure 'relanote' CLI is installed and in your PATH.");
        }
    }
    context.subscriptions.push(vscode.commands.registerCommand("relanote.restartServer", async () => {
        const client = (0, client_1.getClient)();
        if (client) {
            try {
                await (0, client_1.restartClient)(context);
                vscode.window.showInformationMessage("Relanote Language Server restarted");
            }
            catch (error) {
                vscode.window.showErrorMessage("Failed to restart Relanote Language Server");
            }
        }
        else {
            try {
                await (0, client_1.startClient)(context);
                vscode.window.showInformationMessage("Relanote Language Server started");
            }
            catch (error) {
                vscode.window.showErrorMessage("Failed to start Relanote Language Server");
            }
        }
    }));
    context.subscriptions.push(vscode.workspace.onDidChangeConfiguration(async (e) => {
        if (e.affectsConfiguration("relanote.lsp")) {
            const enabled = vscode.workspace
                .getConfiguration("relanote")
                .get("lsp.enabled", true);
            const client = (0, client_1.getClient)();
            if (enabled && !client) {
                try {
                    await (0, client_1.startClient)(context);
                }
                catch (error) {
                    console.error("Failed to start Relanote Language Server:", error);
                }
            }
            else if (!enabled && client) {
                await (0, client_1.stopClient)();
            }
            else if (enabled && client) {
                await (0, client_1.restartClient)(context);
            }
        }
    }));
}
async function deactivate() {
    await (0, client_1.stopClient)();
}
//# sourceMappingURL=extension.js.map