import { type NextRequest, NextResponse } from 'next/server'

export const runtime = 'nodejs'

const GEMINI_URL = 'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent'

export async function POST(request: NextRequest) {
  try {
    const { name, mimeType, count, firstCreated, mostRecentCreated } = await request.json()

    const apiKey = process.env.GEMINI_API_KEY
    if (!apiKey) {
      return NextResponse.json(
        {
          explanation:
            'AI triage is offline — set GEMINI_API_KEY (free from Google AI Studio) to enable this feature.',
        },
        { status: 200 },
      )
    }

    const isFolder = mimeType === 'application/vnd.google-apps.folder'
    const prompt = `A user's Google Drive has ${count} ${isFolder ? 'folders' : 'files'} all named "${name}", first created ${firstCreated} and most recently ${mostRecentCreated}. This pattern usually means an Apps Script time-driven trigger, a recurring calendar/automation integration (Zapier, Make, IFTTT), or a misconfigured sync tool is recreating it on a schedule.

In 2-3 short sentences, explain the most likely cause of this pattern and give one concrete next step to find and stop it (e.g. where to look in script.google.com triggers, or which third-party integration to check). Be specific and concise.`

    const res = await fetch(`${GEMINI_URL}?key=${apiKey}`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        contents: [{ parts: [{ text: prompt }] }],
      }),
    })

    if (!res.ok) {
      const body = await res.text()
      console.error('Gemini API error:', res.status, body)
      return NextResponse.json(
        { explanation: 'AI triage is temporarily unavailable — try again shortly.' },
        { status: 200 },
      )
    }

    const data = await res.json()
    const explanation: string =
      data.candidates?.[0]?.content?.parts?.[0]?.text ?? 'No explanation returned.'

    return NextResponse.json({ explanation })
  } catch (err) {
    console.error('Cleaner explain API error:', err)
    return NextResponse.json(
      { explanation: 'AI triage is temporarily unavailable — try again shortly.' },
      { status: 200 },
    )
  }
}
