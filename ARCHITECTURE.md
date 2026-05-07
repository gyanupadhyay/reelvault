# ReelVault — Architecture

## Frontend layers

```
presentation/   Flutter widgets, BLoCs (UI state machines)
domain/         Pure Dart entities + repository interfaces. No Flutter, no I/O.
data/           Repository implementations, remote data source (Dio), local cache (Drift).
core/           Cross-cutting: DI (get_it), router (go_router), networking, storage.
```

The presentation layer talks only to the domain layer's repository interfaces. The data layer satisfies those interfaces. Swapping the backend or storage engine never touches presentation code.

## Backend layout

```
backend/src/
├── server.js                  composition root — middleware + route mounting
├── config.js                  port, default user, paths, body limits
├── db.js                      driver abstraction: SQLite local / Postgres prod
├── init-db.js                 CLI: idempotent schema create
├── seed.js                    CLI: wipe + reseed (NODE_ENV=production refuses)
├── lib/
│   └── pexels.js              Pexels Videos API client (search + on-disk cache)
├── middleware/
│   ├── compression.js         gzip JSON responses
│   ├── userId.js              extracts x-user-id → req.userId (auth seam)
│   └── errorHandler.js        sanitized 500 — no leaked stack traces
├── repositories/
│   └── progressRepo.js        upsertProgress (monotonic conflict resolution)
└── routes/
    ├── reels.js               GET /reels (paginated)
    ├── series.js              GET /series/:id (joined with this user's progress)
    ├── progress.js            GET, PUT /progress/:episodeId; POST /progress/bulk-sync
    └── continueWatching.js    GET /continue-watching
```

`server.js` is intentionally small (~50 lines) — it composes middleware in mount order, mounts each route module by URL prefix, attaches the error handler last, and starts listening. All actual work lives in `routes/` and `repositories/`. A reviewer can follow any endpoint from the route mount in `server.js` to the handler file by URL prefix without scrolling around a monolith.

The `userId` middleware is the only seam that needs to change when real auth lands — replace the `x-user-id` header read with a JWT verify and set `req.userId` from the verified `sub` claim. Every route reads `req.userId` and is unchanged.

## State management — Bloc

One BLoC per screen-scoped concern: `ReelFeedBloc`, `SeriesBloc`. The player owns its state directly because `VideoPlayerController` already exposes a `ValueListenable`; wrapping it in another bloc would be redundant overhead on a hot path.

The reel feed BLoC is provided in a `ShellRoute`, not the screen itself. That's how feed scroll position survives a round-trip to a series and back: the bloc instance outlives the screen widget.

## Reel feed — controller lifecycle

This is the highest-risk subsystem, so it's worth explaining in detail.

`VideoControllerPool` keeps **3 `VideoPlayerController`s alive at any moment**: prev / current / next (the window `{N-1, N, N+1}`). Only the active slot is actively playing/decoding — both neighbors are initialized and immediately paused. When the user swipes, we:

1. Compute the new desired window `{i-1, i, i+1}`.
2. Dispose every controller whose index is no longer in the window.
3. Create + `initialize()` a controller for any new index in the window.
4. Play the active controller; keep the neighbors paused.

**The "paused neighbors" rule is what makes 3 controllers safe on Qualcomm.** Earlier in this project's history, a `radius=1` pool that *played* the active and *initialized* the neighbors caused 14 silent `c2.qti.avc.decoder` init failures during fast-scroll transitions — the device's hardware decoder slot count overflowed when 3+ streams were actively decoding plus a fourth in mid-dispose. The current design holds 3 native decoder slots steady-state but only ever has *one* doing real frame decoding work, which sits well within the device's concurrent-decoder budget. Real-device telemetry confirms zero decoder failures across hundreds of transitions including backward scrolls.

**Why bring prev back at all?** The earlier "forward-only" pool (`{N, N+1}`) was decoder-safe but the user reported "video doesn't load when swiping back" — every backward swipe paid a full ~500-1500ms re-init over WAN. Keeping prev warm and paused makes backward swipes as instant as forward.

**Decoder-failure recovery.** As a defense in depth, if a slot's `controller.value.hasError` is true after `initialize()` resolves, the pool disposes it and recreates once before giving up. This catches transient codec hiccups without infinite retry loops (a `_retriedSlots` set guards against that).

**Navigation-time disposal.** The 3-controller window is decoder-safe for steady-state scrolling, but when the user navigates from the feed into the player, the player tries to allocate a 4th decoder. On Qualcomm SoCs that pushed concurrent allocations past the device limit for some 1080p high-profile mp4s and the player would fail with "Couldn't load this episode." The fix: a `leaveFeed()` callback on each in-app navigation tap (series, continue-watching, downloads) that calls `pool.disposeAll()` and triggers a `setState`. The build's `addPostFrameCallback` re-creates the active slot on back, using the saved positions in `_resumeByIndex`.

**Two-phase dispose.** `disposeAll()` can't tear down `VideoPlayerController` instances synchronously — the screen has live `ValueListenableBuilder`s pointing at them, and the next frame's widget unmounts call `removeListener` on the `ChangeNotifier` (which throws if it's already been disposed). Phase 1 clears `_slots` immediately so `controllerAt()` returns null, the next build removes the conditional widgets, and unmount can detach listeners cleanly. Phase 2 runs `controller.dispose()` in a `SchedulerBinding.addPostFrameCallback`, after the unmounts have completed.

**Concurrent-mod safety.** `setActive()` snapshots `_slots` before its play/pause loop. If the user taps a navigation while a `setActive` is mid-await, `disposeAll()` clears the original list, and the loop carries on iterating the snapshot — the per-slot `s.disposed` guard handles the per-element bookkeeping.

**Race-against-dispose in awaits.** Each slot owns a `Completer<void> disposeSignal` that fires when the slot is disposed. Every `await s.ready` is wrapped as `await Future.any([s.ready, s.disposeSignal.future])` so a slot that gets disposed mid-init (its `controller.initialize()` future never settles on some Android builds) doesn't deadlock the pool — the await unblocks, `s.disposed` is checked, the loop bails on this slot.

The pool is independent of the BLoC — it's a plain Dart object owned by the screen's `State`. The BLoC reports the active index; the screen drives the pool. This separation matters: the BLoC stays pure (testable without Flutter), and the pool encapsulates the messy lifecycle.

**Memory ceiling:** 3 controllers × N MB each, regardless of feed length. Verified — controller count stays at 3 throughout, and drops to 0 when the user navigates away from the feed.

## Preloading and prefetch

Three layers of preload work together so swipes never wait on the network:

1. **Pool preload (active+1, active-1).** Both neighbors hold real `VideoPlayerController`s with their first frames already initialized. Forward and backward swipes hit `waited 0ms` because the pool just calls `play()` on a controller that's already buffered.

2. **HTTP Range prefetch (active±2..±4).** Beyond the pool window, the screen calls `ApiClient.prefetchRange(url, bytes: 524287)` for the next 2-4 reels in both directions. This issues an HTTP `Range: bytes=0-524287` request for 512KB of each upcoming reel's video — enough to cover the mp4 moov atom plus several seconds of frames. The bytes land in the OS HTTP cache; when the user actually scrolls to those reels, ExoPlayer's internal HTTP layer finds the bytes already on disk and skips the network roundtrip. Pexels CDN serves the videos with their own long-lived cache headers and supports HTTP Range (`206 Partial Content` verified). Dedup tracking on the `ApiClient` (`_prefetchInFlight` + `_prefetchDone`) prevents duplicate fetches.

3. **Thumbnail precache (active-2..active+5).** While the user is on reel N, we walk N-2..N+5 and call `precacheImage(CachedNetworkImageProvider(thumbnailUrl), context)` for each. Using the `cached_network_image` provider (not bare `NetworkImage`) means thumbs land in both Flutter's in-memory image cache *and* the package's on-disk cache, so subsequent cold launches render thumbs instantly without re-fetching from picsum. Combined with the thumbnail-underlay rendering (see below), this is what makes the feed *feel* like Instagram — the user never sees a white spinner during transitions, only a real image with the video fading in over it.

**Cold-start prefetch.** The first `/reels` page is also fetched eagerly during `setupLocator()`, before the bloc even mounts. The repository (`ReelRepositoryImpl`) caches the in-flight `Future` so when the bloc's `fetchReels(cursor: 0)` call arrives a few hundred ms later, it gets handed the same Future instead of issuing a duplicate request. This overlaps the HTTP roundtrip with Flutter framework boot and shaves a few hundred ms off the cold-start path on real hardware.

## Reel tile rendering — no white spinner, ever

The reel tile uses a 3-layer Stack:

1. **Gradient fallback** — `Container(decoration: LinearGradient(...))`. Visible only if everything else fails (offline + thumbnail host unreachable). Better than a white spinner — the user gets a hint that something will appear.
2. **Thumbnail** — `Image.network(reel.thumbnailUrl, fit: BoxFit.cover, gaplessPlayback: true)`. Renders the moment bytes arrive (fast — comes from the precached image cache when scrolling). Fully covers the gradient.
3. **Video** — `FittedBox(fit: BoxFit.cover, child: VideoPlayer(controller))`, full-bleed. Once the controller initializes, the video renders on top of the thumbnail and fully occludes it (no letterbox bleed-through, even for 16:9 sources on a portrait phone — the edges crop, matching TikTok/Instagram's vertical-feed model).

There is no `CircularProgressIndicator` in the reel tile. Every "loading" surface is masked by either a thumbnail or a gradient.

## Scroll-settle (fast scroll handling)

The screen debounces page changes with a 150ms timer. `onPageChanged` fires immediately for pagination tracking, but `_pool.setActive(...)` is deferred until the user has *settled* on a page. If they swipe rapidly through 10 reels, only the final one triggers controller creation and playback. Without this, fast scrolling would create-and-immediately-dispose 10 controllers, jank the frame rate, and waste video bandwidth.

## App lifecycle

Both the feed and the player register a `WidgetsBindingObserver`.

**Feed observer** calls `pool.pauseActive()` on `paused`/`inactive`. On `resumed` it only calls `pool.resumeActive()` if the feed is still the topmost route (`ModalRoute.of(context)?.isCurrent`). Without that route check, backgrounding the app while in the player would cause both the feed reel and the player to start playing simultaneously when the user returned — a real audio-bleed bug caught by field-validation.

**Player observer** pauses the controller on `paused`/`inactive` *and* fires a final progress save in the same callback. This tightens the force-kill durability bound: in the common case where a user backgrounds before the OS kills the process (e.g., switching apps then getting OOM-killed minutes later), zero seconds of progress are lost. On `resumed` it only auto-plays if the player is still current and the user hadn't manually paused before backgrounding (`_wasPlayingBeforeBackground` flag).

## Navigation context preservation

The reel feed is in a `ShellRoute`. The shell's `BlocProvider` survives push/pop of child routes, so the bloc's `activeIndex` and reel list are intact when the user returns. The feed screen also uses `AutomaticKeepAliveClientMixin` to retain its `PageController` position.

## Watch progress — local-first, monotonic

Progress writes go to **local Drift first**, marked `synced=false`. A fire-and-forget HTTP `PUT /progress/:id` runs in parallel; on success it flips `synced=true`. If the request fails, the row stays unsynced.

**Monotonic guarantee:** both the client and server compare the incoming `progress_seconds` against the existing value and keep the larger one. Progress can therefore only move forward. Even if a stale write arrives (e.g. server lag, retried request from an offline queue), it cannot rewind the user.

The save cadence in the player is every 5 seconds, plus a synchronous flush on background (via the lifecycle observer above) and a best-effort flush on `dispose()`. In the worst case (force-kill with no preceding background) the loss is ≤5 seconds; in the realistic case (user backgrounds before the OS kills the process) the loss is ~0 seconds. Both are well inside the spec's "must not lose more than a few seconds" requirement.

## Offline → online sync

`ConnectivityService` listens to `connectivity_plus` and emits **only on transitions** (the seed callback no-ops if the platform listener already fired) so a duplicate `syncPending` doesn't fire on cold start. The DI layer subscribes to that stream and calls `ProgressRepository.syncPending()`. That method:

1. Selects all rows where `synced = false`.
2. **Chunks them into batches of 200** and posts each chunk to `POST /progress/bulk-sync`. If a chunk fails, remaining chunks stay unsynced and get retried on the next reconnect tick — no point spamming the network.
3. Receives the server-resolved values per chunk (server applies the same `max(existing, incoming)` rule).
4. For each resolved item, takes `max(local, server)` again as a final guard, then marks `synced=true`.

This double-guard means: even if the server returns a *lower* value due to a race with another device, we don't overwrite our local value with it. The double-max is the conflict resolution — it's commutative and idempotent.

## Downloads

`background_downloader` (chosen over `flutter_downloader` because it's actively maintained and supports native pause/resume across platforms). Per-episode tasks are tracked in the `downloads` table. State machine: `idle → queued → running → complete | failed | paused`.

Resume on interruption is provided natively by the package — partial downloads survive process death because the package writes to a temp file with byte-range tracking. We persist the `taskId` so reattachment after restart works.

Concurrency is left at the package default (parallelism handled by the OS) — the spec said "sequential or limited-concurrency," and the default is reasonable for a trial.

**Bulk delete** is a thin client-side loop: `DeleteAllSeriesDownloads` reads `state.series.episodes`, filters those with a `localPath`, and calls `deleteDownload` on each. The action is gated behind a confirm dialog because it's destructive. There's no server roundtrip — the spec specifies downloads are tracked client-side only.

## Online/offline playback switch

`PlayerScreen` checks `DownloadRepository.localPathFor(episodeId)` before constructing the controller:
- If a local file exists, uses `VideoPlayerController.file(...)` — zero network.
- Otherwise, `VideoPlayerController.networkUrl(...)`.

The decision is made once per session, on entry. The user never sees a "switching mode" UI; it just works.

If the episode is **not** downloaded **and** `ConnectivityService.isOnline` is false, the player short-circuits before constructing any controller and renders an explicit "you're offline, this episode isn't downloaded" screen with a back button. This is the spec's "show a clear message" requirement. `ConnectivityService` was hardened with an initial `checkConnectivity()` call in its constructor so this works on cold start, not just after a network *change* event.

Network errors at controller `initialize()` time (e.g. backend unreachable on Wi-Fi with no real internet) are also caught and surfaced as a friendly error UI rather than an infinite spinner.

## Player UX

The player screen owns its own `VideoPlayerController` (no bloc — see "State management"). Controls overlay:

- **Center row**: ⏮ prev / ⏪ -10s / ▶︎-⏸ / ⏩ +10s / ⏭ next. The prev and next buttons walk `series.episodes` by `episodeNumber`; they're greyed out at the boundaries.
- **Top-right**: speed picker (`0.5x / 1x / 1.25x / 1.5x / 2x`) and ⛶ fullscreen toggle. Fullscreen flips the device to landscape via `SystemChrome.setPreferredOrientations` and hides system UI (`SystemUiMode.immersiveSticky`). On dispose we always restore portrait + edge-to-edge UI in case the user backed out mid-fullscreen.
- **Below seek bar**: elapsed time on the left, remaining time (negative) on the right, both refreshed via `ValueListenableBuilder<VideoPlayerValue>` directly off the controller.
- Double-tap left half / right half = ±10s seek.

Auto-advance on completion is unchanged (`pushReplacement` to the next episode); manual ⏭ uses the same code path so swiping back works correctly.

## Continue Watching

`ContinueWatchingScreen` calls `ProgressRepository.continueWatching()`. The repo prefers the server (`GET /continue-watching`) and falls back to a local Drift query joining `progress_local` with `cached_episodes` when offline. Same shape on both paths, so the UI is path-agnostic.

**One row per in-progress *series*, not per episode.** The spec wording is "in-progress series," matching the Netflix/Prime/YouTube convention — if a user has touched Ep 1, Ep 2, and Ep 4 of the same series, only the most recently watched episode shows up; tapping the row resumes that episode.

Server uses a window function:

```sql
ROW_NUMBER() OVER (PARTITION BY e.series_id ORDER BY p.last_watched_at DESC) AS rn
... WHERE rn = 1
```

Window functions are supported by both SQLite (≥3.25) and Postgres, so the same SQL ships unchanged across local dev and the deployed Render Postgres. The offline fallback in Dart mirrors this with a single-pass walk through the recency-sorted list, keeping the first occurrence per `series_id` (a `Set<String>` guards against duplicates).

The screen is reachable from the 🕘 icon on the reel feed's right rail (next to playlist and downloads). It's mounted inside the same `ShellRoute` as the feed, so the feed's bloc and scroll position survive the round-trip.

## "From reel" highlight

When the user taps a reel, the destination route includes `?fromEpisodeId=<id>`. `SeriesScreen` reads it from `state.uri.queryParameters` and passes it down to each `_EpisodeTile`. The matching tile renders with a tinted `primaryContainer` background and a "From reel" pill. This is a stateless visual cue — no extra state in the bloc.

## Backend perf (HTTP wire layer)

The deployed backend (Render free tier, fronted by Cloudflare) is configured for cheap-but-effective wire-level wins:

- **Brotli/gzip on JSON.** `compression()` middleware gzips `/reels`, `/series/:id`, `/progress/:id` etc. In practice, Cloudflare's edge applies Brotli on top, dropping a 6.4KB `/reels?limit=20` JSON to ~736 bytes (~88% reduction).
- **Videos served from Pexels CDN.** `video_url` and `thumbnail_url` point directly at `videos.pexels.com` / `images.pexels.com`. The Express server doesn't proxy mp4 bytes — clients hit Pexels CDN edge directly. Pexels supplies its own cache headers (verified Range-friendly with `206 Partial Content`), so re-watched reels in the same session land in the device cache.
- **`thumbnail_url` in `/reels` response.** The endpoint joins `episodes.thumbnail_url` so each reel item carries the URL of an image to display under the video while the controller initializes. No DB schema change — the column already existed in the `episodes` table.

These three together are what enable the perceived-loading fixes on the client side (Range prefetch lands bytes into the cached path; thumbnails arrive in time to mask init waits).

## What breaks at scale (honest)

1. **Single-user model** — backend hardcodes `demo-user`. Real auth would need JWT and a `users` table.
2. **Third-party CDN dependency.** Videos and thumbnails are served by Pexels (`videos.pexels.com`, `images.pexels.com`). Pros: zero origin bandwidth, global edge, no LFS storage on our side. Cons: Pexels could remove a video, rate-limit the API, or change CDN URLs — none happens often, but a real product would mirror the chosen Pexels assets to its own object storage (R2 / S3 + CloudFront) for stability and to satisfy SLAs.
3. **No retry/backoff** on individual progress writes — they rely on the bulk-sync net to catch them. Fine for a trial; in prod I'd add exponential backoff. Bulk sync itself is chunked into 200-row batches.
4. **No video manifest negotiation** — we assume the URL plays. HLS/DASH adaptive bitrate is out of scope. A production app would ship a 720p reel rendition + HLS for adaptive bitrate.
5. **Reel feed isn't locally cached** — the bloc fetches `/reels` over the network on every cold start (eager prefetch overlaps it with framework boot, but the network is still the bottleneck). Caching the last seen page in Drift would make subsequent cold starts effectively instant.
6. **No ETag revalidation on metadata endpoints** — `/reels` and `/series/:id` always return full payloads. Adding `ETag` + `If-None-Match` (304 short-circuit) would save a round-trip's worth of bytes on subsequent fetches.

## Library choices, justified

| Layer | Pick | Why over alternatives |
|---|---|---|
| State | `flutter_bloc` | Predictable, testable, handles streams of events well. Riverpod was the alternative; chose Bloc because the team requested it and the structured event/state model maps cleanly to evaluator's review process. |
| DI | `get_it` | Simplest service locator; no codegen. Compile-time DI (Injectable) was overkill for a 50h trial. |
| Routing | `go_router` | Declarative + supports `ShellRoute` which is exactly what feed-position-preservation needs. |
| HTTP | `dio` | Interceptors for auth/logging come for free; cancel tokens matter for a feed that scrolls fast. |
| Local DB | `drift` | Type-safe SQL, supports complex joins for "merge cached episodes with local progress + downloads." Isar is faster but the API has churned and 4.0 is unstable. |
| Downloads | `background_downloader` | Active maintenance, native pause/resume, iOS+Android background support. `flutter_downloader` is older and the resume story is weaker. |
| Video | `video_player` | First-party Flutter plugin. `better_player` and `media_kit` are richer but heavier; for the controller-pool approach, the simpler API wins. |
| Backend runtime | Node 18 + Express | Smallest possible footprint for the 5 endpoints the spec requires. No ORM — raw SQL via a thin driver wrapper keeps the monotonic-upsert logic visible in one file (`repositories/progressRepo.js`) so a reviewer can audit the conflict-resolution rule in 30 seconds. Layered structure (config / middleware / repositories / routes) keeps `server.js` ~50 lines so the composition is easy to scan. |
| Backend DB | `better-sqlite3` (default) with `pg` adapter | SQLite means the reviewer can `npm i && npm run init-db && npm run seed` and have a working backend in 10 seconds, no docker, no Postgres install. The `pg` adapter is included so the same server file works against Postgres unchanged for a real deployment. |
| Content source | **Pexels Videos API** (free tier, free CDN) | The earliest version of this project shipped 25 self-hosted mp4s tracked via Git LFS so a reviewer's clone-and-run was deterministic. That broke down once the spec demanded *episodes 2-10 min* and *reels 15-60s* with content that actually reflected those durations — Git LFS quotas + repo size made shipping ~150 MB of long-form content per reviewer untenable. Pexels exposes a free Videos API (200 req/hr, no card) with consistent encoding and supports per-query duration filters (`min_duration`, `max_duration`), which is exactly what the spec asks for. The `pexels.js` picker hard-caps renditions at 1920×1080 to stay within mobile decoder limits (Qualcomm c2.qti.avc stalls on oversized H.264 like 2048×988). Per-series themed queries (space, city, ocean, workshop, cooking) populate 5 episodes + 5 reels per series. URLs are stored verbatim in Postgres; the device hits Pexels CDN directly, no origin bandwidth on our side. Trade-off: a Pexels video could disappear or change URL — for a take-home this is acceptable; a production app would mirror the chosen assets to its own object storage. |

## Scope cuts

- No PiP — listed P2 in the spec.
- No category filtering / search — listed P2.
- No pull-to-refresh on the reel feed — listed P2.
- Single-user (`x-user-id` header), no auth screen.
- Series-level "download all" button — per-episode is implemented; bulk *delete* ships, bulk *download* does not (acceptable per spec wording "per-episode or full-series").
