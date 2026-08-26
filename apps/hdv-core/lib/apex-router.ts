/**
 * lib/apex-router.ts — APEX Mixture-of-Experts heuristic router.
 *
 * Pure model-selection logic shared by the /api/apex route handler,
 * the workflow simulator, and any other caller that needs a model decision
 * without making a network call.
 */

export type BudgetTier = 'low' | 'medium' | 'high'

export interface RouteDecision {
  model: string
  category: string
  budgetTier: BudgetTier
  reasoning: string
}

const MODEL_MAP = {
  haiku: 'claude-haiku-4-5-20251001',
  sonnet: 'claude-sonnet-5',
  opus: 'claude-opus-5',
  fable: 'claude-fable-5',
} as const

export function heuristicRoute(
  intent: string,
  category: string,
  budgetTier: BudgetTier,
  preferSpeed = false,
): string {
  const low = budgetTier === 'low' || preferSpeed
  const high = budgetTier === 'high'

  switch (category) {
    case 'security': case 'audit':
      return high ? MODEL_MAP.opus : MODEL_MAP.sonnet
    case 'code': case 'analysis':
      return low ? MODEL_MAP.haiku : high ? MODEL_MAP.opus : MODEL_MAP.sonnet
    case 'creative': case 'simulation':
      return high ? MODEL_MAP.fable : MODEL_MAP.sonnet
    case 'vision': case 'multimodal':
      return MODEL_MAP.sonnet
    case 'chat': case 'support':
      return low ? MODEL_MAP.haiku : MODEL_MAP.sonnet
    default: {
      const lower = intent.toLowerCase()
      if (/secur|audit|knoll/.test(lower)) return MODEL_MAP.opus
      if (/dream|simulat|creat/.test(lower)) return MODEL_MAP.fable
      if (/cod|debug|refactor/.test(lower)) return MODEL_MAP.sonnet
      return low ? MODEL_MAP.haiku : MODEL_MAP.sonnet
    }
  }
}

export function routeTask(
  intent: string,
  category = 'general',
  budgetTier: BudgetTier = 'medium',
  preferSpeed = false,
): RouteDecision {
  const model = heuristicRoute(intent, category, budgetTier, preferSpeed)
  return {
    model,
    category,
    budgetTier,
    reasoning: `Heuristic: category="${category}" budget="${budgetTier}"${preferSpeed ? ' speed=true' : ''} → ${model}`,
  }
}
