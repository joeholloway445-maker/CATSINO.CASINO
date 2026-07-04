import type { Metadata } from 'next'
import { Geist_Mono } from 'next/font/google'
import HopeCompanion from '@/components/HopeCompanion'
import PostHogProvider from '@/components/PostHogProvider'
import './globals.css'

const geistMono = Geist_Mono({
  variable: '--font-geist-mono',
  subsets: ['latin'],
})

export const metadata: Metadata = {
  title: 'THE HDV CORE',
  description: 'Hope · Dream · Vision — Multi-mode game powered by the HOPE Authority Layer',
}

export default function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode
}>) {
  return (
    <html lang="en" className={`${geistMono.variable} h-full`}>
      <body className="h-full bg-[#0f0f1a] text-slate-200 antialiased">
        <PostHogProvider>{children}</PostHogProvider>
        <HopeCompanion />
      </body>
    </html>
  )
}
