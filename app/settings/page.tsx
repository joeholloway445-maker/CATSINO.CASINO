import { createClient } from "@/lib/supabase/server";
import { redirect } from "next/navigation";
import Navbar from "@/components/Navbar";
import SettingsClient from "./SettingsClient";

export default async function SettingsPage() {
  const supabase = await createClient();
  const { data: { user } } = await supabase.auth.getUser();
  if (!user) redirect("/login");

  const { data: profile } = await supabase
    .from("profiles")
    .select("username, faction, is_admin")
    .eq("id", user.id)
    .single();

  return (
    <div className="min-h-screen bg-gray-950 text-white">
      <Navbar username={profile?.username ?? ""} />
      <main className="max-w-2xl mx-auto px-4 py-12">
        <h1 className="text-4xl font-bold text-center text-gray-300 mb-2">⚙️ Settings</h1>
        <p className="text-center text-gray-500 mb-10">Manage your account and preferences</p>
        <SettingsClient
          initialUsername={profile?.username ?? ""}
          email={user.email ?? ""}
          faction={profile?.faction ?? "none"}
        />
      </main>
    </div>
  );
}
