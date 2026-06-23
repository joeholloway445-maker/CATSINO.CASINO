import { createClient } from "@/lib/supabase/server";
import { redirect } from "next/navigation";
import Navbar from "@/components/Navbar";

export default async function EventsPage() {
  const supabase = await createClient();
  const { data: { user } } = await supabase.auth.getUser();
  if (!user) redirect("/login");

  const { data: events } = await supabase
    .from("active_events")
    .select("*")
    .gte("ends_at", new Date().toISOString())
    .order("ends_at", { ascending: true });

  return (
    <div className="min-h-screen bg-gray-950 text-white">
      <Navbar />
      <main className="max-w-4xl mx-auto px-4 py-12">
        <h1 className="text-4xl font-bold text-center text-yellow-400 mb-2">🎪 Live Events</h1>
        <p className="text-center text-gray-400 mb-10">Limited-time bonuses active right now</p>

        {(!events || events.length === 0) ? (
          <div className="text-center py-20">
            <div className="text-6xl mb-4">😴</div>
            <p className="text-gray-400 text-xl">No events active right now.</p>
            <p className="text-gray-500 mt-2">Check back soon — events rotate regularly!</p>
          </div>
        ) : (
          <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
            {events.map((event) => {
              const endsAt = new Date(event.ends_at);
              const hoursLeft = Math.max(0, Math.floor((endsAt.getTime() - Date.now()) / 3600000));
              const minutesLeft = Math.max(0, Math.floor((endsAt.getTime() - Date.now()) / 60000) % 60);
              const eventIcons: Record<string, string> = {
                jackpot_hour: "🎰",
                double_xp: "⭐",
                faction_war: "⚔️",
                lucky_weekend: "🍀",
                race_championship: "🏁",
                companion_festival: "🐾",
                high_roller: "💎",
              };
              const icon = eventIcons[event.event_id] ?? "🎪";

              return (
                <div key={event.id} className="bg-gray-800 border border-yellow-500/30 rounded-xl p-6 hover:border-yellow-400/60 transition-all">
                  <div className="flex items-center gap-3 mb-3">
                    <span className="text-4xl">{icon}</span>
                    <div>
                      <h2 className="text-xl font-bold text-yellow-300">{event.name}</h2>
                      {event.multiplier > 1 && (
                        <span className="text-xs bg-yellow-500/20 text-yellow-300 px-2 py-0.5 rounded-full">
                          {event.multiplier}x Multiplier
                        </span>
                      )}
                    </div>
                  </div>
                  <p className="text-gray-300 mb-4">{event.description}</p>
                  <div className="flex items-center justify-between text-sm">
                    <span className="text-gray-400">⏳ Ends in:</span>
                    <span className="text-orange-400 font-mono font-bold">
                      {hoursLeft}h {minutesLeft}m
                    </span>
                  </div>
                </div>
              );
            })}
          </div>
        )}

        <div className="mt-12 bg-gray-800/50 rounded-xl p-6">
          <h2 className="text-xl font-bold text-purple-300 mb-4">📅 Upcoming Events</h2>
          <div className="grid grid-cols-2 md:grid-cols-4 gap-3 text-sm text-gray-400">
            {["🎰 Jackpot Hour", "⭐ Double XP", "⚔️ Faction War", "🏁 Race Championship",
              "🍀 Lucky Weekend", "🐾 Companion Festival", "💎 High Roller Night", "🌟 Bonus Bonanza"
            ].map((e) => (
              <div key={e} className="bg-gray-700/50 rounded-lg p-3 text-center">{e}</div>
            ))}
          </div>
        </div>
      </main>
    </div>
  );
}
