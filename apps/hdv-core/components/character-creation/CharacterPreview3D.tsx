'use client'

import dynamic from 'next/dynamic'
import type { Race, Frame, PhysicalMod } from '@/types/character'

const CharacterPreview3DCanvas = dynamic(() => import('./CharacterPreview3DCanvas'), {
  ssr: false,
  loading: () => (
    <div className="w-full h-full flex items-center justify-center">
      <span className="font-mono text-purple-500 text-xs animate-pulse tracking-widest">
        LOADING FORM...
      </span>
    </div>
  ),
})

interface Props {
  race: Race | null
  frame: Frame | null
  mod: PhysicalMod | null
}

export default function CharacterPreview3D({ race, frame, mod }: Props) {
  return (
    <div className="rounded-xl border border-purple-900 bg-[#0f0f1a] h-64 sm:h-80 overflow-hidden">
      <CharacterPreview3DCanvas race={race} frame={frame} mod={mod} />
    </div>
  )
}
