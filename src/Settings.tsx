import { useState, useEffect } from "react";
import { invoke } from "@tauri-apps/api/core";

interface Config {
  openai_api_key?: string;
  anthropic_api_key?: string;
  working_directory?: string;
}

interface SettingsProps {
  isOpen: boolean;
  onClose: () => void;
  onSave: (config: Config) => void;
}

export default function Settings({ isOpen, onClose, onSave }: SettingsProps) {
  const [config, setConfig] = useState<Config>({});
  const [saving, setSaving] = useState(false);

  useEffect(() => {
    if (isOpen) {
      invoke<Config>("get_config").then(setConfig).catch(console.error);
    }
  }, [isOpen]);

  const handleSave = async () => {
    setSaving(true);
    try {
      await invoke("save_config", { config });
      onSave(config);
      onClose();
    } catch (error) {
      console.error("Failed to save config:", error);
    } finally {
      setSaving(false);
    }
  };

  if (!isOpen) return null;

  return (
    <div className="fixed inset-0 bg-black/60 flex items-center justify-center z-50">
      <div className="bg-[#1e1e32] rounded-xl shadow-2xl w-full max-w-md p-6 border border-gray-700">
        <h2 className="text-xl font-semibold mb-4 text-white">Settings</h2>

        <div className="space-y-4">
          <div>
            <label className="block text-sm font-medium text-gray-300 mb-1">
              OpenAI API Key
            </label>
            <input
              type="password"
              value={config.openai_api_key || ""}
              onChange={(e) =>
                setConfig({ ...config, openai_api_key: e.target.value })
              }
              placeholder="sk-..."
              className="w-full px-3 py-2 bg-[#12121f] border border-gray-600 rounded-lg text-white placeholder-gray-500 focus:outline-none focus:border-blue-500"
            />
            <p className="mt-1 text-xs text-gray-400">
              Used as OPENAI_API_KEY environment variable
            </p>
          </div>

          <div>
            <label className="block text-sm font-medium text-gray-300 mb-1">
              Anthropic API Key (optional)
            </label>
            <input
              type="password"
              value={config.anthropic_api_key || ""}
              onChange={(e) =>
                setConfig({ ...config, anthropic_api_key: e.target.value })
              }
              placeholder="sk-ant-..."
              className="w-full px-3 py-2 bg-[#12121f] border border-gray-600 rounded-lg text-white placeholder-gray-500 focus:outline-none focus:border-blue-500"
            />
            <p className="mt-1 text-xs text-gray-400">
              Used as ANTHROPIC_API_KEY environment variable
            </p>
          </div>

          <div>
            <label className="block text-sm font-medium text-gray-300 mb-1">
              Working Directory
            </label>
            <input
              type="text"
              value={config.working_directory || ""}
              onChange={(e) =>
                setConfig({ ...config, working_directory: e.target.value })
              }
              placeholder="Leave empty for home directory"
              className="w-full px-3 py-2 bg-[#12121f] border border-gray-600 rounded-lg text-white placeholder-gray-500 focus:outline-none focus:border-blue-500"
            />
          </div>
        </div>

        <div className="flex justify-end gap-3 mt-6">
          <button
            onClick={onClose}
            className="px-4 py-2 text-gray-300 hover:text-white transition-colors"
          >
            Cancel
          </button>
          <button
            onClick={handleSave}
            disabled={saving}
            className="px-4 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700 transition-colors disabled:opacity-50"
          >
            {saving ? "Saving..." : "Save & Restart Terminal"}
          </button>
        </div>
      </div>
    </div>
  );
}
