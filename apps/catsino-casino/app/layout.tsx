import type { Metadata } from 'next'
import { Orbitron, Space_Mono } from 'next/font/google'
import './globals.css'

const orbitron = Orbitron({
  variable: '--font-display',
  subsets: ['latin'],
  weight: ['400', '700', '900'],
})

const spaceMono = Space_Mono({
  variable: '--font-mono',
  subsets: ['latin'],
  weight: ['400', '700'],
})

export const metadata: Metadata = {
  title: 'CATSINO.CASINO — Neon Cat Social Casino',
  description:
    'A free-to-play, cat-themed social casino. Spin Purr Play Slots and more with Cat Chips. No real-money gambling, ever.',
}

export default function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode
}>) {
  return (
    <html lang="en" className={`${orbitron.variable} ${spaceMono.variable} h-full`}>
      <body className="h-full font-mono antialiased">{children}</body>
    </html>
  )
}
