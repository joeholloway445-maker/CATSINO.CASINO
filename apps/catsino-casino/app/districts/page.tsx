import { createClient } from "@/lib/supabase/server";
import { redirect } from "next/navigation";
import Link from "next/link";
import Navbar from "@/components/Navbar";

// The Superliminal layer: the DFW Metroplex, four canon cities.
// Mirrors godot/src/data/hub_region_data.gd + city_data.gd — if you rename
// or add landmarks there, update here.
const CITIES = [
  {
    id: "arlington",
    name: "Soulless Sanctuary",
    real: "Arlington",
    faction: "Neutral — the factionless start",
    emoji: "🕍",
    accent: "text-violet-300 border-violet-400/40",
    glow: "from-violet-500/10 to-fuchsia-500/5",
    description:
      "The neutral heart of the Metroplex — sanctuary for everyone, home to no one. The ONLY city with the Arena, the College, and the Space Station gate.",
    landmarks: ["Sanctuary Dome (Arena)", "Star Bowl", "Space Station", "College Hall"],
    exclusive: true,
  },
  {
    id: "dallas",
    name: "New Dallas",
    real: "Dallas",
    faction: "Sovereign Crown",
    emoji: "👑",
    accent: "text-amber-300 border-amber-400/40",
    glow: "from-amber-500/10 to-yellow-500/5",
    description:
      "The Sovereign seat — the old skyline rebuilt taller, crowned in gold. The spires kept their bones; the city kept nothing else.",
    landmarks: ["Reunion Spire", "Emerald Slab", "Veil Arch"],
  },
  {
    id: "fort_worth",
    name: "Hell's Half Acre",
    real: "Fort Worth",
    faction: "Veiled Current",
    emoji: "🌊",
    accent: "text-sky-300 border-sky-400/40",
    glow: "from-sky-500/10 to-blue-500/5",
    description:
      "The Veiled haunt — named for the old red-light quarter that never really closed. Stockyards, river channels, and deals made in the dark between them.",
    landmarks: ["Acre Clocktower", "Longhorn Gate"],
  },
  {
    id: "denton",
    name: "Sky Fjord",
    real: "Denton",
    faction: "Wildlands Ascendant",
    emoji: "🌿",
    accent: "text-emerald-300 border-emerald-400/40",
    glow: "from-emerald-500/10 to-green-500/5",
    description:
      "The Wildlands reach — the courthouse square drowned in green, the lowlands north of the Metroplex carved open to the sky.",
    landmarks: ["Fjord Dome", "Sky Tank"],
  },
];

const CIVIC_SET = ["Market", "Bank", "Armorer", "Blacksmith", "Stockyards", "Wager Hall"];

export default async function DistrictsPage() {
  const supabase = await createClient();
  const { data: { user } } = await supabase.auth.getUser();
  if (!user) redirect("/login");

  return (
    <div className="min-h-screen bg-[#050409] text-white">
      <Navbar />
      <main className="max-w-5xl mx-auto px-4 py-12">
        <h1 className="text-4xl font-bold text-center tracking-widest text-violet-300 mb-2">
          THE DFW METROPLEX
        </h1>
        <p className="text-center text-slate-400 mb-2">
          The Superliminal layer. Four cities, one wilderness between them.
        </p>
        <p className="text-center text-slate-600 text-sm mb-10">
          Every city carries the civic set — {CIVIC_SET.join(" · ")} — and everything
          beyond the city limits is procedural, painted by whoever walks it.
        </p>

        <div className="space-y-6">
          {CITIES.map((c) => (
            <div
              key={c.id}
              className={`bg-gradient-to-r ${c.glow} border ${c.accent} rounded-2xl p-6 bg-black/40`}
            >
              <div className="flex flex-col md:flex-row gap-6">
                <div className="text-7xl text-center md:text-left">{c.emoji}</div>
                <div className="flex-1">
                  <div className="flex items-center gap-3 mb-1 flex-wrap">
                    <h2 className={`text-2xl font-bold tracking-wide ${c.accent.split(" ")[0]}`}>
                      {c.name}
                    </h2>
                    <span className="text-xs text-slate-500 uppercase tracking-wider">
                      {c.real}
                    </span>
                    {c.exclusive && (
                      <span className="text-xs bg-violet-500/20 text-violet-300 px-2 py-0.5 rounded-full">
                        Arena · College · Space Station
                      </span>
                    )}
                  </div>
                  <p className="text-xs text-slate-500 uppercase tracking-wider mb-2">{c.faction}</p>
                  <p className="text-slate-300 mb-4">{c.description}</p>
                  <div>
                    <p className="text-xs text-slate-500 uppercase font-bold mb-1">Skyline</p>
                    <div className="flex flex-wrap gap-1">
                      {c.landmarks.map((l) => (
                        <span key={l} className="text-xs bg-white/5 border border-white/10 text-slate-300 px-2 py-0.5 rounded">
                          {l}
                        </span>
                      ))}
                    </div>
                  </div>
                </div>
              </div>
            </div>
          ))}
        </div>

        <p className="text-center text-slate-600 text-sm mt-10">
          The Metroplex is explorable in the game client (Superliminal layer).
          Looking for the Catsino floors instead?{" "}
          <Link href="/games" className="text-fuchsia-400 hover:underline">
            The Hyperliminal is this way
          </Link>
          .
        </p>
      </main>
    </div>
  );
}
