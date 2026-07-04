import { createClient as createSupabaseClient } from "@supabase/supabase-js";

/**
 * Service-role client for server-only backend writes (ledger, personas, tenants).
 * Never import this from a client component — it bypasses RLS.
 */
export function createAdminClient() {
  return createSupabaseClient(
    process.env.NEXT_PUBLIC_SUPABASE_URL!,
    process.env.SUPABASE_SERVICE_ROLE_KEY!,
    { auth: { autoRefreshToken: false, persistSession: false } }
  );
}
