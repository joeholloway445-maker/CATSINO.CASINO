import { createClient } from "@/lib/supabase/server";
import { redirect } from "next/navigation";
import Link from "next/link";
import Navbar from "@/components/Navbar";

const DISTRICTS = [
  {
    id: "paw_vegas",
    name: "Paw Vegas",
    emoji: "🎰",
    description: "The beating heart of Catsino — slot machines, card tables, and the infamous Fortune Wheel. Where fortunes are made and lost.",
    color: "from-yellow-500/20 to-orange-500/20",
    border: "border-yellow-500/40",
    games: ["Slots", "Blackjack", "Fortune Wheel", "Poker"],
    npcs: ["Dealer Dev", "Lucky Lira", "Slot Sam", "???"],
    unlock: "Available from start",
  },
  {
    id: "cat_coliseum",
    name: "Cat Coliseum",
    emoji: "⚔️",
    description: "Ancient arena reborn in neon. Frame-based combat with real stakes. Prove your worth and climb the ranks to challenge Champion Vex.",
    color: "from-red-500/20 to-pink-500/20",
    border: "border-red-500/40",
    games: ["Arena Combat", "Grand Tournament"],
    npcs: ["Arena Guard Brox", "Coach Mira", "Champion Vex"],
    unlock: "Available from start",
  },
  {
    id: "neon_alley",
    name: "Neon Alley",
    emoji: "🌊",
    description: "Canal racing through shimmering neon corridors. The VeiledCurrent controls these waterways — and the odds.",
    color: "from-cyan-500/20 to-blue-500/20",
    border: "border-cyan-500/40",
    games: ["Canal Racing", "Scratch Cards"],
    npcs: ["Aqua Merchant Teal", "Race Starter Nara", "Veiled Scout"],
    unlock: "Available from start",
  },
  {
    id: "cat_forest",
    name: "Cat Forest",
    emoji: "🌿",
    description: "Ancient woodland district. Home to the WildlandsAscendant and the rarest companions. The forest elder holds secrets older than the factions.",
    color: "from-green-500/20 to-emerald-500/20",
    border: "border-green-500/40",
    games: ["Companion Hunting", "Paw Ball"],
    npcs: ["Forest Elder Moss", "Wildlands Ranger", "Companion Keeper Zara"],
    unlock: "Available from start",
  },
  {
    id: "arcade_galaxy",
    name: "Arcade Galaxy",
    emoji: "🕹️",
    description: "No one knows how it got here. No one's asking. An impossible arcade floating above the city, packed with strange games and stranger prizes.",
    color: "from-purple-500/20 to-violet-500/20",
    border: "border-purple-500/40",
    games: ["Cat Puzzle", "Fortune Wheel", "Scratch Card", "Paw Poker"],
    npcs: ["Arcade Host Pixel", "Puzzle Master Gridlock"],
    unlock: "Available from start",
  },
];

export default async function DistrictsPage() {
  const supabase = await createClient();
  const { data: { user } } = await supabase.auth.getUser();
  if (!user) redirect("/login");

  return (
    <div className="min-h-screen bg-gray-950 text-white">
      <Navbar />
      <main className="max-w-5xl mx-auto px-4 py-12">
        <h1 className="text-4xl font-bold text-center text-emerald-400 mb-2">🗺️ Districts</h1>
        <p className="text-center text-gray-400 mb-10">Five worlds. Infinite games. Choose your next destination.</p>

        <div className="space-y-6">
          {DISTRICTS.map((d) => (
            <div
              key={d.id}
              className={`bg-gradient-to-r ${d.color} border ${d.border} rounded-2xl p-6 hover:scale-[1.01] transition-all`}
            >
              <div className="flex flex-col md:flex-row gap-6">
                <div className="text-7xl text-center md:text-left">{d.emoji}</div>
                <div className="flex-1">
                  <div className="flex items-center gap-3 mb-2">
                    <h2 className="text-2xl font-bold">{d.name}</h2>
                    <span className="text-xs bg-green-500/20 text-green-300 px-2 py-0.5 rounded-full">
                      {d.unlock}
                    </span>
                  </div>
                  <p className="text-gray-300 mb-4">{d.description}</p>
                  <div className="flex flex-wrap gap-4">
                    <div>
                      <p className="text-xs text-gray-500 uppercase font-bold mb-1">Games</p>
                      <div className="flex flex-wrap gap-1">
                        {d.games.map(g => (
                          <span key={g} className="text-xs bg-gray-700 text-gray-200 px-2 py-0.5 rounded">{g}</span>
                        ))}
                      </div>
                    </div>
                    <div>
                      <p className="text-xs text-gray-500 uppercase font-bold mb-1">NPCs</p>
                      <div className="flex flex-wrap gap-1">
                        {d.npcs.map(n => (
                          <span key={n} className="text-xs bg-gray-700 text-gray-200 px-2 py-0.5 rounded">{n}</span>
                        ))}
                      </div>
                    </div>
                  </div>
                </div>
                <div className="flex flex-col justify-center gap-2 min-w-[120px]">
                  <Link
                    href={`/games`}
                    className="bg-white/10 hover:bg-white/20 text-white font-semibold py-2 px-4 rounded-lg text-center text-sm transition-all"
                  >
                    Play Games
                  </Link>
                </div>
              </div>
            </div>
          ))}
        </div>
      </main>
    </div>
  );
}
