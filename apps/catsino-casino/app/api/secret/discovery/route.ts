import { getAdminClient } from "@/lib/supabase/admin";
import { NextResponse } from "next/server";

// First-discovery reports for unlabeled in-game secrets (currently only the
// Recall Walk). The Godot client queues the report durably and retries until
// this returns ok, so this endpoint must accept unauthenticated posts — a
// discoverer may never have had a web session. Writes go through the
// service-role client; the table has no anon policies.
//
// Owner ping: set DISCORD_SECRET_WEBHOOK_URL (a channel webhook) in the
// Vercel env and every FIRST discovery per player lands in that channel.
// The webhook stays server-side only — it never ships in the game client.

export async function POST(req: Request) {
  let body: { player?: unknown; layer?: unknown; found_at?: unknown };
  try {
    body = await req.json();
  } catch {
    return NextResponse.json({ ok: false, error: "Bad JSON" }, { status: 400 });
  }

  const player = String(body.player ?? "").trim().slice(0, 64);
  const layer = String(body.layer ?? "unknown").trim().slice(0, 32) || "unknown";
  if (!player) {
    return NextResponse.json({ ok: false, error: "player required" }, { status: 400 });
  }
  const foundAtSec = Number(body.found_at);
  const foundAt = Number.isFinite(foundAtSec) && foundAtSec > 0
    ? new Date(foundAtSec * 1000).toISOString()
    : new Date().toISOString();

  const supabase = getAdminClient();
  const { error } = await supabase.from("secret_discoveries").insert({
    secret_id: "recall_walk",
    player_name: player,
    layer,
    found_at: foundAt,
  });

  // 23505 = unique violation: this player's discovery is already on record.
  // Still ok:true so the client clears its retry queue and stays silent.
  if (error && error.code !== "23505") {
    return NextResponse.json({ ok: false, error: error.message }, { status: 500 });
  }
  const isNew = !error;

  const hook = process.env.DISCORD_SECRET_WEBHOOK_URL;
  if (isNew && hook) {
    await fetch(hook, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({
        content: `🕯️ **Someone found the Recall Walk.** \`${player}\` walked backwards out of the **${layer}** and woke up in their Subliminal. Their recall quest chain just went live.`,
      }),
    }).catch(() => {}); // the ping is best-effort; the row is the record
  }

  return NextResponse.json({ ok: true, first: isNew });
}
