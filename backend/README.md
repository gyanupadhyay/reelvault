# ReelVault Backend

Node + Express. Defaults to **SQLite** for zero-config local dev; flips to **Postgres** automatically if `DATABASE_URL` is set. Reel and episode video URLs are served from Pexels CDN — the backend stores URLs only, no mp4 hosting.

## Setup

```bash
cd backend
npm install
npm run init-db                       # creates schema
PEXELS_API_KEY=your_key npm run seed  # inserts 5 series, 25 episodes, 25 reels
npm start                             # http://localhost:3000
```

For Postgres: `DATABASE_URL=postgres://... PEXELS_API_KEY=your_key npm run seed`.

The seed needs a free Pexels API key — sign up at <https://www.pexels.com/api/> (no card, instant). Per-series themed queries (space, city, ocean, workshop, cooking) fetch episode-length (2–10 min) and reel-length (15–60s) videos and store the Pexels CDN URLs directly. Responses are cached to `.cache/pexels.json` so re-seeds work offline / without a key.

## Env vars

| Var | Purpose |
|---|---|
| `DATABASE_URL` | If set, use Postgres; otherwise SQLite at `backend/reelvault.db`. |
| `PORT` | HTTP port. Default `3000`. |
| `PEXELS_API_KEY` | Required only when seeding (not at runtime). |
| `NODE_ENV` | If `production`, the seed refuses to run unless `ALLOW_DESTRUCTIVE_SEED=1` is also set — protects live data from accidental wipes. |
| `ALLOW_DESTRUCTIVE_SEED` | `1` to bypass the prod-guard. Only needed when seeding *on* a process where `NODE_ENV=production` is exported (Render shell, CI). |
| `PGSSL` | `true` / `false` to override SSL behaviour. By default, SSL auto-enables for managed Postgres hosts (Render, Heroku, Neon, Supabase, Railway, Fly). |

## Endpoints

All endpoints accept an optional `x-user-id` header. Defaults to `demo-user`.

| Method | Path | Purpose |
|---|---|---|
| GET | `/health` | liveness + driver info |
| GET | `/reels?cursor=0&limit=20` | paginated reel feed |
| GET | `/series/:id` | series detail + episodes + per-episode progress |
| GET | `/progress/:episodeId` | get progress for one episode |
| PUT | `/progress/:episodeId` | save progress (monotonic — never decreases) |
| POST | `/progress/bulk-sync` | offline batch sync, returns resolved values |
| GET | `/continue-watching` | in-progress episodes for the user |

## Conflict resolution

The server enforces monotonic progress: on every write, it takes `max(existing, incoming)` for `progress_seconds`, the later `last_watched_at`, and OR's the `completed` flag. This is what the spec calls out as "must not break: progress must never go backwards." The same logic powers `bulk-sync` so offline-accumulated progress is safe to push.

## Smoke test

```bash
curl localhost:3000/health
curl 'localhost:3000/reels?limit=5'
curl localhost:3000/series/ser_01
curl -X PUT localhost:3000/progress/ser_01_ep1 \
  -H 'content-type: application/json' \
  -d '{"progress_seconds": 120, "completed": false}'
curl localhost:3000/progress/ser_01_ep1
curl localhost:3000/continue-watching
```
