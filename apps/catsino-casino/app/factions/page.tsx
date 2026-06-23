import { redirect } from "next/navigation";
import { createClient } from "@/lib/supabase/server";
import Navbar from "@/components/Navbar";

const FACTIONS = [
  {
    id: "SovereignCrown",
    icon: "👑",
    color: "border-yellow-500 bg-yellow-950",
    textColor: "text-yellow-400",
    tagline: "Elite. Exclusive. Absolute.",
    bonuses: ["+10% slot multiplier", "+5% combat damage", "Highest-rarity companions"],
  },
  {
    id: "WildlandsAscendant",
    icon: "🌿",
    color: "border-green-500 bg-green-950",
    textColor: "text-green-400",
    tagline: "Nature's fury, harnessed.",
    bonuses: ["+5% slot multiplier", "+10% combat damage", "+5 race SPD"],
  },
  {
    id: "VeiledCurrent",
    icon: "🌊",
    color: "border-blue-500 bg-blue-950",
    textColor: "text-blue-400",
    tagline: "Flow unseen. Strike true.",
    bonuses: ["+12% slot multiplier", "+8% combat damage", "+8 race SPD"],
  },
  {
    id: "Factionless",
    icon: "⚡",
    color: "border-gray-500 bg-gray-900",
    textColor: "text-gray-400",
    tagline: "Bound by nothing.",
    bonuses: ["No faction restrictions", "Use any companion", "Full independence"],
  },
];

export default async function FactionsPage() {
  const supabase = await createClient();
  const { data: { user } } = await supabase.auth.getUser();
  if (!user) redirect("/login");

  const [{ data: profile }, { data: wallet }, { data: factionData }] = await Promise.all([
    supabase.from("profiles").select("username, faction, level").eq("id", user.id).single(),
    supabase.from("wallets").select("coins").eq("user_id", user.id).single(),
    supabase.from("profiles").select("faction").not("faction", "is", null),
  ]);

  const username = profile?.username ?? "Cat";
  const coins = wallet?.coins ?? 0;
  const playerFaction = profile?.faction ?? "Factionless";

  // Count members per faction
  const factionCounts: Record<string, number> = {};
  for (const row of factionData ?? []) {
    factionCounts[row.faction] = (factionCounts[row.faction] ?? 0) + 1;
  }

  return (
    <main className="min-h-screen bg-black text-white">
      <Navbar username={username} coins={coins} />
      <section className="max-w-4xl mx-auto px-6 py-8">
        <h1 className="text-3xl font-bold text-purple-400 mb-1">⚔️ Factions</h1>
        <p className="text-gray-400 mb-6">
          Your faction: <span className="font-bold text-white">{playerFaction}</span>
          &nbsp;— change in the Godot MMO client.
        </p>

        <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
          {FACTIONS.map((f) => {
            const isCurrent = f.id === playerFaction;
            return (
              <div
                key={f.id}
                className={`rounded-xl p-5 border ${f.color} ${isCurrent ? "ring-2 ring-purple-500" : ""}`}
              >
                <div className="flex items-center gap-2 mb-2">
                  <span className="text-3xl">{f.icon}</span>
                  <div>
                    <div className={`font-bold text-lg ${f.textColor}`}>{f.id}</div>
                    <div className="text-gray-400 text-sm">{f.tagline}</div>
                  </div>
                  {isCurrent && (
                    <span className="ml-auto text-xs bg-purple-600 text-white px-2 py-1 rounded">YOUR FACTION</span>
                  )}
                </div>
                <div className="space-y-1 mb-3">
                  {f.bonuses.map((b, i) => (
                    <div key={i} className="text-sm text-gray-300 flex items-center gap-1">
                      <span className="text-green-400">✓</span> {b}
                    </div>
                  ))}
                </div>
                <div className="text-xs text-gray-500">
                  {factionCounts[f.id] ?? 0} player{factionCounts[f.id] !== 1 ? "s" : ""} in this faction
                </div>
              </div>
            );
          })}
        </div>
      </section>
    </main>
  );
}
