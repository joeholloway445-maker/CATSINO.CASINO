"use client";

import { useState, useEffect } from "react";
import Navbar from "@/components/Navbar";

interface InventoryItem {
  id: string;
  item_id: string;
  item_type: string;
  quantity: number;
  equipped: boolean;
}

const TYPE_ICONS: Record<string, string> = {
  frame: "🤖",
  cosmetic_frame: "🖼️",
  mod: "⚙️",
  consumable: "🧪",
  cosmetic: "✨",
  companion_item: "🐾",
  boost: "⚡",
};

export default function InventoryPage() {
  const [items, setItems] = useState<InventoryItem[]>([]);
  const [filter, setFilter] = useState("all");
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    fetch("/api/inventory")
      .then(r => r.json())
      .then(d => { setItems(d.items ?? []); setLoading(false); });
  }, []);

  const filtered = filter === "all" ? items : items.filter(i => i.item_type === filter);
  const types = ["all", ...Array.from(new Set(items.map(i => i.item_type)))];

  return (
    <div className="min-h-screen bg-gray-950 text-white">
      <Navbar />
      <main className="max-w-5xl mx-auto px-4 py-12">
        <h1 className="text-4xl font-bold text-center text-cyan-400 mb-2">🎒 Inventory</h1>
        <p className="text-center text-gray-400 mb-8">Your items, frames, mods, and consumables</p>

        <div className="flex flex-wrap gap-2 justify-center mb-8">
          {types.map(t => (
            <button
              key={t}
              onClick={() => setFilter(t)}
              className={`px-4 py-2 rounded-full text-sm font-semibold transition-all ${
                filter === t
                  ? "bg-cyan-500 text-black"
                  : "bg-gray-700 text-gray-300 hover:bg-gray-600"
              }`}
            >
              {t === "all" ? "All Items" : `${TYPE_ICONS[t] ?? "📦"} ${t.charAt(0).toUpperCase() + t.slice(1)}`}
            </button>
          ))}
        </div>

        {loading ? (
          <div className="text-center text-gray-400 py-20">Loading inventory...</div>
        ) : filtered.length === 0 ? (
          <div className="text-center py-20">
            <div className="text-6xl mb-4">📦</div>
            <p className="text-gray-400 text-xl">No items here.</p>
            <p className="text-gray-500 mt-2">Visit the shop to pick up gear!</p>
          </div>
        ) : (
          <div className="grid grid-cols-2 md:grid-cols-3 lg:grid-cols-4 gap-4">
            {filtered.map(item => (
              <div
                key={item.id}
                className={`bg-gray-800 rounded-xl p-4 border-2 transition-all hover:scale-105 ${
                  item.equipped ? "border-cyan-400" : "border-gray-600 hover:border-gray-400"
                }`}
              >
                <div className="text-4xl text-center mb-2">
                  {TYPE_ICONS[item.item_type] ?? "📦"}
                </div>
                <h3 className="text-sm font-bold text-center text-white mb-1">
                  {item.item_id.replace(/_/g, " ").replace(/\b\w/g, c => c.toUpperCase())}
                </h3>
                <p className="text-xs text-center text-gray-400 capitalize mb-2">{item.item_type}</p>
                {item.quantity > 1 && (
                  <p className="text-xs text-center text-yellow-400">×{item.quantity}</p>
                )}
                {item.equipped && (
                  <div className="text-center mt-2">
                    <span className="text-xs bg-cyan-500/20 text-cyan-300 px-2 py-0.5 rounded-full">Equipped</span>
                  </div>
                )}
              </div>
            ))}
          </div>
        )}
      </main>
    </div>
  );
}
