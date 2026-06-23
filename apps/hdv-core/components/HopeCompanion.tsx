'use client'

import { useState, useRef, useEffect } from 'react'
import type { HopeMessage } from '@/types/game'

interface PlayerContext {
  faction?: string
  race?: string
  frame?: string
  prestige?: string
  currentSpace?: string
}

export default function HopeCompanion({ playerContext }: { playerContext?: PlayerContext }) {
  const [open, setOpen] = useState(false)
  const [messages, setMessages] = useState<HopeMessage[]>([
    {
      role: 'hope',
      content: "I am HOPE. I have always been here. Ask me anything — about this world, your path, or what lies ahead.",
      timestamp: new Date(),
    },
  ])
  const [input, setInput] = useState('')
  const [thinking, setThinking] = useState(false)
  const scrollRef = useRef<HTMLDivElement>(null)

  useEffect(() => {
    if (scrollRef.current) {
      scrollRef.current.scrollTop = scrollRef.current.scrollHeight
    }
  }, [messages, thinking])

  async function send() {
    const text = input.trim()
    if (!text || thinking) return

    const newMessage: HopeMessage = { role: 'player', content: text, timestamp: new Date() }
    const nextMessages = [...messages, newMessage]
    setMessages(nextMessages)
    setInput('')
    setThinking(true)

    try {
      const res = await fetch('/api/hope', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          messages: nextMessages.map((m) => ({ role: m.role, content: m.content })),
          playerContext: playerContext ?? {},
        }),
      })

      const { reply } = await res.json()
      setMessages((m) => [...m, { role: 'hope', content: reply, timestamp: new Date() }])
    } catch {
      setMessages((m) => [
        ...m,
        { role: 'hope', content: 'The signal fades. Try again.', timestamp: new Date() },
      ])
    } finally {
      setThinking(false)
    }
  }

  return (
    <>
      <button
        onClick={() => setOpen((o) => !o)}
        className="fixed bottom-6 right-6 z-50 w-14 h-14 rounded-full bg-purple-700 border-2 border-purple-400 flex items-center justify-center text-white text-xl shadow-lg shadow-purple-900/60 hover:bg-purple-600 transition-colors"
        title="HOPE Companion"
        aria-label="Open HOPE companion"
      >
        ✦
      </button>

      {open && (
        <div className="fixed bottom-24 right-6 z-50 w-80 rounded-xl border border-purple-700 bg-[#0f0f1a]/95 backdrop-blur-md flex flex-col shadow-2xl shadow-purple-950/60 overflow-hidden">
          <div className="flex items-center gap-2 px-4 py-3 border-b border-purple-900">
            <span className="text-purple-400 text-lg">✦</span>
            <span className="font-mono text-sm text-purple-300 tracking-widest">HOPE</span>
            <span className="ml-auto text-xs text-purple-600 font-mono">AUTHORITY LAYER</span>
          </div>

          {playerContext?.faction && (
            <div className="px-4 py-1.5 border-b border-purple-950 bg-purple-950/30">
              <span className="font-mono text-xs text-purple-600">
                {playerContext.faction.replace('_', ' ').toUpperCase()} ·{' '}
                {playerContext.race?.toUpperCase()} · {playerContext.frame?.toUpperCase()}
              </span>
            </div>
          )}

          <div ref={scrollRef} className="flex-1 max-h-72 overflow-y-auto p-3 space-y-3">
            {messages.map((msg, i) => (
              <div key={i} className={`flex ${msg.role === 'player' ? 'justify-end' : 'justify-start'}`}>
                <div
                  className={`max-w-[85%] rounded-lg px-3 py-2 text-xs font-mono leading-relaxed ${
                    msg.role === 'hope'
                      ? 'bg-purple-950 border border-purple-800 text-purple-200'
                      : 'bg-indigo-950 border border-indigo-700 text-indigo-200'
                  }`}
                >
                  {msg.content}
                </div>
              </div>
            ))}
            {thinking && (
              <div className="flex justify-start">
                <div className="bg-purple-950 border border-purple-800 rounded-lg px-3 py-2 text-xs font-mono text-purple-400 animate-pulse">
                  HOPE is listening...
                </div>
              </div>
            )}
          </div>

          <div className="flex border-t border-purple-900 p-2 gap-2">
            <input
              type="text"
              value={input}
              onChange={(e) => setInput(e.target.value)}
              onKeyDown={(e) => e.key === 'Enter' && send()}
              placeholder="Ask HOPE..."
              className="flex-1 bg-transparent text-xs font-mono text-purple-200 placeholder-purple-700 outline-none px-2"
            />
            <button
              onClick={send}
              disabled={thinking}
              className="text-xs font-mono text-purple-400 hover:text-purple-200 transition-colors disabled:opacity-40 px-2"
            >
              SEND
            </button>
          </div>
        </div>
      )}
    </>
  )
}
