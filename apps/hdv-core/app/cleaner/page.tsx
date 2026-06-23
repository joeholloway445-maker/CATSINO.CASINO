import Link from 'next/link'
import DriveCleaner from '@/components/cleaner/DriveCleaner'

export default function CleanerPage() {
  return (
    <main className="min-h-screen px-6 py-16 max-w-2xl mx-auto">
      <Link href="/" className="font-mono text-xs text-purple-400 hover:text-purple-300">
        ← back to core
      </Link>

      <div className="text-purple-500 text-3xl mt-6 mb-2 tracking-widest font-mono">✦ HOPE CLEANER ✦</div>
      <h1 className="text-2xl font-mono font-bold text-slate-100 mb-2">V1 — Drive Cleanup Toolkit</h1>
      <p className="text-slate-400 font-mono text-sm mb-8 leading-relaxed">
        Connect your Google Drive and run a one-time scan. Use the settings &amp; functions menu to
        toggle modules and tune thresholds: find recurring files/folders created over and over by a
        forgotten automation, large files eating up storage, and stale files you haven&apos;t touched
        in a long time. Dry run is on by default — review before anything moves to trash.
      </p>

      <DriveCleaner />

      <div className="mt-12 font-mono text-xs text-slate-600 leading-relaxed">
        <p className="text-slate-500 font-bold mb-1">ROADMAP</p>
        <p>V1 — Drive cleanup toolkit: duplicates, large files, stale files (this)</p>
        <p>V2 — Apps Script trigger audit (find &amp; disable runaway scripts)</p>
        <p>V3 — AI chat history consolidation across apps</p>
        <p>V4 — Background activity tracker (desktop + mobile)</p>
      </div>
      <div className="mt-6 font-mono text-xs text-slate-600 leading-relaxed">
        <p className="text-slate-500 font-bold mb-1">PART OF HOPE STUDIO</p>
        <p>HOPE Cleaner is a standalone module that will fold into the upcoming HOPE Studio app
          alongside the other HOPE tools.</p>
      </div>
    </main>
  )
}
