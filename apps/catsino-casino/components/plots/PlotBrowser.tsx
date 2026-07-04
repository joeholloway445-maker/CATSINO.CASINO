"use client";

import { useEffect, useState } from "react";

interface Choice {
  id: string;
  choice_key: string;
  label: string;
  description: string | null;
}

interface Wager {
  arc_id: string;
  choice_id: string;
  currency: "chip" | "renown";
  amount: number;
  payout: number | null;
}

interface Arc {
  id: string;
  slug: string;
  title: string;
  description: string;
  status: "voting" | "resolved";
  closes_at: string | null;
  resolved_at: string | null;
  winning_choice_id: string | null;
  choices: Choice[];
  tally: {
    byChoice: Record<string, Record<string, number>>;
    byFaction: Record<string, Record<string, number>>;
  };
  myWagers: Wager[];
}

export default function PlotBrowser() {
  const [arcs, setArcs] = useState<Arc[]>([]);
  const [loading, setLoading] = useState(true);
  const [amounts, setAmounts] = useState<Record<string, number>>({});
  const [pending, setPending] = useState<string | null>(null);
  const [error, setError] = useState("");
  const [notice, setNotice] = useState("");

  const load = async () => {
    const res = await fetch("/api/story/arcs");
    const data = await res.json();
    if (data.arcs) setArcs(data.arcs);
    setLoading(false);
  };

  useEffect(() => {
    load();
  }, []);

  const wager = async (arcId: string, choiceId: string) => {
    const amount = amounts[choiceId] || 100;
    setPending(choiceId);
    setError("");
    setNotice("");
    try {
      const res = await fetch("/api/story/wager", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ arcId, choiceId, amount, currency: "chip" }),
      });
      const data = await res.json();
      if (data.error) {
        setError(data.error);
        return;
      }
      if (data.fellBackToRenown) {
        setNotice("Out of Cat Chips — wagered Renown instead.");
      }
      await load();
    } catch {
      setError("Network error");
    } finally {
      setPending(null);
    }
  };

  if (loading) {
    return <p className="text-center text-gray-500">Loading the Conclave's plots…</p>;
  }

  if (arcs.length === 0) {
    return <p className="text-center text-gray-500">No plots are up for a vote right now.</p>;
  }

  return (
    <div className="space-y-8">
      {error && <p className="text-center text-red-400 text-sm">{error}</p>}
      {notice && <p className="text-center text-yellow-400 text-sm">{notice}</p>}

      {arcs.map((arc) => {
        const factionRows = Object.entries(arc.tally.byFaction);
        return (
          <div key={arc.id} className="rounded-2xl bg-gray-800/60 border border-purple-900/50 p-6">
            <div className="flex items-center justify-between mb-1">
              <h2 className="text-xl font-bold text-purple-300">{arc.title}</h2>
              <span
                className={`text-xs font-bold px-2 py-0.5 rounded ${
                  arc.status === "voting" ? "bg-green-900/50 text-green-300" : "bg-gray-700 text-gray-400"
                }`}
              >
                {arc.status === "voting" ? "VOTING OPEN" : "RESOLVED"}
              </span>
            </div>
            <p className="text-sm text-gray-400 mb-4">{arc.description}</p>

            <div className="grid sm:grid-cols-3 gap-3">
              {arc.choices.map((choice) => {
                const totals = arc.tally.byChoice[choice.id] ?? {};
                const totalWeight = (totals.chip ?? 0) + (totals.renown ?? 0);
                const isWinner = arc.winning_choice_id === choice.id;
                const myStake = arc.myWagers.filter((w) => w.choice_id === choice.id);
                return (
                  <div
                    key={choice.id}
                    className={`rounded-xl border p-3 ${
                      isWinner ? "border-yellow-500 bg-yellow-900/10" : "border-gray-700 bg-gray-900/40"
                    }`}
                  >
                    <p className="font-semibold text-sm text-white">
                      {choice.label} {isWinner && "🐾"}
                    </p>
                    {choice.description && <p className="text-xs text-gray-500 mt-1">{choice.description}</p>}
                    <p className="text-xs text-purple-400 mt-2">
                      {totals.chip ?? 0} chips · {totals.renown ?? 0} renown · weight {totalWeight}
                    </p>
                    {myStake.length > 0 && (
                      <p className="text-xs text-cyan-400 mt-1">
                        Your stake: {myStake.reduce((s, w) => s + w.amount, 0)} {myStake[0].currency}
                        {myStake.some((w) => w.payout != null) &&
                          ` (payout: ${myStake.reduce((s, w) => s + (w.payout ?? 0), 0)})`}
                      </p>
                    )}

                    {arc.status === "voting" && (
                      <div className="flex items-center gap-2 mt-3">
                        <input
                          type="number"
                          min={1}
                          placeholder="100"
                          className="w-20 bg-gray-700 text-white text-xs rounded px-2 py-1 border border-gray-600"
                          onChange={(e) =>
                            setAmounts((prev) => ({ ...prev, [choice.id]: Number(e.target.value) }))
                          }
                        />
                        <button
                          disabled={pending === choice.id}
                          onClick={() => wager(arc.id, choice.id)}
                          className="bg-purple-700 hover:bg-purple-600 disabled:opacity-50 text-white text-xs font-bold px-3 py-1 rounded"
                        >
                          Invest
                        </button>
                      </div>
                    )}
                  </div>
                );
              })}
            </div>

            {factionRows.length > 0 && (
              <div className="mt-4 text-xs text-gray-500">
                <span className="text-gray-400 font-semibold">Faction investment: </span>
                {factionRows
                  .map(([faction, cur]) => `${faction} (${(cur.chip ?? 0) + (cur.renown ?? 0)})`)
                  .join(" · ")}
              </div>
            )}
          </div>
        );
      })}
    </div>
  );
}
