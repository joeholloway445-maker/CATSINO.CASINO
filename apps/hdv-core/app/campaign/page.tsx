import Link from 'next/link'
import { createClient } from '@/lib/supabase/server'
import { redirect } from 'next/navigation'
import CampaignTracker from '@/components/campaign/CampaignTracker'

export default async function CampaignPage() {
  const supabase = await createClient()
  const { data: { user } } = await supabase.auth.getUser()
  if (!user) redirect('/login')

  return (
    <div className="min-h-screen bg-[#0f0f1a] px-4 py-8">
      <div className="max-w-5xl mx-auto">
        <div className="flex items-center justify-between mb-2">
          <h1 className="font-mono text-xl text-purple-400 tracking-widest">PVP CAMPAIGN</h1>
          <Link href="/character-select" className="font-mono text-xs text-purple-500 hover:text-purple-300">
            ← BACK
          </Link>
        </div>
        <p className="font-mono text-xs text-purple-600 mb-6">
          No closed zones, no queue -- the open world is the battlefield, 24/7. Every kill counts toward your
          faction&apos;s score for the current campaign.
        </p>
        <CampaignTracker />
      </div>
    </div>
  )
}
