'use client'

import dynamic from 'next/dynamic'

const ExtraliminalCanvas = dynamic(() => import('./ExtraliminalCanvas'), {
  ssr: false,
  loading: () => (
    <div className="w-full h-screen flex items-center justify-center bg-[#0f0f1a]">
      <div className="text-center">
        <div className="text-purple-500 text-3xl mb-4 animate-pulse">✦</div>
        <div className="font-mono text-xs text-purple-600 tracking-widest animate-pulse">
          ENTERING THE SPACE...
        </div>
      </div>
    </div>
  ),
})

interface PlayerData {
  faction: string
  race: string
  frame: string
  prestige: number
  currencies: Record<string, number>
}

export default function ExtraliminalGameLoader({ playerData }: { playerData: PlayerData }) {
  return <ExtraliminalCanvas playerData={playerData} />
}
