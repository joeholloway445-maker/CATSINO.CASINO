# Nakama client — original implementation

This is **not** a copy of Heroic Labs' official `nakama-godot` client. It's
an original GDScript implementation written against Nakama's public,
documented server API (REST endpoints under `/v2/...` and the realtime
WebSocket JSON protocol), sized to match exactly the call surface this
project's managers already code against (`AccountManager`,
`SocialManager`, `ChatManager`, `PresenceManager`).

## Confidence levels

Written and reasoned through carefully, but **never run against a live
Nakama server** (no Godot editor or server available in the environment
this was authored in). Before relying on this in production, smoke-test
each path against a real `nakama` container:

**High confidence** (stable, extremely well-documented, low risk):
- `/v2/account/authenticate/{device,email,custom}`
- `/v2/account/session/refresh`
- `/v2/account` (GET/PUT)
- `/v2/rpc/{id}` — body is a **JSON-encoded string** (payload double-wrapped;
  see `rpc_async`)
- `/v2/storage` (PUT write)
- Realtime WS handshake (`/ws?token=...`) and the `match_join` /
  `match_data_send` / `match_data` / `status_update` /
  `status_presence_event` envelope shapes — this is the path
  `PresenceManager` actually depends on today.

**Medium confidence** (recalled from the API, not verified live — test
these specifically before shipping):
- `/v2/storage/get` (read specific objects by id)
- `/v2/friend` (list/add/delete) and `/v2/group*` (create/join/leave/add
  users/list) REST paths and query-param shapes
- `channel_join` / `channel_message_send` / `channel_message` realtime
  envelope field names

If a live server rejects a call, the fix is almost always a field or path
name — the surrounding GDScript (session handling, JWT decode, exception
wrapping, socket driver) is solid.

## Swapping in the official client later

If/when the official `heroiclabs/nakama-godot` addon is added (e.g. via
the Godot editor's AssetLib), it can replace this folder outright —
`AccountManager._init_nakama_client()` just does
`load("res://addons/nakama-godot-4/Nakama.gd")` and calls
`NakamaClient.create_client(...)`, so as long as the replacement exposes
the same static factory, nothing else in the codebase needs to change.
