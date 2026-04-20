import { useState, useEffect, useCallback } from "react";
import { invoke } from "@tauri-apps/api/core";
import Terminal from "./Terminal";
import Settings from "./Settings";

interface Config {
  openai_api_key?: string;
  anthropic_api_key?: string;
  working_directory?: string;
}

interface NodeInfo {
  node_path?: string;
  bundled?: string;
  npm_prefix?: string;
}

function App() {
  const [settingsOpen, setSettingsOpen] = useState(false);
  const [config, setConfig] = useState<Config>({});
  const [nodeInfo, setNodeInfo] = useState<NodeInfo>({});
  const [terminalKey, setTerminalKey] = useState(0);
  const [showHelp, setShowHelp] = useState(true);

  useEffect(() => {
    invoke<Config>("get_config").then(setConfig).catch(console.error);
    invoke<NodeInfo>("get_node_info").then(setNodeInfo).catch(console.error);
  }, []);

  const handleConfigSave = useCallback((newConfig: Config) => {
    setConfig(newConfig);
    setTerminalKey((k) => k + 1);
  }, []);

  const env: Record<string, string> = {};
  if (config.openai_api_key) {
    env.OPENAI_API_KEY = config.openai_api_key;
  }
  if (config.anthropic_api_key) {
    env.ANTHROPIC_API_KEY = config.anthropic_api_key;
  }

  return (
    <div className="h-full flex flex-col bg-[#12121f]">
      {/* Header */}
      <header className="flex items-center justify-between px-4 py-2 bg-[#1a1a2e] border-b border-gray-700">
        <div className="flex items-center gap-3">
          <h1 className="text-lg font-semibold text-white">Codex Trainer</h1>
          <span className="text-xs text-gray-400 bg-gray-700 px-2 py-0.5 rounded">
            v1.0.0
          </span>
          {nodeInfo.bundled === "true" && (
            <span className="text-xs text-green-400 bg-green-900/30 px-2 py-0.5 rounded">
              Node.js bundled
            </span>
          )}
        </div>

        <div className="flex items-center gap-2">
          <button
            onClick={() => setShowHelp(!showHelp)}
            className="flex items-center gap-2 px-3 py-1.5 text-sm text-gray-300 hover:text-white hover:bg-gray-700 rounded-lg transition-colors"
          >
            <svg className="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M13 16h-1v-4h-1m1-4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z" />
            </svg>
            Help
          </button>
          <button
            onClick={() => setSettingsOpen(true)}
            className="flex items-center gap-2 px-3 py-1.5 text-sm text-gray-300 hover:text-white hover:bg-gray-700 rounded-lg transition-colors"
          >
            <svg className="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M10.325 4.317c.426-1.756 2.924-1.756 3.35 0a1.724 1.724 0 002.573 1.066c1.543-.94 3.31.826 2.37 2.37a1.724 1.724 0 001.065 2.572c1.756.426 1.756 2.924 0 3.35a1.724 1.724 0 00-1.066 2.573c.94 1.543-.826 3.31-2.37 2.37a1.724 1.724 0 00-2.572 1.065c-.426 1.756-2.924 1.756-3.35 0a1.724 1.724 0 00-2.573-1.066c-1.543.94-3.31-.826-2.37-2.37a1.724 1.724 0 00-1.065-2.572c-1.756-.426-1.756-2.924 0-3.35a1.724 1.724 0 001.066-2.573c-.94-1.543.826-3.31 2.37-2.37.996.608 2.296.07 2.572-1.065z" />
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M15 12a3 3 0 11-6 0 3 3 0 016 0z" />
            </svg>
            Settings
          </button>
        </div>
      </header>

      {/* Help Banner */}
      {showHelp && (
        <div className="px-4 py-3 bg-blue-900/30 border-b border-blue-700/50">
          <div className="flex justify-between items-start">
            <div className="space-y-2">
              <p className="text-sm text-blue-200 font-medium">
                Getting Started (Node.js is bundled - no install needed!)
              </p>
              <ol className="text-sm text-blue-100/80 space-y-1 list-decimal list-inside">
                <li>
                  Click <strong>Settings</strong> and add your OpenAI API key
                </li>
                <li>
                  Install Codex:{" "}
                  <code className="bg-black/30 px-1.5 py-0.5 rounded font-mono text-xs">
                    npm install -g @openai/codex
                  </code>
                </li>
                <li>
                  Run Codex:{" "}
                  <code className="bg-black/30 px-1.5 py-0.5 rounded font-mono text-xs">
                    codex "create a todo app with html and css"
                  </code>
                </li>
                <li>
                  View generated files in your home directory
                </li>
              </ol>
            </div>
            <button
              onClick={() => setShowHelp(false)}
              className="text-blue-300 hover:text-white p-1"
            >
              <svg className="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M6 18L18 6M6 6l12 12" />
              </svg>
            </button>
          </div>
        </div>
      )}

      {/* API Key Warning */}
      {!config.openai_api_key && !showHelp && (
        <div className="px-4 py-2 bg-yellow-900/30 border-b border-yellow-700/50">
          <p className="text-sm text-yellow-200">
            <strong>Note:</strong> Click Settings to add your OpenAI API key before using Codex
          </p>
        </div>
      )}

      {/* Terminal */}
      <main className="flex-1 p-2 overflow-hidden">
        <Terminal
          key={terminalKey}
          env={Object.keys(env).length > 0 ? env : undefined}
          cwd={config.working_directory}
        />
      </main>

      {/* Settings Modal */}
      <Settings
        isOpen={settingsOpen}
        onClose={() => setSettingsOpen(false)}
        onSave={handleConfigSave}
      />
    </div>
  );
}

export default App;
