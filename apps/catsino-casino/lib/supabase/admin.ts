import { createClient, SupabaseClient } from '@supabase/supabase-js'

let cached: SupabaseClient | null = null

// Lazy singleton: world-builder API routes need the service-role client, but
// instantiating it at module load time crashes `next build`'s page-data
// collection step in any environment where SUPABASE_SERVICE_ROLE_KEY isn't
// set (e.g. preview builds without prod secrets) with "supabaseKey is
// required". Creating it on first request instead defers that to runtime.
export function getAdminClient(): SupabaseClient {
  if (!cached) {
    cached = createClient(
      process.env.NEXT_PUBLIC_SUPABASE_URL!,
      process.env.SUPABASE_SERVICE_ROLE_KEY!,
    )
  }
  return cached
}
