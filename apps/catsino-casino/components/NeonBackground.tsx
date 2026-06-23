'use client'

import { motion } from 'framer-motion'

const ORBS = [
  { color: 'rgba(176,38,255,0.35)', size: 360, top: '-10%', left: '5%', duration: 18 },
  { color: 'rgba(0,246,255,0.3)', size: 300, top: '20%', left: '70%', duration: 22 },
  { color: 'rgba(255,43,214,0.28)', size: 280, top: '60%', left: '15%', duration: 26 },
  { color: 'rgba(57,255,136,0.22)', size: 240, top: '70%', left: '75%', duration: 20 },
]

export default function NeonBackground() {
  return (
    <div className="absolute inset-0 overflow-hidden pointer-events-none -z-10">
      {ORBS.map((orb, i) => (
        <motion.div
          key={i}
          className="absolute rounded-full blur-3xl"
          style={{
            width: orb.size,
            height: orb.size,
            top: orb.top,
            left: orb.left,
            background: orb.color,
          }}
          animate={{
            x: [0, 40, -20, 0],
            y: [0, -30, 20, 0],
            scale: [1, 1.1, 0.95, 1],
          }}
          transition={{ repeat: Infinity, duration: orb.duration, ease: 'easeInOut' }}
        />
      ))}
    </div>
  )
}
