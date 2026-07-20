# Put the game on your phone (super simple)

You do **not** need the App Store.

## Option A — One click (GitHub Pages) ← updated 2026-07-17

1. On your phone open:  
   **https://joeholloway445-maker.github.io/CATSINO.CASINO/**
2. Tap **Play Offline** → **Play Prototype Spine**.

That’s the **2026-07-20** Pages rebuild (mobile play fixes from PR #71).
Hard-refresh (or clear site data) if you still see an older build.

If GitHub Pages is unset on the repo:  
Settings → Pages → Branch **`gh-pages`** → folder **`/`** → Save → wait 1–2 min.

## Option B — Your domain

You want the phone to open something like **`https://play.catsino.casino`**.

1. Rebuild locally: `bash scripts/export_web.sh` (needs Godot 4.3 + Web templates).
2. Upload everything in `builds/html5/` (keep `_headers`) to the subdomain’s
   public web folder on GoDaddy / Hostinger / Cloudflare / Netlify.
3. Open `https://play.catsino.casino` → **Play Offline** → **Play Prototype Spine**.

I **cannot** finish wiring `play.catsino.casino` without your hosting login —
that domain is still a parked page from here.

## Option C — Desktop Godot (full art)

For the complete visual set (OSM city shells, music, HDRI, PeriHumans):

1. Install newest stable **Godot 4.x** (4.3+).
2. Open `godot/project.godot`.
3. Press F5 → **Play Offline** → **Play Prototype Spine**.

## Older zip

[prototype-web-v0.1](https://github.com/joeholloway445-maker/CATSINO.CASINO/releases/tag/prototype-web-v0.1)
is the Jul 15 HTML5 tarball. Prefer Option A (live Pages) unless you need an
offline zip.

## Screenshot walkthrough

See **[`docs/PROTOTYPE_VIEW.md`](PROTOTYPE_VIEW.md)** for the 2026-07-17
in-engine tour (title, layers, arena, Paws Vegas, casino).
