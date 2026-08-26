/**
 * POST /api/apex — APEX Mixture-of-Experts routing endpoint.
 *
 * Routes a task to the optimal Claude model based on the task category,
 * budget tier, and intent. This is the HDV MoE router that DREAM, VISION,
 * and the workflow platform use to dispatch AI tasks.
 *
 * Request body:
 *   {
 *     intent: string,         // natural language task description
 *     category?: string,      // "code" | "creative" | "security" | "analysis" | "vision" | "chat"
 *     budgetTier?: string,    // "low" | "medium" | "high"
 *     preferSpeed?: boolean,
 *     systemPrompt?: string,  // optional system prompt override
 *     maxTokens?: number,
 *   }
 */
import { type NextRequest, NextResponse } from 'next/server'
import { createClient } from '@/lib/supabase/server'
import { heuristicRoute, type BudgetTier } from '@/lib/apex-router'

export const runtime = 'nodejs'

const MODEL_ALIASES: Record<string, string> = {
  haiku: 'claude-haiku-4-5-20251001',
  sonnet: 'claude-sonnet-5',
  opus: 'claude-opus-5',
  fable: 'claude-fable-5',
  'sonnet-4': 'claude-sonnet-4-6',
}

export async function POST(request: NextRequest) {
  const supabase = await createClient()
  const { data: { user } } = await supabase.auth.getUser()
  if (!user) return NextResponse.json({ error: 'Unauthorized' }, { status: 401 })

  const apiKey = process.env.ANTHROPIC_API_KEY
  if (!apiKey) {
    return NextResponse.json(
      { error: 'APEX is offline — set ANTHROPIC_API_KEY to enable routing.' },
      { status: 503 },
    )
  }

  try {
    const {
      intent,
      category = 'general',
      budgetTier = 'medium',
      preferSpeed = false,
      systemPrompt,
      maxTokens = 1024,
      model: modelOverride,
    } = await request.json()

    if (!intent || typeof intent !== 'string') {
      return NextResponse.json({ error: 'intent is required' }, { status: 400 })
    }

    const resolvedModel = modelOverride
      ? (MODEL_ALIASES[modelOverride] ?? modelOverride)
      : heuristicRoute(intent, category, budgetTier as BudgetTier, preferSpeed)

    const body: Record<string, unknown> = {
      model: resolvedModel,
      max_tokens: maxTokens,
      messages: [{ role: 'user', content: intent }],
    }
    if (systemPrompt) body.system = systemPrompt

    const resp = await fetch('https://api.anthropic.com/v1/messages', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'x-api-key': apiKey,
        'anthropic-version': '2023-06-01',
      },
      body: JSON.stringify(body),
    })

    if (!resp.ok) {
      const errText = await resp.text()
      console.error('APEX API error:', resp.status, errText)
      return NextResponse.json(
        { error: 'APEX routing failed — model unavailable.' },
        { status: 502 },
      )
    }

    const data = await resp.json() as {
      content: Array<{ type: string; text: string }>
      usage?: unknown
    }
    const text = data.content?.find((c) => c.type === 'text')?.text ?? ''

    let parsed: unknown = text
    try { parsed = JSON.parse(text) } catch {}

    return NextResponse.json({
      model: resolvedModel,
      category,
      budgetTier,
      text,
      parsed,
      usage: data.usage,
      routedBy: 'apex-heuristic',
    })
  } catch (err) {
    console.error('APEX route error:', err)
    return NextResponse.json(
      { error: 'APEX routing error — try again.' },
      { status: 500 },
    )
  }
}

// GET /api/apex — return routing info (no AI call)
export async function GET(request: NextRequest) {
  const supabase = await createClient()
  const { data: { user } } = await supabase.auth.getUser()
  if (!user) return NextResponse.json({ error: 'Unauthorized' }, { status: 401 })

  const url = new URL(request.url)
  const intent = url.searchParams.get('intent') ?? ''
  const category = url.searchParams.get('category') ?? 'general'
  const budgetTier = url.searchParams.get('budgetTier') ?? 'medium'
  const preferSpeed = url.searchParams.get('preferSpeed') === 'true'

  const model = heuristicRoute(intent, category, budgetTier as BudgetTier, preferSpeed)
  return NextResponse.json({ model, category, budgetTier, routedBy: 'apex-heuristic' })
}
