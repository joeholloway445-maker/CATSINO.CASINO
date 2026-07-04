"use client";

import { useState } from "react";
import Navbar from "@/components/Navbar";

const RARITY_COLORS: Record<string, string> = {
  common: "text-gray-300 border-gray-500",
  uncommon: "text-green-300 border-green-500",
  rare: "text-cyan-300 border-cyan-500",
  epic: "text-purple-300 border-purple-500",
  legendary: "text-yellow-300 border-yellow-400",
};

const FACTIONS = ["Any", "SovereignCrown", "WildlandsAscendant", "VeiledCurrent", "Factionless"];

interface SummonResult {
  companion_id: string;
  faction: string;
  rarity: string;
}

export default function SummonPage() {
  const [results, setResults] = useState<SummonResult[]>([]);
  const [loading, setLoading] = useState(false);
  const [faction, setFaction] = useState("Any");
  const [error, setError] = useState("");

  const summon = async (count: 1 | 10) => {
    setLoading(true);
    setError("");
    try {
      const res = await fetch("/api/companions/summon", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ count, faction: faction === "Any" ? "" : faction }),
      });
      const data = await res.json();
      if (data.error) { setError(data.error); return; }
      setResults(data.companions ?? []);
    } catch {
      setError("Network error");
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="min-h-screen bg-gray-950 text-white">
      <Navbar />
      <main className="max-w-3xl mx-auto px-4 py-12">
        <h1 className="text-4xl font-bold text-center text-purple-400 mb-2">✨ Companion Summon</h1>
        <p className="text-center text-gray-400 mb-8">Spend Charges to discover new companions</p>

        <div className="bg-gray-800 rounded-2xl p-6 mb-8">
          <div className="flex flex-wrap gap-3 justify-center mb-6">
            <select
              value={faction}
              onChange={e => setFaction(e.target.value)}
              className="bg-gray-700 text-white px-4 py-2 rounded-lg border border-gray-600"
            >
              {FACTIONS.map(f => <option key={f}>{f}</option>)}
            </select>
          </div>

          <div className="flex gap-4 justify-center">
            <button
              onClick={() => summon(1)}
              disabled={loading}
              className="bg-purple-600 hover:bg-purple-500 disabled:opacity-50 text-white font-bold py-3 px-8 rounded-xl transition-all hover:scale-105"
            >
              Summon × 1
              <span className="block text-xs text-purple-200">300 charges</span>
            </button>
            <button
              onClick={() => summon(10)}
              disabled={loading}
              className="bg-yellow-600 hover:bg-yellow-500 disabled:opacity-50 text-black font-bold py-3 px-8 rounded-xl transition-all hover:scale-105"
            >
              Summon × 10
              <span className="block text-xs text-yellow-900">2,500 charges</span>
            </button>
          </div>

          {error && <p className="text-red-400 text-center mt-4">{error}</p>}
        </div>

        <div className="mb-6 text-sm text-gray-500 text-center">
          <span className="text-white font-semibold">Rates: </span>
          Common 60% • Uncommon 25% • Rare 10% • Epic 4% • Legendary 1%
          <span className="block text-purple-400 mt-1">Pity system: guaranteed Epic at 50 pulls</span>
        </div>

        {results.length > 0 && (
          <div className="grid grid-cols-2 md:grid-cols-5 gap-3">
            {results.map((r, i) => (
              <div
                key={i}
                className={`border-2 rounded-xl p-3 text-center ${RARITY_COLORS[r.rarity]}`}
              >
                <p className="text-2xl mb-1">🐱</p>
                <p className="text-xs font-bold">{r.companion_id}</p>
                <p className="text-xs opacity-70">{r.faction.replace("Ascendant", "").replace("Current", "").replace("Sovereign", "SC")}</p>
                <p className="text-xs font-semibold uppercase mt-1">{r.rarity}</p>
              </div>
            ))}
          </div>
        )}

        <div className="mt-12 bg-gray-800/50 rounded-xl p-6">
          <h2 className="text-lg font-bold text-yellow-300 mb-4">🎰 Summon Rates</h2>
          <div className="space-y-2 text-sm">
            {[
              { rarity: "legendary", rate: "1%", color: "text-yellow-400" },
              { rarity: "epic", rate: "4%", color: "text-purple-400" },
              { rarity: "rare", rate: "10%", color: "text-cyan-400" },
              { rarity: "uncommon", rate: "25%", color: "text-green-400" },
              { rarity: "common", rate: "60%", color: "text-gray-300" },
            ].map(r => (
              <div key={r.rarity} className="flex justify-between">
                <span className={`capitalize ${r.color}`}>{r.rarity}</span>
                <span className="text-gray-400">{r.rate}</span>
              </div>
            ))}
          </div>
        </div>
      </main>
    </div>
  );
}
