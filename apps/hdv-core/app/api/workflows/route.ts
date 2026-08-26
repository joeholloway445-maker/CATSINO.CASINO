/**
 * /api/workflows — HDV Workflow proxy for the n8n-clone orchestrator.
 *
 * Proxies authenticated requests to the HDV Orchestrator API
 * (WORKFLOW_API_URL) using the current Supabase user's ID as the userId.
 *
 * This integrates HOPE (Supabase auth) with the workflow platform so the
 * game app can create, run, and monitor automation workflows.
 */
import { type NextRequest, NextResponse } from 'next/server'
import { createClient } from '@/lib/supabase/server'

export const runtime = 'nodejs'

const WORKFLOW_API = (process.env.WORKFLOW_API_URL ?? 'http://localhost:3001').replace(/\/$/, '')
const WORKFLOW_API_KEY = process.env.WORKFLOW_API_KEY ?? ''

function proxyHeaders(userId: string): HeadersInit {
  return {
    'Content-Type': 'application/json',
    ...(WORKFLOW_API_KEY ? { Authorization: `Bearer ${WORKFLOW_API_KEY}` } : {}),
    'x-hdv-user-id': userId,
  }
}

export async function GET(request: NextRequest) {
  const supabase = await createClient()
  const { data: { user } } = await supabase.auth.getUser()
  if (!user) return NextResponse.json({ error: 'Unauthorized' }, { status: 401 })

  if (!WORKFLOW_API_KEY) {
    return NextResponse.json(
      { error: 'Workflow orchestrator not configured — set WORKFLOW_API_URL and WORKFLOW_API_KEY.' },
      { status: 503 },
    )
  }

  const url = new URL(request.url)
  const qs = url.search
  const resp = await fetch(`${WORKFLOW_API}/workflows${qs}`, {
    headers: proxyHeaders(user.id),
  })
  const data = await resp.json()
  return NextResponse.json(data, { status: resp.status })
}

export async function POST(request: NextRequest) {
  const supabase = await createClient()
  const { data: { user } } = await supabase.auth.getUser()
  if (!user) return NextResponse.json({ error: 'Unauthorized' }, { status: 401 })

  if (!WORKFLOW_API_KEY) {
    return NextResponse.json(
      { error: 'Workflow orchestrator not configured — set WORKFLOW_API_URL and WORKFLOW_API_KEY.' },
      { status: 503 },
    )
  }

  const body = await request.json()
  const resp = await fetch(`${WORKFLOW_API}/workflows`, {
    method: 'POST',
    headers: proxyHeaders(user.id),
    body: JSON.stringify(body),
  })
  const data = await resp.json()
  return NextResponse.json(data, { status: resp.status })
}
