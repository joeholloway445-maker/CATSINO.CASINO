# Put the game on your phone (super simple)

You do **not** need the App Store.

I already built the game and uploaded it here:  
**https://github.com/joeholloway445-maker/CATSINO.CASINO/releases/tag/prototype-web-v0.1**

I **cannot** finish putting it on `play.catsino.casino` from this computer — that site is still a GoDaddy “parked” page, and I don’t have your hosting login/password.

---

## Option A — One click (GitHub Pages)

1. Open: https://github.com/joeholloway445-maker/CATSINO.CASINO/settings/pages  
2. Under **Branch**, pick **`gh-pages`** → folder **`/`** → Save.  
3. Wait 1–2 minutes.  
4. On your phone open:  
   `https://joeholloway445-maker.github.io/CATSINO.CASINO/`  
5. Tap **Play Offline** → **Play Prototype Spine**.

(If the game stuck-loads, your host must send special security headers. Then use Option B.)

---

## Option B — Your domain (what you said you have)

You want the phone to open something like **`https://play.catsino.casino`**.

1. Download the zip from the release link above.  
2. Unzip it (you’ll see `index.html`, `index.wasm`, `index.pck`, …).  
3. In GoDaddy / Hostinger **File Manager**, open the folder for `play.catsino.casino` (or create that subdomain first).  
4. Upload **all** those unzipped files into the public web folder (`public_html` / `www`).  
5. Make sure HTTPS is on for that subdomain.  
6. On your phone open: `https://play.catsino.casino`  
7. **Play Offline** → **Play Prototype Spine**.

If you use **Cloudflare** or **Netlify**, keep the `_headers` file in that folder (it sets the headers Godot needs).

---

## Option C — Tell me your hosting login (or invite me)

If you add Hostinger/GoDaddy/Cloudflare access (or paste a deploy token into the repo secrets), I can upload and wire DNS for you next.

---

## What I already did for you

- Built the browser game  
- Uploaded release `prototype-web-v0.1`  
- Pushed a `gh-pages` branch with the files  
- Fixed deploy scripts so VPS deploy uses `builds/html5`
