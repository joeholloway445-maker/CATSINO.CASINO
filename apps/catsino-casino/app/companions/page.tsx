import { redirect } from "next/navigation";
import { createClient } from "@/lib/supabase/server";
import Navbar from "@/components/Navbar";

const FACTION_COLORS: Record<string, string> = {
  SovereignCrown:     "text-yellow-400 border-yellow-600",
  WildlandsAscendant: "text-green-400 border-green-600",
  VeiledCurrent:      "text-blue-400 border-blue-600",
  Factionless:        "text-gray-400 border-gray-600",
};

const FACTION_ICONS: Record<string, string> = {
  SovereignCrown:     "👑",
  WildlandsAscendant: "🌿",
  VeiledCurrent:      "🌊",
  Factionless:        "⚡",
};

const RARITY_STARS = ["", "★", "★★", "★★★", "★★★★", "★★★★★"];

export default async function CompanionsPage() {
  const supabase = await createClient();
  const { data: { user } } = await supabase.auth.getUser();
  if (!user) redirect("/login");

  const [{ data: profile }, { data: wallet }] = await Promise.all([
    supabase.from("profiles").select("username, faction").eq("id", user.id).single(),
    supabase.from("wallets").select("coins").eq("user_id", user.id).single(),
  ]);

  const username = profile?.username ?? "Cat";
  const coins = wallet?.coins ?? 0;
  const playerFaction = profile?.faction ?? "Factionless";

  const COMPANION_PREVIEW = [
    { id: "SC001", name: "Crownthorn Velvet", faction: "SovereignCrown",     rarity: 3, element: "light",  signature: "Thorn Regalia" },
    { id: "SC050", name: "Dusk Saber Yren",   faction: "SovereignCrown",     rarity: 4, element: "shadow", signature: "Dusk Severance" },
    { id: "SC100", name: "Emperor Maximus Vex",faction: "SovereignCrown",    rarity: 5, element: "void",   signature: "Absolute Sovereignty" },
    { id: "WA001", name: "Mossclaw Beren",     faction: "WildlandsAscendant", rarity: 2, element: "earth",  signature: "Root Surge" },
    { id: "WA100", name: "Sovereign of the Wilds", faction: "WildlandsAscendant", rarity: 5, element: "earth", signature: "Wild Sovereignty" },
    { id: "VC001", name: "Silkstrike Naya",    faction: "VeiledCurrent",     rarity: 2, element: "water",  signature: "Ripple Burst" },
    { id: "VC100", name: "The Tideweaver",     faction: "VeiledCurrent",     rarity: 5, element: "void",   signature: "Weave of Tides" },
    { id: "FL001", name: "Stray Bolt Kiko",    faction: "Factionless",       rarity: 1, element: "none",   signature: "Wild Spark" },
    { id: "FL100", name: "The Unaffiliated",   faction: "Factionless",       rarity: 5, element: "none",   signature: "True Independence" },
  ];

  return (
    <main className="min-h-screen bg-black text-white">
      <Navbar username={username} coins={coins} />
      <section className="max-w-5xl mx-auto px-6 py-8">
        <h1 className="text-3xl font-bold text-purple-400 mb-1">🐾 Companions</h1>
        <p className="text-gray-400 mb-2">
          500 named companions across 4 factions. Collect, evolve, and build your roster.
        </p>
        <p className="text-sm text-purple-300 mb-6">
          Your faction: <span className="font-bold">{FACTION_ICONS[playerFaction]} {playerFaction}</span>
        </p>

        <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-4 mb-8">
          {COMPANION_PREVIEW.map((c) => (
            <div
              key={c.id}
              className={`rounded-xl p-4 border bg-gray-900 ${FACTION_COLORS[c.faction] ?? "border-gray-700"}`}
            >
              <div className="flex items-center gap-2 mb-1">
                <span className="text-xl">{FACTION_ICONS[c.faction]}</span>
                <span className="font-bold text-white">{c.name}</span>
              </div>
              <div className="text-xs text-gray-400 mb-1">{c.faction} · {c.element}</div>
              <div className="text-yellow-400 text-sm mb-1">{RARITY_STARS[c.rarity]}</div>
              <div className="text-xs text-gray-300">⚡ {c.signature}</div>
              <div className="text-xs text-gray-600 mt-1">{c.id}</div>
            </div>
          ))}
        </div>

        <div className="bg-gray-900 border border-purple-800 rounded-xl p-5">
          <h2 className="text-lg font-bold text-purple-300 mb-2">Full Roster</h2>
          <p className="text-gray-400 text-sm">
            The complete 500-companion roster is available in the Godot MMO client.
            Launch the game to explore, unlock, and equip companions from all 4 factions.
          </p>
          <div className="grid grid-cols-4 gap-3 mt-4">
            {Object.entries(FACTION_ICONS).map(([faction, icon]) => (
              <div key={faction} className={`text-center p-3 rounded-lg border bg-gray-800 ${FACTION_COLORS[faction]}`}>
                <div className="text-2xl">{icon}</div>
                <div className="text-xs font-bold mt-1">{faction.replace("Ascendant","").replace("Current","")}</div>
                <div className="text-xs text-gray-500 mt-1">
                  {faction === "SovereignCrown" ? "150" : faction === "WildlandsAscendant" ? "150" : faction === "VeiledCurrent" ? "100" : "100"} companions
                </div>
              </div>
            ))}
          </div>
        </div>
      </section>
    </main>
  );
}
