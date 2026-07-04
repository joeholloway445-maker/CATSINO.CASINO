'use client'

import { useEffect, useRef } from 'react'
import { useRouter } from 'next/navigation'
import HopeCompanion from '@/components/HopeCompanion'

interface PlayerData {
  faction: string
  race: string
  frame: string
  prestige: number
  currencies: Record<string, number>
}

export default function ExtraliminalCanvas({ playerData }: { playerData: PlayerData }) {
  const containerRef = useRef<HTMLDivElement>(null)
  const router = useRouter()

  useEffect(() => {
    if (!containerRef.current) return

    let game: import('phaser').Game | null = null

    Promise.all([
      import('phaser'),
      import('@/lib/game/scenes/ExtraliminalScene'),
    ]).then(([Phaser, { ExtraliminalScene }]) => {
      if (!containerRef.current) return

      const scene = new ExtraliminalScene()

      game = new Phaser.Game({
        type: Phaser.AUTO,
        parent: containerRef.current,
        width: window.innerWidth,
        height: window.innerHeight,
        backgroundColor: '#0f0f1a',
        scene: [scene],
        scale: {
          mode: Phaser.Scale.RESIZE,
          autoCenter: Phaser.Scale.CENTER_BOTH,
        },
        physics: {
          default: 'arcade',
          arcade: { debug: false },
        },
      })

      // Pass player data via the scene's init
      game.scene.start('ExtraliminalScene', playerData)

      // Poll registry for navigation signals
      const navInterval = setInterval(() => {
        const navigateTo = game?.registry.get('navigateTo')
        if (navigateTo) {
          router.push(navigateTo)
          clearInterval(navInterval)
        }
      }, 500)

      return () => clearInterval(navInterval)
    })

    return () => {
      game?.destroy(true)
    }
  }, [])

  return (
    <>
      <div ref={containerRef} className="w-full h-full" />
      <HopeCompanion
        playerContext={{
          faction: playerData.faction,
          race: playerData.race,
          frame: playerData.frame,
          prestige: String(playerData.prestige),
          currentSpace: 'extraliminal game',
        }}
      />
    </>
  )
}
