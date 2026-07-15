# Environment variables

Copy these into a local `.env.local` (which is gitignored).

```
# Supabase — shared Periliminal.Space project
NEXT_PUBLIC_SUPABASE_URL=
NEXT_PUBLIC_SUPABASE_ANON_KEY=

# Server-only. Powers admin routes (lib/supabase/admin.ts). Never expose client-side.
SUPABASE_SERVICE_ROLE_KEY=
```

## Supabase setup — shared project

CATSINO.CASINO and hdv-core are one universe and use **one Supabase project**
(`lamdemoaszkilguvkvcd` / Periliminal.Space). Point both apps at the same
`NEXT_PUBLIC_SUPABASE_URL` / `NEXT_PUBLIC_SUPABASE_ANON_KEY`.

1. Get the **Project URL**, **anon key**, and **service_role key** from
   Supabase → Project Settings → API.
2. Apply monorepo migrations from `supabase/migrations/` (via SQL editor or
   `supabase db push`). Casino economy lives in
   `030_catsino_casino_merge.sql` (wallets, spins, daily bonus, admin adjust).
   Do **not** apply a conflicting standalone `profiles` migration against the
   shared production database.
3. To make a user an admin:
   ```sql
   update public.profiles set is_admin = true where username = 'your_username';
   ```
   Admins can visit `/admin` to manage users and balances.
4. Email confirmations: for local testing you can disable "Confirm email"
   under Authentication → Providers → Email, or confirm via the dashboard.
