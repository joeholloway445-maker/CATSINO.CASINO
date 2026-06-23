import { redirect } from "next/navigation";
import { createClient } from "@/lib/supabase/server";

export default async function BattlePassPage() {
  const supabase = await createClient();
  const { data: { user } } = await supabase.auth.getUser();
  if (!user) redirect("/login");

  const { data: profile } = await supabase
    .from("profiles")
    .select("username, level, total_xp")
    .eq("id", user.id)
    .single();

  const xp = profile?.total_xp ?? 0;
  const FREE_TIERS = [
    { tier: 1, xp: 0,     reward: "200 🪙" },
    { tier: 2, xp: 500,   reward: "300 🪙" },
    { tier: 3, xp: 1200,  reward: "Companion: FL001" },
    { tier: 4, xp: 2000,  reward: "500 🪙" },
    { tier: 5, xp: 3000,  reward: "Lucky Charm 🍀" },
    { tier: 6, xp: 4200,  reward: "750 🪙" },
    { tier: 7, xp: 5600,  reward: "5 💎" },
    { tier: 8, xp: 7200,  reward: "1,000 🪙" },
    { tier: 9, xp: 9000,  reward: "Companion: WA001" },
    { tier: 10, xp: 11000, reward: "Title: Season Veteran 🏆" },
  ];

  return (
    <div className="min-h-screen bg-black text-white p-6">
      <div className="max-w-3xl mx-auto">
        <h1 className="text-3xl font-bold text-yellow-400 mb-1">⚡ Season Battle Pass</h1>
        <p className="text-gray-400 mb-2">Current XP: <span className="text-white font-bold">{xp.toLocaleString()}</span></p>

        <div className="w-full bg-gray-800 rounded-full h-3 mb-6">
          <div
            className="bg-yellow-400 h-3 rounded-full transition-all"
            style={{ width: `${Math.min(100, (xp / 11000) * 100).toFixed(1)}%` }}
          />
        </div>

        <h2 className="text-xl font-bold text-white mb-3">Free Track</h2>
        <div className="grid grid-cols-2 sm:grid-cols-5 gap-3 mb-8">
          {FREE_TIERS.map((t) => {
            const unlocked = xp >= t.xp;
            return (
              <div
                key={t.tier}
                className={`rounded-lg p-3 text-center border ${
                  unlocked
                    ? "bg-yellow-900 border-yellow-500 text-yellow-200"
                    : "bg-gray-900 border-gray-700 text-gray-500"
                }`}
              >
                <div className="font-bold text-lg">T{t.tier}</div>
                <div className="text-xs mt-1">{t.reward}</div>
                <div className="text-xs text-gray-500 mt-1">{t.xp.toLocaleString()} XP</div>
                {unlocked && <div className="text-green-400 text-xs mt-1">✓ Unlocked</div>}
              </div>
            );
          })}
        </div>

        <div className="bg-purple-950 border border-purple-500 rounded-xl p-5 text-center">
          <h2 className="text-xl font-bold text-purple-300 mb-2">👑 Premium Track</h2>
          <p className="text-gray-400 text-sm mb-3">
            Premium companions, gems, and exclusive titles — available in the Godot MMO client.
          </p>
          <p className="text-purple-400 text-sm">Launch the game to activate Premium Pass.</p>
        </div>
      </div>
    </div>
  );
}
