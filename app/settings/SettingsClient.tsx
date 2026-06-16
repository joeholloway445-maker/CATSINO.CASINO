"use client";

import { useState } from "react";

interface Props {
  initialUsername: string;
  email: string;
  faction: string;
}

export default function SettingsClient({ initialUsername, email, faction }: Props) {
  const [username, setUsername] = useState(initialUsername);
  const [saving, setSaving] = useState(false);
  const [message, setMessage] = useState("");

  const saveProfile = async () => {
    setSaving(true);
    setMessage("");
    try {
      const res = await fetch("/api/profile", {
        method: "PATCH",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ username }),
      });
      const data = await res.json();
      setMessage(data.error ? `Error: ${data.error}` : "Profile saved!");
    } finally {
      setSaving(false);
    }
  };

  return (
    <div className="space-y-6">
      <div className="bg-gray-800 rounded-2xl p-6">
        <h2 className="text-lg font-bold text-white mb-4">👤 Account</h2>
        <div className="space-y-4">
          <div>
            <label className="block text-sm text-gray-400 mb-1">Email</label>
            <input
              type="text"
              value={email}
              disabled
              className="w-full bg-gray-700/50 text-gray-400 px-4 py-2 rounded-lg border border-gray-600 cursor-not-allowed"
            />
          </div>
          <div>
            <label className="block text-sm text-gray-400 mb-1">Username</label>
            <input
              type="text"
              value={username}
              onChange={e => setUsername(e.target.value)}
              maxLength={20}
              className="w-full bg-gray-700 text-white px-4 py-2 rounded-lg border border-gray-600 focus:border-purple-500 focus:outline-none"
            />
          </div>
          <button
            onClick={saveProfile}
            disabled={saving}
            className="bg-purple-600 hover:bg-purple-500 disabled:opacity-50 text-white font-semibold py-2 px-6 rounded-lg transition-all"
          >
            {saving ? "Saving..." : "Save Profile"}
          </button>
          {message && <p className={`text-sm ${message.startsWith("Error") ? "text-red-400" : "text-green-400"}`}>{message}</p>}
        </div>
      </div>

      <div className="bg-gray-800 rounded-2xl p-6">
        <h2 className="text-lg font-bold text-white mb-4">⚔️ Faction</h2>
        <p className="text-gray-400 text-sm mb-2">Current faction: <span className="text-yellow-400 font-semibold">{faction === "none" ? "None" : faction}</span></p>
        <p className="text-gray-500 text-xs">Change your faction from the <a href="/factions" className="text-cyan-400 hover:underline">Factions page</a>. Note: changing factions resets your faction progress.</p>
      </div>

      <div className="bg-gray-800 rounded-2xl p-6">
        <h2 className="text-lg font-bold text-white mb-4">🔒 Security</h2>
        <p className="text-gray-400 text-sm mb-4">Manage your account security through Supabase auth.</p>
        <a
          href="/auth/update-password"
          className="text-cyan-400 hover:text-cyan-300 text-sm underline"
        >
          Change Password
        </a>
      </div>

      <div className="bg-gray-800/50 rounded-2xl p-6 border border-gray-700">
        <h2 className="text-lg font-bold text-gray-400 mb-2">ℹ️ About</h2>
        <p className="text-gray-500 text-sm">
          CATSINO.CASINO — Free-to-play virtual cat casino. All games use virtual Cat Coins only.
          No real money involved. All RNG is server-authoritative.
        </p>
      </div>
    </div>
  );
}
