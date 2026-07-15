# Psychology service setup

Env vars (put in a local `.env`, gitignored):

```
SUPABASE_URL=
SUPABASE_SERVICE_KEY=
POLL_INTERVAL=60
```

`SUPABASE_SERVICE_KEY` must be the service-role key (bypasses RLS) so the
poller can read `hope_telemetry` and write `psychology_profiles` /
`player_anomalies` (migration `034_player_anomalies.sql`).
