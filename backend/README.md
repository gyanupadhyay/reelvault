# ReelVault Backend

Node + Express. Defaults to **SQLite** for zero-config local dev; flips to **Postgres** automatically if `DATABASE_URL` is set.

## Setup

```bash
cd backend
npm install
npm run init-db   # creates schema
npm run seed      # inserts 5 series, 25 episodes, 25 reels
npm start         # http://localhost:3000
```

For Postgres: `DATABASE_URL=postgres://user:pass@host/db npm run init-db && npm run seed && npm start`.

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
