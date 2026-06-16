import { createClient } from "@/lib/supabase/server";
import { redirect } from "next/navigation";
import Navbar from "@/components/Navbar";

const ALL_QUESTS = [
  { id: "intro_district_tour", name: "Welcome to Catsino", desc: "Visit all 5 districts", reward_coins: 500, reward_xp: 200, type: "main" },
  { id: "first_battle", name: "Arena Debut", desc: "Complete your first combat in Cat Coliseum", reward_coins: 200, reward_xp: 100, type: "main" },
  { id: "find_sovereign_crown", name: "Faction Finder", desc: "Talk to a faction representative", reward_coins: 300, reward_xp: 150, type: "side" },
  { id: "neon_alley_racer", name: "Need for Speed", desc: "Complete a race in Neon Alley", reward_coins: 400, reward_xp: 175, type: "side" },
  { id: "forest_mystery", name: "Forest Mystery", desc: "Discover the Forest Elder's secret", reward_coins: 600, reward_xp: 250, type: "main" },
  { id: "companion_collector", name: "Monster Collector", desc: "Collect 5 companions", reward_coins: 750, reward_xp: 300, type: "side" },
  { id: "faction_allegiance", name: "Choose Your Side", desc: "Join a faction", reward_coins: 1000, reward_xp: 400, type: "main" },
  { id: "help_aqua_merchant", name: "Canal Delivery", desc: "Help Aqua Merchant Teal deliver goods", reward_coins: 350, reward_xp: 150, type: "side" },
  { id: "grand_tournament", name: "Grand Tournament", desc: "Enter and complete the Grand Tournament", reward_coins: 2000, reward_xp: 800, type: "main" },
  { id: "arcade_champion", name: "Arcade Legend", desc: "Score 500 points in Cat Puzzle", reward_coins: 500, reward_xp: 200, type: "side" },
  { id: "fortune_wheel_spin", name: "Wheel of Fortune", desc: "Spin the Fortune Wheel 3 times", reward_coins: 200, reward_xp: 100, type: "daily" },
  { id: "daily_spin", name: "Daily Spinner", desc: "Play the slots once today", reward_coins: 100, reward_xp: 50, type: "daily" },
  { id: "win_3_games", name: "Hat Trick", desc: "Win 3 games in any district today", reward_coins: 300, reward_xp: 150, type: "daily" },
  { id: "race_champion", name: "Race Champion", desc: "Win first place in 3 races", reward_coins: 800, reward_xp: 350, type: "side" },
  { id: "big_spender", name: "High Roller", desc: "Wager 10,000 coins total", reward_coins: 1500, reward_xp: 500, type: "side" },
];

const TYPE_CONFIG: Record<string, { label: string; color: string; bg: string }> = {
  main: { label: "Main", color: "text-yellow-400", bg: "bg-yellow-500/10 border-yellow-500/30" },
  side: { label: "Side", color: "text-blue-400", bg: "bg-blue-500/10 border-blue-500/30" },
  daily: { label: "Daily", color: "text-green-400", bg: "bg-green-500/10 border-green-500/30" },
};

export default async function QuestsPage() {
  const supabase = await createClient();
  const { data: { user } } = await supabase.auth.getUser();
  if (!user) redirect("/login");

  const { data: progress } = await supabase
    .from("quest_progress")
    .select("quest_id, status, progress")
    .eq("user_id", user.id);

  const progressMap: Record<string, { status: string; progress: number }> = {};
  for (const p of progress ?? []) {
    progressMap[p.quest_id] = { status: p.status, progress: p.progress ?? 0 };
  }

  const mainQuests = ALL_QUESTS.filter(q => q.type === "main");
  const sideQuests = ALL_QUESTS.filter(q => q.type === "side");
  const dailyQuests = ALL_QUESTS.filter(q => q.type === "daily");

  const QuestCard = ({ quest }: { quest: typeof ALL_QUESTS[0] }) => {
    const p = progressMap[quest.id];
    const status = p?.status ?? "locked";
    const cfg = TYPE_CONFIG[quest.type];
    return (
      <div className={`border rounded-xl p-4 ${status === "complete" ? "opacity-60 border-gray-600" : `${cfg.bg} border`}`}>
        <div className="flex items-start justify-between mb-2">
          <h3 className="font-bold text-white">{quest.name}</h3>
          <div className="flex items-center gap-2">
            <span className={`text-xs font-semibold px-2 py-0.5 rounded-full ${cfg.color} bg-black/20`}>
              {cfg.label}
            </span>
            {status === "complete" && <span className="text-green-400 text-sm">✓</span>}
            {status === "active" && <span className="text-yellow-400 text-sm">▶</span>}
          </div>
        </div>
        <p className="text-sm text-gray-400 mb-3">{quest.desc}</p>
        <div className="flex items-center justify-between text-xs">
          <div className="flex gap-3">
            <span className="text-yellow-400">💰 {quest.reward_coins}</span>
            <span className="text-purple-400">⭐ {quest.reward_xp} XP</span>
          </div>
          {status === "active" && (
            <span className="text-cyan-400">In Progress</span>
          )}
          {status === "locked" && (
            <span className="text-gray-500">Not Started</span>
          )}
        </div>
      </div>
    );
  };

  return (
    <div className="min-h-screen bg-gray-950 text-white">
      <Navbar />
      <main className="max-w-4xl mx-auto px-4 py-12">
        <h1 className="text-4xl font-bold text-center text-purple-400 mb-2">📋 Quests</h1>
        <p className="text-center text-gray-400 mb-10">Complete quests to earn Cat Coins and XP</p>

        <div className="grid grid-cols-3 gap-4 mb-10">
          {[
            { label: "Completed", value: Object.values(progressMap).filter(p => p.status === "complete").length, color: "text-green-400" },
            { label: "In Progress", value: Object.values(progressMap).filter(p => p.status === "active").length, color: "text-yellow-400" },
            { label: "Available", value: ALL_QUESTS.length, color: "text-blue-400" },
          ].map(stat => (
            <div key={stat.label} className="bg-gray-800 rounded-xl p-4 text-center">
              <p className={`text-3xl font-bold ${stat.color}`}>{stat.value}</p>
              <p className="text-gray-400 text-sm mt-1">{stat.label}</p>
            </div>
          ))}
        </div>

        <section className="mb-8">
          <h2 className="text-xl font-bold text-yellow-400 mb-4">⭐ Main Quests</h2>
          <div className="space-y-3">
            {mainQuests.map(q => <QuestCard key={q.id} quest={q} />)}
          </div>
        </section>

        <section className="mb-8">
          <h2 className="text-xl font-bold text-green-400 mb-4">📅 Daily Quests</h2>
          <div className="space-y-3">
            {dailyQuests.map(q => <QuestCard key={q.id} quest={q} />)}
          </div>
        </section>

        <section>
          <h2 className="text-xl font-bold text-blue-400 mb-4">🗺️ Side Quests</h2>
          <div className="space-y-3">
            {sideQuests.map(q => <QuestCard key={q.id} quest={q} />)}
          </div>
        </section>
      </main>
    </div>
  );
}
