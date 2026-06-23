'use client'

import dynamic from 'next/dynamic'

const GameCanvas = dynamic(() => import('@/components/GameCanvas'), {
  ssr: false,
  loading: () => (
    <div className="w-full h-screen flex items-center justify-center bg-[#0f0f1a]">
      <span className="font-mono text-purple-500 text-sm animate-pulse tracking-widest">
        INITIALIZING CORE...
      </span>
    </div>
  ),
})

export default function GameLoader() {
  return <GameCanvas />
}
