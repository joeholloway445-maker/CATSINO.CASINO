# Environment variables

Copy these into a local `.env.local` (which is gitignored).

```
# Supabase
NEXT_PUBLIC_SUPABASE_URL=
NEXT_PUBLIC_SUPABASE_ANON_KEY=
```

## Supabase setup

1. Create a project at [supabase.com](https://supabase.com).
2. Copy the **Project URL** and **anon/public key** from Settings → API into the
   variables above.
3. Apply `supabase/migrations/001_initial_schema.sql` via the Supabase SQL editor
   or the Supabase CLI (`supabase db push`). This creates:
   - `profiles` — username + admin flag, auto-created on signup
   - `wallets` — Cat Coins balance, XP, daily streak (starts at 10,000 coins)
   - `spins` — full spin history for every game
   - `spin_slot(game, bet)` — atomic, server-side RNG slot function
   - `claim_daily_bonus()` — daily login reward
   - `admin_adjust_coins(user_id, amount)` — admin-only balance adjustment
4. To make a user an admin, run in the SQL editor:
   ```sql
   update public.profiles set is_admin = true where username = 'your_username';
   ```
   Admins can then visit `/admin` to manage users and balances.
5. Email confirmations: for local testing you can disable "Confirm email" under
   Authentication → Providers → Email, or confirm via the Supabase dashboard.
