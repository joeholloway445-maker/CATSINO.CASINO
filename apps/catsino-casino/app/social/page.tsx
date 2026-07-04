import { redirect } from "next/navigation";
import { createClient } from "@/lib/supabase/server";
import SocialClient from "./SocialClient";

export default async function SocialPage() {
  const supabase = await createClient();
  const { data: { user } } = await supabase.auth.getUser();
  if (!user) redirect("/login");

  const { data: profile } = await supabase
    .from("profiles")
    .select("username, level, avatar_url")
    .eq("id", user.id)
    .single();

  const { data: leaderboard } = await supabase
    .from("profiles")
    .select("username, level, total_winnings")
    .order("total_winnings", { ascending: false })
    .limit(10);

  return (
    <SocialClient
      username={profile?.username ?? "Cat"}
      level={profile?.level ?? 1}
      leaderboard={leaderboard ?? []}
    />
  );
}
