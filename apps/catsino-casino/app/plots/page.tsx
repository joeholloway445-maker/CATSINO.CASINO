import { createClient } from "@/lib/supabase/server";
import { redirect } from "next/navigation";
import Navbar from "@/components/Navbar";
import PlotBrowser from "@/components/plots/PlotBrowser";

export default async function PlotsPage() {
  const supabase = await createClient();
  const { data: { user } } = await supabase.auth.getUser();
  if (!user) redirect("/login");

  return (
    <div className="min-h-screen bg-gray-950 text-white">
      <Navbar />
      <main className="max-w-5xl mx-auto px-4 py-12">
        <h1 className="text-4xl font-bold text-center text-purple-400 mb-2">🐾 The Cat Conclave</h1>
        <p className="text-center text-gray-400 mb-8">
          Wager Cat Chips (or Renown, if you&apos;re out of chips) to steer the realm&apos;s overarching plots
        </p>
        <PlotBrowser />
      </main>
    </div>
  );
}
