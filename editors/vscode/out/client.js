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
exports.startClient = startClient;
exports.stopClient = stopClient;
exports.restartClient = restartClient;
exports.getClient = getClient;
const vscode = __importStar(require("vscode"));
const node_1 = require("vscode-languageclient/node");
let client;
async function startClient(context) {
    const config = vscode.workspace.getConfiguration("relanote");
    const serverPath = config.get("lsp.path", "relanote");
    const serverOptions = {
        run: {
            command: serverPath,
            args: ["lsp"],
            transport: node_1.TransportKind.stdio,
        },
        debug: {
            command: serverPath,
            args: ["lsp"],
            transport: node_1.TransportKind.stdio,
        },
    };
    const clientOptions = {
        documentSelector: [{ scheme: "file", language: "relanote" }],
        synchronize: {
            fileEvents: vscode.workspace.createFileSystemWatcher("**/*.rela"),
        },
        outputChannelName: "Relanote Language Server",
    };
    client = new node_1.LanguageClient("relanote", "Relanote Language Server", serverOptions, clientOptions);
    await client.start();
    console.log("Relanote Language Server started");
    return client;
}
async function stopClient() {
    if (client) {
        await client.stop();
        client = undefined;
        console.log("Relanote Language Server stopped");
    }
}
async function restartClient(context) {
    await stopClient();
    return startClient(context);
}
function getClient() {
    return client;
}
//# sourceMappingURL=client.js.map