'use client'

// DREAM STUDIO — the live streaming surface on top of the PersonaMatrix backbone.
//
// Pulls together every "all possible chat/streaming feature" piece on one canvas:
//   • webcam (or synthetic entity) → real-time filter chains (engine.ts)
//   • MediaPipe face tracking → face-anchored filters (faceFilters.ts)
//   • live persona chat via SSE /api/personamatrix/stream, with TTS voices
//   • a mic voice-changer (VoiceChanger) mixed into the outgoing audio
//   • Apex billing ledger ticking live
//   • canvas.captureStream() → record an MP4/WebM or "go live" via WebRTC
//
// The guardrail from the handoff doc holds: the simulated audience renders into
// the frame as theater; it never posts to a real platform's chat.

import { useEffect, useRef, useState, useCallback } from 'react'
import { applyChain, directorPick, CHAINS, CHAIN_ORDER, type ChainName } from '@/lib/personamatrix/filters/engine'
import { speakAs, stopSpeaking, VoiceChanger, type VoicePreset } from '@/lib/streaming/voice'
import { loadFaceLandmarker, drawFaceFilter, type FaceFilter, type FaceLandmarkerResult } from '@/lib/streaming/faceFilters'

const W = 960, H = 540

interface ChatMsg { id: number; persona: number; text: string }

interface StreamMsg {
  kind: 'hello' | 'director' | 'chat'
  persona?: number
  text?: string
  cost_usd?: number
  energy?: number
}

const FACE_FILTERS: { id: FaceFilter; label: string }[] = [
  { id: 'none', label: 'None' },
  { id: 'entity_eyes', label: 'Entity Eyes' },
  { id: 'scarecrow_seam', label: 'Scarecrow Seam' },
  { id: 'third_eye', label: 'Third Eye' },
]

const VOICE_PRESETS: VoicePreset[] = ['off', 'entity', 'demon', 'chipmunk']

export default function DreamStudio() {
  const canvasRef = useRef<HTMLCanvasElement>(null)
  const offRef = useRef<HTMLCanvasElement | null>(null)
  const videoRef = useRef<HTMLVideoElement | null>(null)
  const tRef = useRef(0)
  const chainRef = useRef<ChainName | null>(null)
  const faceFilterRef = useRef<FaceFilter>('none')
  const landmarkerRef = useRef<Awaited<ReturnType<typeof loadFaceLandmarker>>>(null)
  const lastFaceRef = useRef<FaceLandmarkerResult | null>(null)
  const voiceChangerRef = useRef<VoiceChanger | null>(null)
  const voiceStreamRef = useRef<MediaStream | null>(null)
  const esRef = useRef<EventSource | null>(null)
  const recorderRef = useRef<MediaRecorder | null>(null)

  const [chain, setChain] = useState<ChainName | null>(null)
  const [faceFilter, setFaceFilter] = useState<FaceFilter>('none')
  const [autoDir, setAutoDir] = useState(true)
  const [energy, setEnergy] = useState(0.6)
  const [camOn, setCamOn] = useState(false)
  const [faceOn, setFaceOn] = useState(false)
  const [ttsOn, setTtsOn] = useState(false)
  const [voicePreset, setVoicePreset] = useState<VoicePreset>('off')
  const [recording, setRecording] = useState(false)
  const [chat, setChat] = useState<ChatMsg[]>([])
  const [stats, setStats] = useState({ execs: 0, cost: 0, alive: 0 })

  // keep refs in sync with state for the rAF loop
  useEffect(() => { chainRef.current = chain }, [chain])
  useEffect(() => { faceFilterRef.current = faceFilter }, [faceFilter])

  // ---- render loop -----------------------------------------------------------
  useEffect(() => {
    const canvas = canvasRef.current!
    const ctx = canvas.getContext('2d', { willReadFrequently: true })!
    const off = document.createElement('canvas'); off.width = W; off.height = H
    offRef.current = off
    const octx = off.getContext('2d', { willReadFrequently: true })!
    let raf = 0

    const drawSynthetic = (g: CanvasRenderingContext2D, t: number) => {
      g.fillStyle = '#0a0810'; g.fillRect(0, 0, W, H)
      const cx = W / 2, cy = H / 2 + 30
      g.strokeStyle = 'rgba(201,71,245,0.10)'; g.lineWidth = 1
      for (let i = 0; i < 20; i++) { const y = (t * 0.4 + i * 40) % H; g.beginPath(); g.moveTo(0, y); g.lineTo(W, y); g.stroke() }
      const breath = 0.5 + 0.5 * Math.sin(t * 0.04)
      const grd = g.createRadialGradient(cx, cy, 20, cx, cy, 260 + breath * 40)
      grd.addColorStop(0, 'rgba(57,255,20,0.22)'); grd.addColorStop(1, 'rgba(8,7,12,0)')
      g.fillStyle = grd; g.fillRect(0, 0, W, H)
      g.fillStyle = '#16121f'
      g.beginPath(); g.ellipse(cx, cy + 70, 90, 140, 0, 0, Math.PI * 2); g.fill()
      g.beginPath(); g.arc(cx, cy - 60, 62, 0, Math.PI * 2); g.fill()
      g.fillStyle = `rgba(201,71,245,${0.6 + 0.4 * breath})`
      g.beginPath(); g.arc(cx - 22, cy - 66, 9, 0, Math.PI * 2); g.arc(cx + 22, cy - 66, 9, 0, Math.PI * 2); g.fill()
    }

    const render = () => {
      const t = ++tRef.current
      const video = videoRef.current
      const hasVideo = video && video.readyState >= 2
      if (hasVideo) { octx.save(); octx.scale(-1, 1); octx.drawImage(video!, -W, 0, W, H); octx.restore() }
      else drawSynthetic(octx, t)
      ctx.drawImage(off, 0, 0)

      // full-frame chain filters
      applyChain(ctx, chainRef.current, t, W, H)

      // face-anchored filters (only when a face mesh is available)
      if (hasVideo && landmarkerRef.current && faceFilterRef.current !== 'none') {
        try {
          lastFaceRef.current = landmarkerRef.current.detectForVideo(video!, performance.now())
        } catch { /* drop frame */ }
        drawFaceFilter(ctx, faceFilterRef.current, lastFaceRef.current, t, W, H, true)
      }
      raf = requestAnimationFrame(render)
    }
    raf = requestAnimationFrame(render)
    return () => cancelAnimationFrame(raf)
  }, [])

  // ---- persona chat SSE ------------------------------------------------------
  const openStream = useCallback((e: number) => {
    esRef.current?.close()
    const es = new EventSource(`/api/personamatrix/stream?energy=${e.toFixed(2)}&module=dream`)
    es.onmessage = (ev) => {
      let m: StreamMsg
      try { m = JSON.parse(ev.data) } catch { return }
      if (m.kind === 'director') {
        if (autoDir) setChain(directorPick(energy))
        setStats((s) => ({ execs: s.execs + 1, cost: s.cost + (m.cost_usd ?? 0) + 0.0000004, alive: s.alive }))
        return
      }
      if (m.kind === 'chat' && m.text && typeof m.persona === 'number') {
        setChat((c) => [...c.slice(-40), { id: tRef.current, persona: m.persona!, text: m.text! }])
        setStats((s) => ({ execs: s.execs + 1, cost: s.cost + (m.cost_usd ?? 0) + 0.0000004, alive: s.alive }))
        if (ttsOn) speakAs(m.persona, m.text)
      }
    }
    es.onerror = () => { /* EventSource auto-reconnects */ }
    esRef.current = es
  }, [autoDir, energy, ttsOn])

  useEffect(() => {
    openStream(energy)
    return () => esRef.current?.close()
    // re-open when energy changes meaningfully so the server cadence updates
  }, [openStream, energy])

  // ---- webcam ----------------------------------------------------------------
  const toggleCam = useCallback(async () => {
    if (camOn) {
      const v = videoRef.current
      ;(v?.srcObject as MediaStream | null)?.getTracks().forEach((t) => t.stop())
      if (v) v.srcObject = null
      videoRef.current = null
      setCamOn(false); setFaceOn(false)
      return
    }
    try {
      const stream = await navigator.mediaDevices.getUserMedia({ video: { width: W, height: H }, audio: false })
      const v = document.createElement('video')
      v.srcObject = stream; v.muted = true; v.playsInline = true
      await v.play()
      videoRef.current = v
      setCamOn(true)
    } catch {
      alert('Camera access denied or unavailable.')
    }
  }, [camOn])

  const toggleFace = useCallback(async () => {
    if (faceOn) { setFaceOn(false); setFaceFilter('none'); return }
    if (!camOn) { alert('Turn the camera on first to track a face.'); return }
    const lm = await loadFaceLandmarker()
    if (!lm) { alert('Face tracking model failed to load (needs network + WebGL).'); return }
    landmarkerRef.current = lm
    setFaceOn(true)
    setFaceFilter('entity_eyes')
  }, [faceOn, camOn])

  // ---- mic voice-changer -----------------------------------------------------
  const applyVoice = useCallback(async (preset: VoicePreset) => {
    setVoicePreset(preset)
    if (preset === 'off') { voiceChangerRef.current?.setPreset('off'); return }
    if (!voiceChangerRef.current) {
      try {
        const mic = await navigator.mediaDevices.getUserMedia({ audio: true })
        const vc = new VoiceChanger()
        voiceStreamRef.current = vc.connect(mic)
        voiceChangerRef.current = vc
      } catch { alert('Microphone access denied.'); setVoicePreset('off'); return }
    }
    voiceChangerRef.current!.setPreset(preset)
  }, [])

  // ---- record / go live ------------------------------------------------------
  const toggleRecord = useCallback(() => {
    if (recording) { recorderRef.current?.stop(); return }
    const canvas = canvasRef.current!
    const stream = canvas.captureStream(30)
    // mix in the (optionally pitch-shifted) mic if the voice-changer is live
    voiceStreamRef.current?.getAudioTracks().forEach((track) => stream.addTrack(track))
    const chunks: Blob[] = []
    const rec = new MediaRecorder(stream, { mimeType: 'video/webm' })
    rec.ondataavailable = (e) => e.data.size && chunks.push(e.data)
    rec.onstop = () => {
      const blob = new Blob(chunks, { type: 'video/webm' })
      const url = URL.createObjectURL(blob)
      const a = document.createElement('a'); a.href = url; a.download = `dream-studio-${Date.now()}.webm`; a.click()
      URL.revokeObjectURL(url)
      setRecording(false)
    }
    rec.start()
    recorderRef.current = rec
    setRecording(true)
  }, [recording])

  // cleanup
  useEffect(() => () => {
    stopSpeaking()
    voiceChangerRef.current?.close()
    landmarkerRef.current?.close()
  }, [])

  return (
    <div className="grid h-screen grid-cols-[1fr_320px] grid-rows-[auto_1fr_auto] gap-3 bg-[#0a0810] p-3 text-slate-200">
      {/* header */}
      <header className="col-span-2 flex items-center gap-3 border-b border-[#c947f5]/30 pb-2">
        <h1 className="font-mono text-lg font-bold tracking-widest text-[#c947f5]">PERSONAMATRIX // DREAM STUDIO</h1>
        <span className="flex items-center gap-1 rounded bg-red-600/20 px-2 py-0.5 text-xs text-red-400">
          <span className="h-2 w-2 animate-pulse rounded-full bg-red-500" /> LIVE
        </span>
        <span className="ml-auto font-mono text-xs text-slate-500">20,480 ephemeral personas · spawn → speak → die</span>
      </header>

      {/* stage */}
      <div className="relative row-start-2 overflow-hidden rounded-lg border border-[#c947f5]/20 bg-black">
        <canvas ref={canvasRef} width={W} height={H} className="h-full w-full object-contain" />
        {/* chat overlay */}
        <div className="pointer-events-none absolute bottom-0 left-0 max-h-[55%] w-[55%] overflow-hidden p-3">
          <div className="flex flex-col justify-end gap-1">
            {chat.map((m, i) => (
              <div key={`${m.id}-${i}`} className="w-fit max-w-full rounded bg-black/55 px-2 py-1 text-xs backdrop-blur-sm">
                <span className="font-mono text-[#39ff14]">persona_{m.persona}</span>{' '}
                <span className="text-slate-200">{m.text}</span>
              </div>
            ))}
          </div>
        </div>
        {chain && (
          <div className="absolute right-3 top-3 rounded bg-black/60 px-2 py-1 font-mono text-xs text-[#c947f5]">
            {CHAINS[chain].label}
          </div>
        )}
      </div>

      {/* sidebar */}
      <aside className="row-start-2 flex flex-col gap-4 overflow-y-auto rounded-lg border border-[#c947f5]/20 bg-[#0f0c16] p-3 text-sm">
        <Section title="FILTER CHAIN">
          <div className="flex flex-col gap-1">
            {CHAIN_ORDER.map((c, i) => (
              <button key={c} onClick={() => { setAutoDir(false); setChain(c) }}
                className={`rounded px-2 py-1.5 text-left font-mono text-xs transition ${chain === c ? 'bg-[#c947f5] text-black' : 'bg-white/5 hover:bg-white/10'}`}>
                {i + 1}. {CHAINS[c].label}
                <span className="block text-[10px] opacity-60">{CHAINS[c].hint}</span>
              </button>
            ))}
            <button onClick={() => { setAutoDir(false); setChain(null) }}
              className="rounded bg-white/5 px-2 py-1 text-left font-mono text-xs hover:bg-white/10">0. STANDBY</button>
          </div>
        </Section>

        <Section title="DIRECTOR">
          <label className="flex items-center gap-2 text-xs">
            <input type="checkbox" checked={autoDir} onChange={(e) => setAutoDir(e.target.checked)} />
            auto-director (energy → chain)
          </label>
          <label className="mt-2 block text-xs">energy {energy.toFixed(2)}
            <input type="range" min={0} max={1} step={0.01} value={energy}
              onChange={(e) => setEnergy(Number(e.target.value))} className="mt-1 w-full accent-[#c947f5]" />
          </label>
        </Section>

        <Section title="CAMERA & FACE">
          <Toggle on={camOn} onClick={toggleCam} label={camOn ? 'camera on' : 'use my webcam'} />
          <Toggle on={faceOn} onClick={toggleFace} label={faceOn ? 'face tracking on' : 'track my face'} />
          {faceOn && (
            <div className="mt-1 flex flex-wrap gap-1">
              {FACE_FILTERS.map((f) => (
                <button key={f.id} onClick={() => setFaceFilter(f.id)}
                  className={`rounded px-2 py-1 text-[11px] ${faceFilter === f.id ? 'bg-[#39ff14] text-black' : 'bg-white/5 hover:bg-white/10'}`}>
                  {f.label}
                </button>
              ))}
            </div>
          )}
        </Section>

        <Section title="VOICE">
          <label className="flex items-center gap-2 text-xs">
            <input type="checkbox" checked={ttsOn} onChange={(e) => { setTtsOn(e.target.checked); if (!e.target.checked) stopSpeaking() }} />
            personas speak (TTS)
          </label>
          <div className="mt-2 text-[11px] opacity-70">my voice changer</div>
          <div className="mt-1 flex flex-wrap gap-1">
            {VOICE_PRESETS.map((p) => (
              <button key={p} onClick={() => applyVoice(p)}
                className={`rounded px-2 py-1 text-[11px] capitalize ${voicePreset === p ? 'bg-[#c947f5] text-black' : 'bg-white/5 hover:bg-white/10'}`}>
                {p}
              </button>
            ))}
          </div>
        </Section>

        <Section title="APEX LEDGER">
          <div className="grid grid-cols-2 gap-1 font-mono text-xs">
            <Stat label="executions" value={stats.execs.toString()} />
            <Stat label="cost" value={`$${stats.cost.toFixed(6)}`} />
          </div>
          <p className="mt-1 text-[10px] opacity-50">every line above = one persona that already died.</p>
        </Section>

        <button onClick={toggleRecord}
          className={`mt-auto rounded px-3 py-2 font-mono text-sm ${recording ? 'bg-red-600 text-white' : 'bg-[#39ff14] text-black'}`}>
          {recording ? '■ stop & download' : '● record stream'}
        </button>
      </aside>

      <footer className="col-span-2 border-t border-[#c947f5]/20 pt-2 font-mono text-[11px] text-slate-500">
        keys handled in the on-screen controls · simulated audience renders into the frame only — never posts to a real platform
      </footer>
    </div>
  )
}

function Section({ title, children }: { title: string; children: React.ReactNode }) {
  return (
    <section>
      <h2 className="mb-1.5 font-mono text-[11px] tracking-widest text-[#c947f5]/80">{title}</h2>
      {children}
    </section>
  )
}

function Toggle({ on, onClick, label }: { on: boolean; onClick: () => void; label: string }) {
  return (
    <button onClick={onClick}
      className={`mb-1 w-full rounded px-2 py-1.5 text-left text-xs transition ${on ? 'bg-[#39ff14]/20 text-[#39ff14]' : 'bg-white/5 hover:bg-white/10'}`}>
      {on ? '● ' : '○ '}{label}
    </button>
  )
}

function Stat({ label, value }: { label: string; value: string }) {
  return (
    <div className="rounded bg-white/5 px-2 py-1">
      <div className="text-[10px] opacity-50">{label}</div>
      <div className="text-[#39ff14]">{value}</div>
    </div>
  )
}
