import { createClient } from "@/lib/supabase/server";
import { redirect } from "next/navigation";
import Navbar from "@/components/Navbar";

const DAILY_REWARDS = [
  { day: 1, coins: 100, label: "Day 1" },
  { day: 2, coins: 150, label: "Day 2" },
  { day: 3, coins: 200, label: "Day 3" },
  { day: 4, coins: 300, label: "Day 4" },
  { day: 5, coins: 400, label: "Day 5" },
  { day: 6, coins: 500, label: "Day 6" },
  { day: 7, coins: 1000, label: "Day 7 ⭐", special: true },
  { day: 8, coins: 200, label: "Day 8" },
  { day: 9, coins: 250, label: "Day 9" },
  { day: 10, coins: 350, label: "Day 10" },
  { day: 11, coins: 500, label: "Day 11" },
  { day: 12, coins: 600, label: "Day 12" },
  { day: 13, coins: 750, label: "Day 13" },
  { day: 14, coins: 2000, label: "Day 14 👑", special: true },
];

export default async function DailyRewardPage() {
  const supabase = await createClient();
  const { data: { user } } = await supabase.auth.getUser();
  if (!user) redirect("/login");

  const { data: profile } = await supabase
    .from("profiles")
    .select("daily_streak, last_daily_claim")
    .eq("id", user.id)
    .single();

  const streak = profile?.daily_streak ?? 0;
  const lastClaim = profile?.last_daily_claim ? new Date(profile.last_daily_claim) : null;
  const now = new Date();
  const canClaim = !lastClaim || (now.getTime() - lastClaim.getTime()) >= 24 * 3600 * 1000;
  const todayDay = ((streak) % 14) + 1;
  const todayReward = DAILY_REWARDS.find(r => r.day === todayDay) ?? DAILY_REWARDS[0];

  return (
    <div className="min-h-screen bg-gray-950 text-white">
      <Navbar />
      <main className="max-w-3xl mx-auto px-4 py-12">
        <h1 className="text-4xl font-bold text-center text-yellow-400 mb-2">🎁 Daily Rewards</h1>
        <p className="text-center text-gray-400 mb-4">Log in every day to earn increasing rewards!</p>

        <div className="text-center mb-8">
          <div className="text-6xl font-bold text-orange-400">{streak}</div>
          <p className="text-gray-400">Day Streak</p>
        </div>

        {canClaim ? (
          <div className="text-center mb-8">
            <div className="bg-yellow-500/20 border-2 border-yellow-400 rounded-2xl p-8 mb-4 inline-block">
              <p className="text-2xl font-bold text-yellow-300 mb-2">Today&apos;s Reward</p>
              <p className="text-5xl font-bold text-white">+{todayReward.coins.toLocaleString()}</p>
              <p className="text-yellow-400">Cat Coins</p>
            </div>
            <br />
            <form action="/api/daily-bonus" method="POST">
              <button
                type="submit"
                className="bg-yellow-500 hover:bg-yellow-400 text-black font-bold py-4 px-12 rounded-xl text-xl transition-all hover:scale-105"
              >
                Claim Reward!
              </button>
            </form>
          </div>
        ) : (
          <div className="text-center mb-8">
            <div className="bg-gray-700/50 border border-gray-600 rounded-2xl p-6 inline-block">
              <p className="text-gray-400 text-lg">Already claimed today!</p>
              <p className="text-gray-500 text-sm mt-2">Come back tomorrow for Day {((streak) % 14) + 2}</p>
            </div>
          </div>
        )}

        <div className="grid grid-cols-7 gap-2">
          {DAILY_REWARDS.map((reward) => {
            const isClaimed = streak >= reward.day;
            const isToday = reward.day === todayDay && canClaim;
            return (
              <div
                key={reward.day}
                className={`rounded-xl p-2 text-center text-xs border-2 transition-all ${
                  isClaimed
                    ? "bg-green-500/20 border-green-500/40 opacity-70"
                    : isToday
                    ? "bg-yellow-500/20 border-yellow-400 scale-105"
                    : reward.special
                    ? "bg-purple-500/10 border-purple-500/30"
                    : "bg-gray-800 border-gray-700"
                }`}
              >
                <p className="font-bold text-gray-300">{reward.label}</p>
                <p className={`font-bold ${reward.special ? "text-purple-300" : "text-yellow-400"}`}>
                  {reward.coins >= 1000 ? `${reward.coins / 1000}k` : reward.coins}
                </p>
                {isClaimed && <p className="text-green-400">✓</p>}
                {isToday && <p className="text-yellow-400">▶</p>}
              </div>
            );
          })}
        </div>
      </main>
    </div>
  );
}
