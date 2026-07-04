import DreamStudio from '@/components/studio/DreamStudio'

export const metadata = {
  title: 'Dream Studio · PersonaMatrix',
  description: 'Live streaming studio — filter chains, face filters, persona chat, and voice on the PersonaMatrix backbone.',
}

// Browser-only surface (webcam, canvas, WebRTC, Web Audio). DreamStudio is a
// client component; this page is just the route shell. It sits behind the auth
// proxy like /game — a signed-in streamer's control deck.
export default function StudioPage() {
  return <DreamStudio />
}
