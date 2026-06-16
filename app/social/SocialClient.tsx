"use client";

import { useState } from "react";
import { motion, AnimatePresence } from "framer-motion";

type LeaderboardEntry = { username: string; level: number; total_winnings: number };

interface Props {
  username: string;
  level: number;
  leaderboard: LeaderboardEntry[];
}

const RANK_MEDALS = ["🥇", "🥈", "🥉"];

export default function SocialClient({ username, level, leaderboard }: Props) {
  const [activeTab, setActiveTab] = useState<"leaderboard" | "guilds" | "friends">("leaderboard");
  const [friendInput, setFriendInput] = useState("");
  const [friendMsg, setFriendMsg] = useState("");

  async function addFriend() {
    if (!friendInput.trim()) return;
    const res = await fetch("/api/social/friend", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ username: friendInput }),
    });
    const data = await res.json();
    setFriendMsg(data.success ? `Added ${friendInput}!` : (data.error ?? "Error"));
    setFriendInput("");
  }

  return (
    <div className="min-h-screen bg-black text-white p-6">
      <div className="max-w-3xl mx-auto">
        <h1 className="text-3xl font-bold text-purple-400 mb-1">🐱 Social Hub</h1>
        <p className="text-gray-400 mb-6">Welcome back, {username} (Lv.{level})</p>

        {/* Tabs */}
        <div className="flex gap-2 mb-6">
          {(["leaderboard", "guilds", "friends"] as const).map((tab) => (
            <button
              key={tab}
              onClick={() => setActiveTab(tab)}
              className={`px-4 py-2 rounded capitalize font-semibold transition-colors ${
                activeTab === tab
                  ? "bg-purple-600 text-white"
                  : "bg-gray-800 text-gray-400 hover:bg-gray-700"
              }`}
            >
              {tab === "leaderboard" ? "🏆 Leaderboard" : tab === "guilds" ? "⚔️ Guilds" : "👥 Friends"}
            </button>
          ))}
        </div>

        <AnimatePresence mode="wait">
          {activeTab === "leaderboard" && (
            <motion.div
              key="leaderboard"
              initial={{ opacity: 0, y: 10 }}
              animate={{ opacity: 1, y: 0 }}
              exit={{ opacity: 0, y: -10 }}
              className="bg-gray-900 rounded-xl p-4"
            >
              <h2 className="text-xl font-bold text-yellow-400 mb-4">Top Cats by Winnings</h2>
              {leaderboard.length === 0 ? (
                <p className="text-gray-500">No players yet. Be the first!</p>
              ) : (
                <div className="space-y-2">
                  {leaderboard.map((entry, i) => (
                    <div
                      key={entry.username}
                      className={`flex items-center gap-3 p-3 rounded-lg ${
                        entry.username === username ? "bg-purple-900 border border-purple-500" : "bg-gray-800"
                      }`}
                    >
                      <span className="text-2xl w-8">{RANK_MEDALS[i] ?? `#${i + 1}`}</span>
                      <span className="flex-1 font-semibold">{entry.username}</span>
                      <span className="text-gray-400 text-sm">Lv.{entry.level}</span>
                      <span className="text-yellow-400 font-bold">
                        {entry.total_winnings?.toLocaleString() ?? 0} 🪙
                      </span>
                    </div>
                  ))}
                </div>
              )}
            </motion.div>
          )}

          {activeTab === "guilds" && (
            <motion.div
              key="guilds"
              initial={{ opacity: 0, y: 10 }}
              animate={{ opacity: 1, y: 0 }}
              exit={{ opacity: 0, y: -10 }}
              className="bg-gray-900 rounded-xl p-4"
            >
              <h2 className="text-xl font-bold text-purple-400 mb-2">⚔️ Guilds</h2>
              <p className="text-gray-400 mb-4">Guilds are managed in the Godot MMO client. Join the world to create or join a guild.</p>
              <div className="grid grid-cols-2 gap-3">
                {[
                  { name: "SovereignCrown", icon: "👑", members: "???", desc: "Elite and exclusive — invitation only." },
                  { name: "WildlandsAscendant", icon: "🌿", members: "???", desc: "Nature-first, faction-strong." },
                  { name: "VeiledCurrent", icon: "🌊", members: "???", desc: "Flow with the tide, unseen." },
                  { name: "Factionless", icon: "⚡", members: "???", desc: "Bound by nothing. Free to roam." },
                ].map((g) => (
                  <div key={g.name} className="bg-gray-800 rounded-lg p-3">
                    <div className="text-2xl mb-1">{g.icon}</div>
                    <div className="font-bold text-white">{g.name}</div>
                    <div className="text-gray-400 text-xs mt-1">{g.desc}</div>
                  </div>
                ))}
              </div>
            </motion.div>
          )}

          {activeTab === "friends" && (
            <motion.div
              key="friends"
              initial={{ opacity: 0, y: 10 }}
              animate={{ opacity: 1, y: 0 }}
              exit={{ opacity: 0, y: -10 }}
              className="bg-gray-900 rounded-xl p-4"
            >
              <h2 className="text-xl font-bold text-green-400 mb-4">👥 Add a Friend</h2>
              <div className="flex gap-2 mb-3">
                <input
                  className="flex-1 bg-gray-800 text-white px-3 py-2 rounded border border-gray-700 outline-none focus:border-purple-500"
                  placeholder="Enter username..."
                  value={friendInput}
                  onChange={(e) => setFriendInput(e.target.value)}
                  onKeyDown={(e) => e.key === "Enter" && addFriend()}
                />
                <button
                  onClick={addFriend}
                  className="bg-purple-600 hover:bg-purple-700 px-4 py-2 rounded font-semibold transition-colors"
                >
                  Add
                </button>
              </div>
              {friendMsg && (
                <p className={`text-sm ${friendMsg.startsWith("Added") ? "text-green-400" : "text-red-400"}`}>
                  {friendMsg}
                </p>
              )}
              <p className="text-gray-500 text-sm mt-4">
                Friend lists and real-time chat are available in the Godot MMO client.
              </p>
            </motion.div>
          )}
        </AnimatePresence>
      </div>
    </div>
  );
}
