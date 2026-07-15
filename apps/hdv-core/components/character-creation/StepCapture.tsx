'use client'

// CAPTURE step — the "can we do the Gemini avatar thing" ask, plus a voice
// line the player dials in themselves. Everything here is browser-native
// (getUserMedia + canvas + Web Audio), same philosophy as the Dream Studio:
// no external API, no key, works the moment the page loads. Fully optional —
// the wizard never blocks on this step.

import { useCallback, useEffect, useRef, useState } from 'react'
import {
  AVATAR_STYLES,
  capturePhoto,
  dataUrlToBlob,
  stylizeAvatar,
  type AvatarStyle,
} from '@/lib/streaming/avatarStylizer'
import { VoiceStudio } from '@/lib/streaming/voice'
import { savePortrait, saveVoiceClip } from '@/lib/character/mediaStore'

const CLIP_MAX_SECONDS = 12

interface Props {
  slot: number
  portraitDataUrl: string | null
  onPortraitChange: (dataUrl: string | null) => void
}

export default function StepCapture({ slot, portraitDataUrl, onPortraitChange }: Props) {
  // ---- camera / photo / clip -------------------------------------------------
  const videoRef = useRef<HTMLVideoElement | null>(null)
  const camStreamRef = useRef<MediaStream | null>(null)
  const recorderRef = useRef<MediaRecorder | null>(null)
  const [camOn, setCamOn] = useState(false)
  const [rawPhoto, setRawPhoto] = useState<string | null>(null)
  const [style, setStyle] = useState<AvatarStyle>('portrait')
  const [busy, setBusy] = useState(false)
  const [clip, setClip] = useState<{ url: string; filename: string } | null>(null)
  const clipRef = useRef<{ url: string; filename: string } | null>(null)
  const [recordingClip, setRecordingClip] = useState(false)
  const [clipSeconds, setClipSeconds] = useState(0)
  const clipTimerRef = useRef<ReturnType<typeof setInterval> | null>(null)

  // ---- voice ------------------------------------------------------------------
  const micStreamRef = useRef<MediaStream | null>(null)
  const studioRef = useRef<VoiceStudio | null>(null)
  const processedStreamRef = useRef<MediaStream | null>(null)
  const voiceRecorderRef = useRef<MediaRecorder | null>(null)
  const [micOn, setMicOn] = useState(false)
  const [pitch, setPitch] = useState(0)
  const [bass, setBass] = useState(0)
  const [treble, setTreble] = useState(0)
  const [recordingVoice, setRecordingVoice] = useState(false)
  const [voiceClip, setVoiceClip] = useState<{ url: string; filename: string } | null>(null)
  const voiceClipRef = useRef<{ url: string; filename: string } | null>(null)

  useEffect(() => () => {
    camStreamRef.current?.getTracks().forEach((t) => t.stop())
    micStreamRef.current?.getTracks().forEach((t) => t.stop())
    studioRef.current?.close()
    if (clipTimerRef.current) clearInterval(clipTimerRef.current)
    if (clipRef.current) URL.revokeObjectURL(clipRef.current.url)
    if (voiceClipRef.current) URL.revokeObjectURL(voiceClipRef.current.url)
  }, [])

  // ---- camera -----------------------------------------------------------------
  const toggleCam = useCallback(async () => {
    if (camOn) {
      camStreamRef.current?.getTracks().forEach((t) => t.stop())
      camStreamRef.current = null
      if (videoRef.current) videoRef.current.srcObject = null
      setCamOn(false)
      return
    }
    try {
      const stream = await navigator.mediaDevices.getUserMedia({ video: { width: 512, height: 512 }, audio: true })
      camStreamRef.current = stream
      if (videoRef.current) {
        videoRef.current.srcObject = stream
        await videoRef.current.play()
      }
      setCamOn(true)
    } catch {
      alert('Camera access denied or unavailable.')
    }
  }, [camOn])

  const takePhoto = useCallback(() => {
    if (!videoRef.current || !camOn) return
    const dataUrl = capturePhoto(videoRef.current, true)
    setRawPhoto(dataUrl)
    onPortraitChange(null) // clear any previously saved avatar until re-stylized
  }, [camOn, onPortraitChange])

  const generateAvatar = useCallback(async (chosen: AvatarStyle) => {
    if (!rawPhoto) return
    setStyle(chosen)
    setBusy(true)
    try {
      const stylized = await stylizeAvatar(rawPhoto, chosen)
      onPortraitChange(stylized)
      await savePortrait(slot, dataUrlToBlob(stylized))
    } finally {
      setBusy(false)
    }
  }, [rawPhoto, slot, onPortraitChange])

  const toggleClip = useCallback(() => {
    if (recordingClip) { recorderRef.current?.stop(); return }
    if (!camStreamRef.current) { alert('Turn the camera on first.'); return }
    const chunks: Blob[] = []
    const rec = new MediaRecorder(camStreamRef.current, { mimeType: 'video/webm' })
    rec.ondataavailable = (e) => e.data.size && chunks.push(e.data)
    rec.onstop = () => {
      if (clipTimerRef.current) { clearInterval(clipTimerRef.current); clipTimerRef.current = null }
      const blob = new Blob(chunks, { type: 'video/webm' })
      setClip((prev) => {
        if (prev) URL.revokeObjectURL(prev.url)
        const next = { url: URL.createObjectURL(blob), filename: `perihuman-clip-${Date.now()}.webm` }
        clipRef.current = next
        return next
      })
      setRecordingClip(false)
      setClipSeconds(0)
    }
    rec.start()
    recorderRef.current = rec
    setRecordingClip(true)
    setClipSeconds(0)
    clipTimerRef.current = setInterval(() => {
      setClipSeconds((s) => {
        if (s + 1 >= CLIP_MAX_SECONDS) { rec.stop(); return s }
        return s + 1
      })
    }, 1000)
  }, [recordingClip])

  // ---- voice --------------------------------------------------------------------
  const toggleMic = useCallback(async () => {
    if (micOn) {
      micStreamRef.current?.getTracks().forEach((t) => t.stop())
      studioRef.current?.close()
      studioRef.current = null
      micStreamRef.current = null
      processedStreamRef.current = null
      setMicOn(false)
      return
    }
    try {
      const mic = await navigator.mediaDevices.getUserMedia({ audio: true })
      const studio = new VoiceStudio()
      const processed = studio.connect(mic)
      studio.setPitchSemitones(pitch)
      studio.setBass(bass)
      studio.setTreble(treble)
      micStreamRef.current = mic
      studioRef.current = studio
      processedStreamRef.current = processed
      setMicOn(true)
    } catch {
      alert('Microphone access denied.')
    }
  }, [micOn, pitch, bass, treble])

  useEffect(() => { studioRef.current?.setPitchSemitones(pitch) }, [pitch])
  useEffect(() => { studioRef.current?.setBass(bass) }, [bass])
  useEffect(() => { studioRef.current?.setTreble(treble) }, [treble])

  const toggleVoiceRecord = useCallback(() => {
    if (recordingVoice) { voiceRecorderRef.current?.stop(); return }
    if (!processedStreamRef.current) { alert('Turn the mic on first.'); return }
    const chunks: Blob[] = []
    const rec = new MediaRecorder(processedStreamRef.current)
    rec.ondataavailable = (e) => e.data.size && chunks.push(e.data)
    rec.onstop = async () => {
      const blob = new Blob(chunks, { type: 'audio/webm' })
      setVoiceClip((prev) => {
        if (prev) URL.revokeObjectURL(prev.url)
        const next = { url: URL.createObjectURL(blob), filename: `perihuman-voice-${Date.now()}.webm` }
        voiceClipRef.current = next
        return next
      })
      setRecordingVoice(false)
      await saveVoiceClip(slot, blob)
    }
    rec.start()
    voiceRecorderRef.current = rec
    setRecordingVoice(true)
  }, [recordingVoice, slot])

  return (
    <div>
      <h2 className="font-mono text-lg text-slate-200 mb-1 tracking-wider">CAPTURE YOUR PERIHUMAN</h2>
      <p className="font-mono text-xs text-slate-500 mb-4">
        Optional — snap a photo or short clip and turn it into your avatar, then record a voice line and
        dial in pitch, bass, and treble until it sounds like you want it to. Everything happens on your
        device; nothing is uploaded anywhere.
      </p>

      {/* Photo + avatar */}
      <div className="grid grid-cols-2 gap-4 mb-6">
        <div>
          <div className="aspect-square rounded-lg overflow-hidden bg-black border border-purple-900 flex items-center justify-center">
            {camOn ? (
              <video ref={videoRef} muted playsInline className="w-full h-full object-cover -scale-x-100" />
            ) : (
              <span className="font-mono text-xs text-slate-600">camera off</span>
            )}
          </div>
          <div className="flex gap-2 mt-2">
            <button
              onClick={toggleCam}
              className="flex-1 px-3 py-2 rounded-lg border border-slate-700 hover:border-slate-500 font-mono text-xs text-slate-300"
            >
              {camOn ? 'STOP CAMERA' : 'USE CAMERA'}
            </button>
            <button
              onClick={takePhoto}
              disabled={!camOn}
              className="flex-1 px-3 py-2 rounded-lg bg-purple-700 hover:bg-purple-600 disabled:opacity-40 font-mono text-xs text-white"
            >
              📸 TAKE PHOTO
            </button>
          </div>
          <button
            onClick={toggleClip}
            disabled={!camOn}
            className={`w-full mt-2 px-3 py-2 rounded-lg font-mono text-xs disabled:opacity-40 ${
              recordingClip ? 'bg-red-600 text-white' : 'border border-slate-700 hover:border-slate-500 text-slate-300'
            }`}
          >
            {recordingClip ? `■ STOP (${CLIP_MAX_SECONDS - clipSeconds}s left)` : `🎬 RECORD ${CLIP_MAX_SECONDS}s CLIP`}
          </button>
          {clip && (
            <div className="mt-2">
              <video src={clip.url} controls className="w-full rounded-lg border border-purple-900" />
              <a
                href={clip.url}
                download={clip.filename}
                className="block mt-1 text-center font-mono text-[11px] text-purple-500 hover:text-purple-300"
              >
                ⬇ download clip
              </a>
            </div>
          )}
        </div>

        <div>
          <div className="aspect-square rounded-lg overflow-hidden bg-[#0f0f1a] border border-purple-900 flex items-center justify-center">
            {portraitDataUrl ? (
              // eslint-disable-next-line @next/next/no-img-element
              <img src={portraitDataUrl} alt="Avatar preview" className="w-full h-full object-cover" />
            ) : rawPhoto ? (
              // eslint-disable-next-line @next/next/no-img-element
              <img src={rawPhoto} alt="Captured photo" className="w-full h-full object-cover opacity-60" />
            ) : (
              <span className="font-mono text-xs text-slate-600 px-4 text-center">
                take a photo, then pick a style
              </span>
            )}
          </div>
          <div className="flex gap-1 mt-2">
            {AVATAR_STYLES.map((s) => (
              <button
                key={s.id}
                onClick={() => generateAvatar(s.id)}
                disabled={!rawPhoto || busy}
                title={s.hint}
                className={`flex-1 px-2 py-2 rounded-lg font-mono text-xs disabled:opacity-40 ${
                  style === s.id && portraitDataUrl
                    ? 'bg-purple-700 text-white'
                    : 'border border-slate-700 hover:border-slate-500 text-slate-300'
                }`}
              >
                {s.label}
              </button>
            ))}
          </div>
          {portraitDataUrl && (
            <a
              href={portraitDataUrl}
              download="perihuman-avatar.png"
              className="block mt-1 text-center font-mono text-[11px] text-purple-500 hover:text-purple-300"
            >
              ⬇ download avatar
            </a>
          )}
        </div>
      </div>

      {/* Voice */}
      <div className="rounded-lg border border-purple-900 bg-[#1a1a2e]/40 p-4">
        <div className="flex items-center gap-2 mb-3">
          <button
            onClick={toggleMic}
            className={`px-3 py-2 rounded-lg font-mono text-xs ${
              micOn ? 'bg-[#39ff14]/20 text-[#39ff14]' : 'border border-slate-700 hover:border-slate-500 text-slate-300'
            }`}
          >
            {micOn ? '● MIC ON' : '🎙️ USE MIC'}
          </button>
          <button
            onClick={toggleVoiceRecord}
            disabled={!micOn}
            className={`px-3 py-2 rounded-lg font-mono text-xs disabled:opacity-40 ${
              recordingVoice ? 'bg-red-600 text-white' : 'bg-purple-700 hover:bg-purple-600 text-white'
            }`}
          >
            {recordingVoice ? '■ STOP RECORDING' : '● RECORD VOICE LINE'}
          </button>
          <span className="font-mono text-[11px] text-slate-500 ml-auto">adjust live while the mic is on</span>
        </div>

        <div className="grid grid-cols-3 gap-4">
          <Slider label="PITCH" value={pitch} min={-12} max={12} step={1} unit="st" onChange={setPitch} />
          <Slider label="BASS" value={bass} min={-15} max={15} step={1} unit="dB" onChange={setBass} />
          <Slider label="TREBLE" value={treble} min={-15} max={15} step={1} unit="dB" onChange={setTreble} />
        </div>

        {voiceClip && (
          <div className="mt-3 flex items-center gap-2">
            <audio src={voiceClip.url} controls className="flex-1 h-8" />
            <a
              href={voiceClip.url}
              download={voiceClip.filename}
              className="font-mono text-[11px] text-purple-500 hover:text-purple-300 whitespace-nowrap"
            >
              ⬇ download
            </a>
          </div>
        )}
      </div>
    </div>
  )
}

function Slider({
  label, value, min, max, step, unit, onChange,
}: {
  label: string
  value: number
  min: number
  max: number
  step: number
  unit: string
  onChange: (v: number) => void
}) {
  return (
    <label className="block">
      <div className="font-mono text-[11px] text-purple-500 mb-1">
        {label} <span className="text-slate-500">{value > 0 ? `+${value}` : value}{unit}</span>
      </div>
      <input
        type="range"
        min={min}
        max={max}
        step={step}
        value={value}
        onChange={(e) => onChange(Number(e.target.value))}
        className="w-full accent-purple-500"
      />
    </label>
  )
}
