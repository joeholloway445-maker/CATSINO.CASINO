import { createClient } from "@/lib/supabase/server";
import { redirect } from "next/navigation";
import Navbar from "@/components/Navbar";
import CampaignTracker from "@/components/campaign/CampaignTracker";

export default async function CampaignPage() {
  const supabase = await createClient();
  const { data: { user } } = await supabase.auth.getUser();
  if (!user) redirect("/login");

  return (
    <div className="min-h-screen bg-gray-950 text-white">
      <Navbar />
      <main className="max-w-5xl mx-auto px-4 py-12">
        <h1 className="text-4xl font-bold text-center text-purple-400 mb-2">🐾 The Clawpaign</h1>
        <p className="text-center text-gray-400 mb-8">
          No closed zones, no queue -- the open world is the battlefield, 24/7. Every kill counts toward your
          faction&apos;s score for the current campaign.
        </p>
        <CampaignTracker />
      </main>
    </div>
  );
}
