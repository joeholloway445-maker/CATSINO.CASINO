import { createClient } from "@/lib/supabase/server";
import { redirect } from "next/navigation";
import Navbar from "@/components/Navbar";

export default async function TournamentsPage() {
  const supabase = await createClient();
  const { data: { user } } = await supabase.auth.getUser();
  if (!user) redirect("/login");

  const { data: tournaments } = await supabase
    .from("tournaments")
    .select("*")
    .order("starts_at", { ascending: false })
    .limit(10);

  const { data: myEntries } = await supabase
    .from("tournament_entries")
    .select("tournament_id, score, rank")
    .eq("user_id", user.id);

  const myTournamentIds = new Set(myEntries?.map(e => e.tournament_id) ?? []);

  const STATUS_COLORS: Record<string, string> = {
    active: "text-green-400 bg-green-400/10",
    upcoming: "text-blue-400 bg-blue-400/10",
    ended: "text-gray-400 bg-gray-400/10",
  };

  return (
    <div className="min-h-screen bg-gray-950 text-white">
      <Navbar />
      <main className="max-w-4xl mx-auto px-4 py-12">
        <h1 className="text-4xl font-bold text-center text-orange-400 mb-2">🏆 Tournaments</h1>
        <p className="text-center text-gray-400 mb-10">Compete for Cat Chip prizes and exclusive titles</p>

        {(!tournaments || tournaments.length === 0) ? (
          <div className="text-center py-20">
            <div className="text-6xl mb-4">🏆</div>
            <p className="text-gray-400 text-xl">No tournaments running yet.</p>
            <p className="text-gray-500 mt-2">Check back soon — weekly tournaments start every Monday!</p>
          </div>
        ) : (
          <div className="space-y-4">
            {tournaments.map((t) => {
              const status = new Date(t.ends_at) < new Date() ? "ended"
                : new Date(t.starts_at) > new Date() ? "upcoming" : "active";
              const isEntered = myTournamentIds.has(t.id);
              const myEntry = myEntries?.find(e => e.tournament_id === t.id);

              return (
                <div key={t.id} className="bg-gray-800 border border-gray-700 rounded-xl p-6 hover:border-orange-500/40 transition-all">
                  <div className="flex items-start justify-between mb-3">
                    <div>
                      <h2 className="text-xl font-bold text-white">{t.name}</h2>
                      <p className="text-gray-400 text-sm">{t.game_type ?? "All Games"}</p>
                    </div>
                    <span className={`text-xs font-semibold px-3 py-1 rounded-full ${STATUS_COLORS[status]}`}>
                      {status.toUpperCase()}
                    </span>
                  </div>

                  <div className="grid grid-cols-3 gap-4 mb-4">
                    <div className="text-center">
                      <p className="text-2xl font-bold text-yellow-400">💰 {t.prize_pool?.toLocaleString() ?? 0}</p>
                      <p className="text-xs text-gray-500">Prize Pool</p>
                    </div>
                    <div className="text-center">
                      <p className="text-2xl font-bold text-cyan-400">{t.entry_count ?? 0}</p>
                      <p className="text-xs text-gray-500">Participants</p>
                    </div>
                    <div className="text-center">
                      <p className="text-2xl font-bold text-purple-400">#{myEntry?.rank ?? "—"}</p>
                      <p className="text-xs text-gray-500">Your Rank</p>
                    </div>
                  </div>

                  {isEntered && myEntry && (
                    <div className="bg-orange-500/10 border border-orange-500/30 rounded-lg p-3 mb-3 text-sm text-orange-300">
                      You&apos;re entered! Score: {myEntry.score ?? 0} pts
                    </div>
                  )}

                  <div className="flex gap-2">
                    {status === "active" && !isEntered && (
                      <button className="flex-1 bg-orange-500 hover:bg-orange-400 text-black font-bold py-2 px-4 rounded-lg text-sm transition-all">
                        Enter Tournament ({t.entry_fee ?? 0} coins)
                      </button>
                    )}
                    <button className="flex-1 bg-gray-700 hover:bg-gray-600 text-white font-semibold py-2 px-4 rounded-lg text-sm transition-all">
                      View Leaderboard
                    </button>
                  </div>
                </div>
              );
            })}
          </div>
        )}

        <div className="mt-12 bg-gray-800/50 rounded-xl p-6">
          <h2 className="text-xl font-bold text-yellow-300 mb-4">🏅 Prize Distribution</h2>
          <div className="grid grid-cols-3 gap-4 text-center text-sm">
            <div className="bg-yellow-500/10 rounded-lg p-4">
              <p className="text-2xl mb-1">🥇</p>
              <p className="font-bold text-yellow-400">1st Place</p>
              <p className="text-gray-400">50% of pool</p>
            </div>
            <div className="bg-gray-500/10 rounded-lg p-4">
              <p className="text-2xl mb-1">🥈</p>
              <p className="font-bold text-gray-300">2nd Place</p>
              <p className="text-gray-400">30% of pool</p>
            </div>
            <div className="bg-orange-500/10 rounded-lg p-4">
              <p className="text-2xl mb-1">🥉</p>
              <p className="font-bold text-orange-400">3rd Place</p>
              <p className="text-gray-400">20% of pool</p>
            </div>
          </div>
        </div>
      </main>
    </div>
  );
}
