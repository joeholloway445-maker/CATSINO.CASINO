# CATSINO.CASINO

A neon cyber-cat **social casino MVP**, built with Next.js 16 + Supabase.

This is **entertainment only**: a free-to-play virtual coin economy ("Cat Coins").
There is no real-money gambling, no purchases, no sweepstakes, no redemption, and
no cash-out path of any kind.

## What's in this MVP

- **Auth** — sign up / sign in via Supabase Auth, with a profile auto-created on signup.
- **Cat Coins economy** — every new player starts with 10,000 Cat Coins.
- **Purr Play Slots** — a fully playable 3-reel slot machine. The RNG and balance
  updates run server-side (Postgres function `spin_slot`) so the result can't be
  tampered with from the client.
- **Daily bonus** — a streak-based daily login reward.
- **Dashboard** — balance, XP, daily streak, game lobby, and recent spin history.
- **Admin panel** (`/admin`) — for users with `profiles.is_admin = true`: view all
  players and manually adjust Cat Coin balances.
- **Neon cat branding** — black background with neon purple/cyan/green/pink, glowing
  text, and a cyber-cat aesthetic across every page.

Other branded games (Black Cat 21, 9 Lives Hold 'Em, Lucky Cat Jackpot, Catnip Cash,
Whisker Wins, Feline Fortune) are listed in the lobby as "coming soon" — the lobby
and economy layer are built so adding each one is just a new game route + a new
`spin_*`/game function.

## Getting started

```bash
npm install
cp ENV_SETUP.md .env.local   # then fill in your Supabase keys, see ENV_SETUP.md
npm run dev
```

Open [http://localhost:3000](http://localhost:3000).

## Stack

- Next.js 16 (App Router) + React 19 + TypeScript
- Tailwind CSS 4 (custom neon cat theme in `app/globals.css`)
- Supabase (Postgres + Auth) — schema in `supabase/migrations/001_initial_schema.sql`

## Roadmap (intentionally not built yet)

- Stripe / payments
- Sweeps coins, redemption, AMOE, legal sweepstakes pages
- Referral system & Reddit growth automation
- VIP tiers, live ops events, analytics dashboards
- Additional slot/table games beyond Purr Play Slots
