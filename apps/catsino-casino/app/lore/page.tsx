import { redirect } from "next/navigation";
import { createClient } from "@/lib/supabase/server";
import Navbar from "@/components/Navbar";

const LORE = {
  world: `PAW VEGAS — a city built on luck, speed, and the eternal battle for style.

Once a sleepy desert outpost, Paw Vegas was transformed overnight when the SovereignCrown arrived and declared it the capital of the new world order. Within a decade, five districts rose from the sand: each one a battlefield for the four great factions.

The slots spin. The reels turn. The cats race.

And somewhere beneath it all — in the roots, in the currents, in the void — something watches.`,

  districts: [
    { id: "paw_vegas",     name: "Paw Vegas Central", icon: "🎰", lore: "The crown jewel of the city. Neon towers and slot machines stretch as far as the eye can see. The SovereignCrown's casino empire began here — and all the other factions followed." },
    { id: "cat_coliseum",  name: "Cat Coliseum",       icon: "⚔️", lore: "Ancient before the city existed. Carved from black obsidian by the original Wildlands settlers. Now Paw Vegas' premier combat arena. Only the strong endure." },
    { id: "neon_alley",    name: "Neon Alley",          icon: "🏁", lore: "The VeiledCurrent's territory. Neon canals, water races, and underground betting dens. The fastest cats in the world come here to prove their speed." },
    { id: "cat_forest",    name: "Cat Forest",          icon: "🌿", lore: "The Wildlands' sacred territory. Ancient trees, hidden clearings, and companions who haven't seen the city in decades. Quests begin here. Legends are born here." },
    { id: "arcade_galaxy", name: "Arcade Galaxy",       icon: "👾", lore: "No one knows who built it. The Arcade Galaxy appeared one morning — a floating platform above the city. The factions all claim ownership. None have proven it." },
  ],

  factions: [
    { id: "SovereignCrown",     icon: "👑", color: "text-yellow-400", lore: "They arrived first. They built fastest. They rule hardest. The SovereignCrown is Paw Vegas' founding faction — a coalition of elite cats who built the city's casino empire." },
    { id: "WildlandsAscendant", icon: "🌿", color: "text-green-400",  lore: "Before the city, there was the forest. The Wildlands faction traces its lineage to the original settlers of Cat Forest. They carry the Factionless label now like a weapon." },
    { id: "VeiledCurrent",      icon: "🌊", color: "text-blue-400",   lore: "You don't see the Current. You feel it. The VeiledCurrent emerged from Neon Alley's underground water network — born of smugglers, racers, and cats who preferred to operate unseen." },
    { id: "Factionless",        icon: "⚡", color: "text-gray-400",   lore: "Not a faction. An absence of one. Some cats answer to no one. A rare few — like The Unaffiliated — transcend faction entirely, earning the respect of all four without belonging to any." },
  ],
};

export default async function LorePage() {
  const supabase = await createClient();
  const { data: { user } } = await supabase.auth.getUser();
  if (!user) redirect("/login");

  const [{ data: profile }, { data: wallet }] = await Promise.all([
    supabase.from("profiles").select("username").eq("id", user.id).single(),
    supabase.from("wallets").select("coins").eq("user_id", user.id).single(),
  ]);

  return (
    <main className="min-h-screen bg-black text-white">
      <Navbar username={profile?.username ?? "Cat"} coins={wallet?.coins ?? 0} />
      <section className="max-w-3xl mx-auto px-6 py-8">
        <h1 className="text-3xl font-bold text-purple-400 mb-6">📖 World Lore</h1>

        <div className="bg-gray-900 border border-purple-800 rounded-xl p-5 mb-8">
          <h2 className="text-xl font-bold text-white mb-3">Paw Vegas</h2>
          <p className="text-gray-300 whitespace-pre-line text-sm leading-relaxed">{LORE.world}</p>
        </div>

        <h2 className="text-xl font-bold text-purple-300 mb-4">🗺️ The Five Districts</h2>
        <div className="space-y-3 mb-8">
          {LORE.districts.map((d) => (
            <div key={d.id} className="bg-gray-900 border border-gray-700 rounded-lg p-4">
              <div className="flex items-center gap-2 mb-1">
                <span className="text-2xl">{d.icon}</span>
                <span className="font-bold text-white">{d.name}</span>
              </div>
              <p className="text-gray-400 text-sm">{d.lore}</p>
            </div>
          ))}
        </div>

        <h2 className="text-xl font-bold text-purple-300 mb-4">⚔️ The Four Factions</h2>
        <div className="space-y-3">
          {LORE.factions.map((f) => (
            <div key={f.id} className="bg-gray-900 border border-gray-700 rounded-lg p-4">
              <div className="flex items-center gap-2 mb-1">
                <span className="text-2xl">{f.icon}</span>
                <span className={`font-bold ${f.color}`}>{f.id}</span>
              </div>
              <p className="text-gray-400 text-sm">{f.lore}</p>
            </div>
          ))}
        </div>
      </section>
    </main>
  );
}
