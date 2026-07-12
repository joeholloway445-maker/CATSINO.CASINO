import { createClient } from "@/lib/supabase/server";
import { redirect } from "next/navigation";
import Navbar from "@/components/Navbar";

/** OmniDex identity frames only — exactly 20. Shop cosmetics are not listed. */
const FRAMES = [
  { id: "skirmisher", name: "Skirmisher", spd: 16 },
  { id: "strider", name: "Strider", spd: 18 },
  { id: "skybound", name: "Skybound", spd: 17 },
  { id: "flicker", name: "Flicker", spd: 18 },
  { id: "marshal", name: "Marshal", spd: 12 },
  { id: "bloom", name: "Bloom", spd: 14 },
  { id: "rewind", name: "Rewind", spd: 14 },
  { id: "conduit", name: "Conduit", spd: 13 },
  { id: "shade", name: "Shade", spd: 16 },
  { id: "fabricator", name: "Fabricator", spd: 12 },
  { id: "bastion", name: "Bastion", spd: 6 },
  { id: "juggernaut", name: "Juggernaut", spd: 7 },
  { id: "gravemind", name: "Gravemind", spd: 6 },
  { id: "riftbreaker", name: "Riftbreaker", spd: 6 },
  { id: "sovereign", name: "Sovereign", spd: 5 },
  { id: "worldroot", name: "Worldroot", spd: 5 },
  { id: "epoch", name: "Epoch", spd: 6 },
  { id: "overlord", name: "Overlord", spd: 4 },
  { id: "obscura", name: "Obscura", spd: 6 },
  { id: "architect", name: "Architect", spd: 4 },
] as const;

const TRACKS = [
  { id: "neon_canal", name: "Neon Canal Circuit", district: "Neon Alley", laps: 3, entry_fee: 200, difficulty: "Beginner", emoji: "🌊" },
  { id: "paw_strip", name: "Paw Vegas Strip", district: "Paw Vegas", laps: 1, entry_fee: 500, difficulty: "Intermediate", emoji: "🎰" },
  { id: "forest_path", name: "Forest Wild Run", district: "Cat Forest", laps: 2, entry_fee: 400, difficulty: "Intermediate", emoji: "🌿" },
  { id: "coliseum_track", name: "Coliseum Grand Prix", district: "Cat Coliseum", laps: 5, entry_fee: 1000, difficulty: "Expert", emoji: "⚔️" },
  { id: "galaxy_circuit", name: "Arcade Galaxy Dash", district: "Arcade Galaxy", laps: 1, entry_fee: 100, difficulty: "Beginner", emoji: "🕹️" },
];

const DIFF_COLORS: Record<string, string> = {
  Beginner: "text-green-400 bg-green-400/10",
  Intermediate: "text-yellow-400 bg-yellow-400/10",
  Expert: "text-red-400 bg-red-400/10",
};

export default async function RacesPage() {
  const supabase = await createClient();
  const { data: { user } } = await supabase.auth.getUser();
  if (!user) redirect("/login");

  const { data: wallet } = await supabase
    .from("wallets")
    .select("coins")
    .eq("user_id", user.id)
    .single();

  const coins = wallet?.coins ?? 0;

  return (
    <div className="min-h-screen bg-gray-950 text-white">
      <Navbar />
      <main className="max-w-5xl mx-auto px-4 py-12">
        <h1 className="text-4xl font-bold text-center text-cyan-400 mb-2">🏁 Races</h1>
        <p className="text-center text-gray-400 mb-4">Choose a track, pick your OmniDex frame, and race for glory</p>
        <p className="text-center text-yellow-400 mb-10">Balance: 🪙 {coins.toLocaleString()}</p>

        <div className="mb-8">
          <h2 className="text-xl font-bold text-gray-300 mb-4">
            OmniDex Frames ({FRAMES.length}/20)
          </h2>
          <div className="flex flex-wrap gap-3">
            {FRAMES.map(f => (
              <div key={f.id} className="bg-gray-800 border border-gray-600 rounded-xl px-4 py-2 text-sm">
                <span className="text-white font-semibold">{f.name}</span>
                <span className="text-cyan-400 ml-2">SPD {f.spd}</span>
              </div>
            ))}
          </div>
        </div>

        <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
          {TRACKS.map(track => (
            <div key={track.id} className="bg-gray-800 border border-gray-700 rounded-2xl p-6 hover:border-cyan-500/50 transition-all">
              <div className="flex items-center gap-3 mb-3">
                <span className="text-4xl">{track.emoji}</span>
                <div>
                  <h2 className="text-xl font-bold text-white">{track.name}</h2>
                  <p className="text-sm text-gray-400">{track.district}</p>
                </div>
              </div>

              <div className="flex gap-3 flex-wrap mb-4">
                <span className={`text-xs px-2 py-1 rounded-full font-semibold ${DIFF_COLORS[track.difficulty]}`}>
                  {track.difficulty}
                </span>
                <span className="text-xs bg-gray-700 text-gray-300 px-2 py-1 rounded-full">
                  {track.laps} lap{track.laps > 1 ? "s" : ""}
                </span>
              </div>

              <div className="flex items-center justify-between">
                <p className="text-yellow-400 font-semibold">Entry: 🪙 {track.entry_fee}</p>
                <div className="text-xs text-gray-500">
                  <p>1st: 3× bet</p>
                  <p>2nd: 1.5×</p>
                </div>
              </div>

              <div className="mt-4 text-center">
                <p className="text-gray-500 text-xs">Race via the Godot MMO client</p>
                <p className="text-gray-600 text-xs">or from the Neon Alley district</p>
              </div>
            </div>
          ))}
        </div>

        <div className="mt-12 bg-gray-800/50 rounded-xl p-6">
          <h2 className="text-xl font-bold text-yellow-300 mb-4">🏆 Race Payouts</h2>
          <div className="grid grid-cols-3 gap-4 text-center text-sm">
            <div className="bg-yellow-500/10 rounded-lg p-4">
              <p className="text-2xl mb-1">🥇</p>
              <p className="font-bold text-yellow-400">1st Place</p>
              <p className="text-gray-400">3× bet</p>
            </div>
            <div className="bg-gray-500/10 rounded-lg p-4">
              <p className="text-2xl mb-1">🥈</p>
              <p className="font-bold text-gray-300">2nd Place</p>
              <p className="text-gray-400">1.5× bet</p>
            </div>
            <div className="bg-orange-500/10 rounded-lg p-4">
              <p className="text-2xl mb-1">🥉</p>
              <p className="font-bold text-orange-400">3rd Place</p>
              <p className="text-gray-400">No payout</p>
            </div>
          </div>
        </div>
      </main>
    </div>
  );
}
