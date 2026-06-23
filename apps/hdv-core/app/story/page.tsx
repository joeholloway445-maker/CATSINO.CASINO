import Link from 'next/link'
import { createClient } from '@/lib/supabase/server'
import { redirect } from 'next/navigation'
import StoryArcBrowser from '@/components/story/StoryArcBrowser'

export default async function StoryPage() {
  const supabase = await createClient()
  const { data: { user } } = await supabase.auth.getUser()
  if (!user) redirect('/login')

  return (
    <div className="min-h-screen bg-[#0f0f1a] px-4 py-8">
      <div className="max-w-5xl mx-auto">
        <div className="flex items-center justify-between mb-6">
          <h1 className="font-mono text-xl text-purple-400 tracking-widest">OVERARCHING PLOTS</h1>
          <Link href="/character-select" className="font-mono text-xs text-purple-500 hover:text-purple-300">
            ← BACK
          </Link>
        </div>
        <StoryArcBrowser />
      </div>
    </div>
  )
}
