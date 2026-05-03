# ReelVault

Short-form video discovery app. Scroll reels, dive into series, watch episodes with progress sync and offline support.

```
reelvault/
├── backend/         Node + Express + (SQLite | Postgres) — deployed on Render
├── frontend/        Flutter (iOS + Android), Bloc + go_router + get_it
├── ARCHITECTURE.md  Layers, controller lifecycle, sync model, scope cuts
└── README.md        ← you are here
```

## Quick start (already deployed)

The backend is live at **https://reelvault-umr4.onrender.com**, fronted by Render's free tier with managed Postgres and HTTPS. The Flutter app's default `API_BASE_URL` already points at it.

```bash
cd frontend
flutter pub get
dart run build_runner build --delete-conflicting-outputs
flutter run                  # talks to the live backend, zero flags needed
```

> **Render free-tier sleep.** The web service spins down after 15 min idle. First request after sleep takes ~30s. Hit `https://reelvault-umr4.onrender.com/health` once before a demo to wake it up; the device's reel-fetch keeps it warm for the rest of the session.

To run against a local backend instead, see [section 2](#2-run-the-flutter-app).

---

## 1. Run the backend (optional — only for backend dev)

Most users **don't need this**. The deployed Render backend is already serving every endpoint and the Flutter app's default URL points at it. Skip to [section 2](#2-run-the-flutter-app) unless you're modifying server-side code.

If you want to run the backend locally:

Requirements: Node **18+** (Node 20 LTS or 22 LTS recommended; Node 24 also works with the prebuilt binaries we depend on).

### macOS / Linux (bash, zsh)

```bash
cd backend
npm install
npm run init-db     # creates reelvault.db (SQLite)
npm run seed        # 5 series × 5 episodes + 25 reels
npm start           # http://localhost:3000
```

> **Seed safety guard.** `seed.js` wipes every table on each run. To prevent accidental prod data loss, it refuses to run when `NODE_ENV=production` unless `ALLOW_DESTRUCTIVE_SEED=1` is also set. Local dev (no `NODE_ENV` set) runs unblocked.

Verify:

```bash
curl http://localhost:3000/health
# {"ok":true,"driver":"sqlite"}

curl 'http://localhost:3000/reels?limit=3'
# {"items":[...3 reels...],"next_cursor":3}
```

To use Postgres instead: `DATABASE_URL=postgres://... npm run init-db && npm run seed && npm start`.

### Windows (PowerShell)

Windows PowerShell 5.1 (the default) does **not** support `&&`, so run each step separately:

```powershell
cd backend
npm install
npm run init-db
npm run seed
npm start
```

In PowerShell, the name `curl` is an alias for `Invoke-WebRequest`, which prints a wrapped object instead of the body. Use `curl.exe` (shipped with Windows 10+) or `Invoke-RestMethod`:

```powershell
curl.exe http://localhost:3000/health
# {"ok":true,"driver":"sqlite"}

Invoke-RestMethod 'http://localhost:3000/reels?limit=3'
```

For Postgres, set `DATABASE_URL` for the current session before running each step:

```powershell
$env:DATABASE_URL = "postgres://user:pass@host:5432/reelvault"
npm run init-db
npm run seed
npm start
```

> **Heads up — `better-sqlite3` on Windows.** This project uses `better-sqlite3@^12`, which ships prebuilt binaries for Node 18, 20, 22, and 24 on Windows x64. If your Node version doesn't have a prebuild, npm falls back to compiling from source via `node-gyp`, which on Windows additionally needs Python with `setuptools` and Visual Studio C++ build tools. The simplest fix is to switch to a Node LTS (e.g. 20.18.x) via [`nvm-windows`](https://github.com/coreybutler/nvm-windows). See [Troubleshooting](#troubleshooting) below.

---

## 2. Run the Flutter app

```bash
cd frontend
flutter pub get
dart run build_runner build --delete-conflicting-outputs   # generates Drift code
flutter run
```

### Backend URL by platform

The app reads `API_BASE_URL` at compile time. **Default is the deployed Render backend** — `https://reelvault-umr4.onrender.com` — so a fresh `flutter run` works on any device with no extra flags. Override only when pointing at a local backend.

| Target | Command |
|---|---|
| **Default (deployed)**   | `flutter run` (uses live Render URL) |
| Android emulator → local | `flutter run --dart-define=API_BASE_URL=http://10.0.2.2:3000` |
| iOS simulator → local    | `flutter run --dart-define=API_BASE_URL=http://localhost:3000` |
| Real device → local      | `flutter run --dart-define=API_BASE_URL=http://<your-LAN-ip>:3000` |

To find your LAN IP: `ipconfig getifaddr en0` (macOS) or `hostname -I` (Linux) or `ipconfig` (Windows).

> **`AndroidManifest.xml`** keeps `android:usesCleartextTraffic="true"` so the LAN-IP override paths still work for local-backend dev. Production traffic uses HTTPS — the cleartext flag isn't actually used unless you override to an `http://` URL.

---

## 3. How to test the spec requirements

### Reel feed performance
- Open the app — first reel autoplays.
- Swipe up/down — neighbors are already buffered, no spinners.
- Rapid-fire swipe through 10 reels — only the final one starts playing (scroll-settle works).
- DevTools → Performance tab → record while scrolling. Frames should stay under 16ms (60fps).

### Controller count (the 30% piece)
The pool is forward-only (`{active, active+1}`), so it never holds more than 2 controllers in steady state. The existing `[pool]` debug logs print the window on every transition:

```
[pool] active=N  size=2  window=[N, N+1]  +created=[N+1]  -disposed=[N-1]
```

Scroll through 50+ reels and grep `flutter logs` for `[pool]`. `size=2` throughout. The reasoning (decoder oversubscription on Qualcomm SoCs) is in `ARCHITECTURE.md` under "Reel feed — controller lifecycle."

### Series navigation + scroll preservation
- Scroll to reel 7. Tap the playlist icon. Series view opens.
- The episode that reel was a preview of is highlighted with a tinted background and a "From reel" badge.
- Tap any episode. Player opens.
- Back back back to feed — you're still on reel 7.

### Series header info
- The header shows `5 episodes · ~22 min total` (sum of `episode.duration_sec`).

### Player controls
- Tap the video to toggle controls. The control overlay shows: ⏮️ prev episode · ⏪ -10s · ▶️/⏸️ · ⏩ +10s · ⏭️ next episode (centered), and `0.5x–2x` speed picker + ⛶ fullscreen toggle (top-right).
- Below the seek bar: elapsed time on the left (`1:23`), remaining time on the right (`-2:45`).
- Double-tap left/right half of the video for ±10s seek.
- ⛶ rotates the device to landscape and hides system UI; tap again to exit.
- ⏮️/⏭️ are greyed out at the first/last episode of the series.

### Watch progress persistence
- Open ep 1, watch ~30 seconds, hit back.
- Force-quit the app from the OS task switcher.
- Reopen. Tap that ep again — resumes within a few seconds of where you left off.

### Backend monotonic guard

Replace `$BASE` with either the deployed URL (`https://reelvault-umr4.onrender.com`) or your local backend (`http://localhost:3000`):

```bash
BASE=https://reelvault-umr4.onrender.com   # or http://localhost:3000

curl -X PUT $BASE/progress/ser_01_ep1 \
  -H 'content-type: application/json' \
  -d '{"progress_seconds": 100}'
# {"progress_seconds":100,...}

curl -X PUT $BASE/progress/ser_01_ep1 \
  -H 'content-type: application/json' \
  -d '{"progress_seconds": 50}'
# {"progress_seconds":100,...}   ← did NOT regress to 50
```

### Offline mode
- Tap the download icon on an episode in the series view. Watch the spinner fill.
- When the green check appears, turn off wifi + cellular (or use airplane mode).
- Tap the same episode. It plays from local file, zero network.
- Try a non-downloaded episode. App shows a clear "You're offline and this episode isn't downloaded" screen with a back button — no crash, no infinite spinner.
- To free space: open the series, tap the "delete sweep" icon in the app bar to remove every download for that series in one tap (with a confirm dialog). Or per-episode via the green check icon.

### Offline → online sync
- Stay in airplane mode. Watch a downloaded episode for 60 seconds. Quit player.
- Inspect: `select * from progress_local where synced=0;` (use any sqlite browser on the device file, or just check via debug).
- Re-enable network. Within a couple of seconds, `synced` flips to 1 and the server has the new progress.

### Background → foreground
- Start a reel playing. Press home button. Wait 30 seconds.
- Bring the app back. Reel resumes from where it paused, no audio artifacts.
- Then: open an episode in the player, press home, return — the player resumes (the feed below stays paused, no audio bleed). The feed's lifecycle observer is route-aware and won't auto-resume when the player is the topmost route.

### Continue Watching
```bash
curl https://reelvault-umr4.onrender.com/continue-watching
# Or against local: curl http://localhost:3000/continue-watching
# Returns episodes you've started but not finished, ordered by recency.
```
In the app, tap the 🕘 history icon on the right rail of the reel feed. You'll see a list of in-progress episodes (sorted by most recently watched), each with a progress bar and `mm:ss / mm:ss` indicator. Tap any row to resume directly in the player.

The series-detail screen also has a "Continue Ep N" CTA that picks up the most recent in-progress episode for that specific series.

### Force-kill durability
- Watch ep 2 for 4 minutes.
- Kill the app from the task switcher (NOT just background — actual force-kill).
- Reopen, navigate to ep 2 — resumes within ~5 seconds of where you stopped (5s is the periodic-save interval).
- Variant: **background first, then force-kill from the task switcher.** The player's lifecycle observer fires a synchronous flush on `AppLifecycleState.paused`, so resume is at the exact second you backgrounded — zero loss in this common path.

---

## 4. Build a release APK

The deployed backend URL is the default, so no `--dart-define` is required:

```bash
cd frontend
flutter build apk --release
```

Output: `build/app/outputs/flutter-apk/app-release.apk`. Distribute via Firebase App Distribution, Drive link, or sideload.

To target a different backend (staging, local), pass the override:

```bash
flutter build apk --release --dart-define=API_BASE_URL=https://your-staging-backend.com
```

### Deploying your own backend (Render free tier)

The current backend is hosted on Render. To replicate from scratch:

1. **GitHub push** the repo.
2. **Render → New Postgres** (Free plan). Copy the *External Database URL*.
3. **Render → New Web Service** → connect repo → Root Directory `backend` → Build `npm install` → Start `npm start`. Add env vars:
   - `DATABASE_URL` = External Postgres URL
   - `NODE_ENV` = `production`
   - `REELVAULT_MEDIA_BASE` = `https://<your-render-url>/static/videos`
4. **Initialize schema + seed** by running locally against the remote DB (Render free tier blocks Shell):

   ```bash
   cd backend

   # Init schema — idempotent, safe to re-run.
   DATABASE_URL='<external-postgres-url>' \
   REELVAULT_MEDIA_BASE='https://<your-render-url>/static/videos' \
     node src/init-db.js

   # Seed data — destructive (wipes tables). The prod-guard refuses to run
   # if NODE_ENV=production is set, so override with ALLOW_DESTRUCTIVE_SEED=1
   # for the first-time seed of a fresh prod DB.
   DATABASE_URL='<external-postgres-url>' \
   REELVAULT_MEDIA_BASE='https://<your-render-url>/static/videos' \
   ALLOW_DESTRUCTIVE_SEED=1 \
     node src/seed.js
   ```

   > Why `ALLOW_DESTRUCTIVE_SEED=1` is needed: if your shell has `NODE_ENV=production` exported (or you're running this from a CI environment that sets it), the guard added in `seed.js` will refuse the run to protect live data. Without `NODE_ENV=production` set, the guard is inert and the variable isn't required.

5. **Update** `frontend/lib/core/di/service_locator.dart`: change `defaultValue` on the `kBaseUrl` constant to your new URL, or pass `--dart-define=API_BASE_URL=...` at build time.

`db.js` auto-enables SSL for managed Postgres providers (Render, Heroku, Neon, Supabase, Railway, Fly), so no extra config is needed.

---

## 5. What's not done (scope cuts, called out in ARCHITECTURE.md)

- Picture-in-picture (P2 in spec)
- Category filtering / search (P2)
- Pull-to-refresh on reel feed (P2)
- Series-level "download all" button (per-episode works; bulk *delete* is implemented)
- Real auth — uses `x-user-id: demo-user`

---

## 6. Troubleshooting

### `npm install` fails on Windows with `Cannot find module 'better-sqlite3'` after a long node-gyp error

You're on a Node version with no prebuilt `better-sqlite3` binary, and the source-compile fallback failed. Common root causes:

- **Python 3.12+ removed `distutils`**, which the bundled `node-gyp@9` imports. Symptom: `ModuleNotFoundError: No module named 'distutils'`.
- **No Visual Studio C++ build tools installed** on the machine.
- **Files locked under `node_modules\better-sqlite3`** from a previous failed install (`EPERM ... rmdir`).

Fixes, in order of preference:

1. **Use a Node LTS that has prebuilds** (recommended). With [nvm-windows](https://github.com/coreybutler/nvm-windows):

   ```powershell
   nvm install 20.18.1
   nvm use 20.18.1     # needs an elevated PowerShell on Windows
   ```

2. **Force a clean reinstall** if a prior install left files locked:

   ```powershell
   Get-Process node -ErrorAction SilentlyContinue | Stop-Process -Force
   Remove-Item -Recurse -Force node_modules, package-lock.json -ErrorAction SilentlyContinue
   npm install
   ```

3. **If you must compile from source** (e.g. uncommon Node version), restore the missing tooling:

   ```powershell
   python -m pip install setuptools     # brings distutils back under Python 3.12+
   npm install -g node-gyp@latest       # newer node-gyp doesn't import distutils
   npm install
   ```

   You'll also need Visual Studio 2022 with the "Desktop development with C++" workload.

### `The token '&&' is not a valid statement separator in this version`

Windows PowerShell 5.1 doesn't support `&&` for command chaining. Either run each command on its own line, use `;` (always runs next, regardless of failure), or upgrade to PowerShell 7+:

```powershell
winget install --id Microsoft.PowerShell --source winget
# then use `pwsh` instead of `powershell`
```

### `curl http://localhost:3000/health` prints a wrapped HTTP object instead of JSON

In PowerShell, `curl` is aliased to `Invoke-WebRequest`. Use `curl.exe` for real curl, or `Invoke-RestMethod` for parsed JSON:

```powershell
curl.exe http://localhost:3000/health
Invoke-RestMethod http://localhost:3000/health
```

### Port 3000 is already in use

Find and stop the owning process:

```powershell
Get-NetTCPConnection -LocalPort 3000 |
  Select-Object -ExpandProperty OwningProcess -Unique |
  ForEach-Object { Stop-Process -Id $_ -Force }
```

```bash
# macOS / Linux
lsof -ti:3000 | xargs kill -9
```

---

## 7. Where to look

| Concern | File |
|---|---|
| Controller lifecycle (the hardest piece) | `frontend/lib/presentation/reel_feed/video_controller_pool.dart` |
| Scroll-settle debounce | `frontend/lib/presentation/reel_feed/reel_feed_screen.dart` (`_onPageChanged`) |
| Monotonic progress (client) | `frontend/lib/data/repositories/repositories_impl.dart` (`ProgressRepositoryImpl.saveProgress`) |
| Monotonic progress (server) | `backend/src/server.js` (`upsertProgress`) |
| Offline → online sync | `frontend/lib/core/di/service_locator.dart` (the connectivity listener at the bottom) |
| Cold-start offline detection | `frontend/lib/core/network/connectivity_service.dart` (`checkConnectivity()` seed in constructor) |
| Resumable downloads | `frontend/lib/data/repositories/download_repository_impl.dart` |
| Bulk-delete series downloads | `frontend/lib/presentation/series/series_bloc.dart` (`DeleteAllSeriesDownloads`) |
| Player: fullscreen, prev/next, time labels, offline error | `frontend/lib/presentation/player/player_screen.dart` |
| "From reel" episode highlight | `frontend/lib/presentation/series/series_screen.dart` (`fromEpisodeId` + `_EpisodeTile.fromReel`) |
| Continue Watching screen | `frontend/lib/presentation/continue_watching/continue_watching_screen.dart` |
| Routing + bloc scoping | `frontend/lib/core/router/app_router.dart` |
