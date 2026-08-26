/**
 * POST /api/workflows/simulate — DREAM simulation endpoint.
 *
 * Runs a workflow definition through DREAM's dry-run simulator without
 * executing real side effects. Supports three modes:
 *   - (default) simulate: trace every node in dry-run
 *   - score: score workflow for security, error-handling, and cost
 *   - generate: generate a workflow plan from a natural-language intent
 */
import { type NextRequest, NextResponse } from 'next/server'
import { createClient } from '@/lib/supabase/server'

export const runtime = 'nodejs'

const WORKFLOW_API = (process.env.WORKFLOW_API_URL ?? 'http://localhost:3001').replace(/\/$/, '')
const WORKFLOW_API_KEY = process.env.WORKFLOW_API_KEY ?? ''

export async function POST(request: NextRequest) {
  const supabase = await createClient()
  const { data: { user } } = await supabase.auth.getUser()
  if (!user) return NextResponse.json({ error: 'Unauthorized' }, { status: 401 })

  const body = await request.json().catch(() => ({}))
  const mode = String(body.mode ?? 'simulate')
  const subPath = mode === 'generate' ? '/generate' : mode === 'score' ? '/score' : ''

  if (!WORKFLOW_API_KEY) {
    // Run local heuristic scoring when orchestrator is not configured
    if (mode === 'score') {
      return NextResponse.json(localScore(body.nodes ?? [], body.edges ?? []))
    }
    return NextResponse.json(
      { error: 'Workflow orchestrator not configured — set WORKFLOW_API_URL and WORKFLOW_API_KEY.' },
      { status: 503 },
    )
  }

  const resp = await fetch(`${WORKFLOW_API}/simulate${subPath}`, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      Authorization: `Bearer ${WORKFLOW_API_KEY}`,
      'x-hdv-user-id': user.id,
    },
    body: JSON.stringify(body),
  })

  return NextResponse.json(await resp.json(), { status: resp.status })
}

// Local fallback scorer (no orchestrator needed)
const SIDE_EFFECTFUL = new Set(['httpRequest', 'email', 'slack', 'database', 'webhookTrigger', 'subWorkflow'])
function localScore(nodes: { id: string; type?: string; data?: { nodeType?: string } }[], edges: unknown[]) {
  const types = nodes.map((n) => String(n.data?.nodeType || n.type || ''))
  const score = [
    types.some((t) => t === 'stopError' || t === 'ifBranch') ? 20 : 0,
    types.some((t) => t === 'respond' || t === 'set') ? 15 : 0,
    types.includes('knoll') ? 25 : 0,
    types.includes('apex') ? 20 : 0,
    nodes.length >= 2 ? 10 : 0,
    Array.isArray(edges) && edges.length >= 1 ? 10 : 0,
  ].reduce((a, b) => a + b, 0)
  return {
    score: Math.min(score, 100),
    grade: score >= 80 ? 'A' : score >= 60 ? 'B' : score >= 40 ? 'C' : 'D',
    hasKnoll: types.includes('knoll'),
    hasApex: types.includes('apex'),
    hasErrorHandling: types.some((t) => t === 'stopError' || t === 'ifBranch'),
    sideEffectCount: types.filter((t) => SIDE_EFFECTFUL.has(t)).length,
    nodeCount: nodes.length,
    edgeCount: Array.isArray(edges) ? edges.length : 0,
    source: 'local',
  }
}
