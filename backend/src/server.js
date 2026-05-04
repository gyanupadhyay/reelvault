// src/server.js
const express = require('express');
const cors = require('cors');
const morgan = require('morgan');
const compression = require('compression');
const path = require('path');
const db = require('./db');

const app = express();

// Gzip JSON responses. Skip /static/videos because mp4 is already compressed
// and re-gzipping wastes CPU + breaks Range/streaming for large payloads.
app.use(
  compression({
    filter: (req, res) => {
      if (req.path.startsWith('/static/videos')) return false;
      return compression.filter(req, res);
    },
  })
);

app.use(cors());
app.use(express.json({ limit: '1mb' }));
app.use(morgan('dev'));

// Serve locally-hosted videos for deterministic performance / offline downloads.
// Files live under backend/public/videos/*.mp4 and are reachable at:
//   http://<host>:3000/static/videos/<file>.mp4
//
// Long Cache-Control + immutable: filenames are content-stable (one mp4 per reel,
// never overwritten in place), so the device's HTTP cache can pin them. A re-watch
// of the same reel skips the network entirely. The ETag covers the rare case
// where a reseed swaps a file but keeps the same name.
app.use(
  '/static',
  express.static(path.join(__dirname, '..', 'public'), {
    maxAge: '30d',
    immutable: true,
    etag: true,
  })
);

const PORT = process.env.PORT || 3000;
const DEFAULT_USER = 'demo-user'; // single-user app for the trial; replace with auth later.

// Helpers ---------------------------------------------------------------

const userIdFromReq = (req) => req.header('x-user-id') || DEFAULT_USER;
const nowIso = () => new Date().toISOString();

// Monotonic upsert: progress can only move forward.
// If incoming.progress_seconds <= existing.progress_seconds AND incoming.last_watched_at <= existing.last_watched_at,
// we keep the existing. Otherwise we take the max progress AND the latest timestamp.
async function upsertProgress(userId, episodeId, progress, lastWatchedAt, completed) {
  const existing = await db.get(
    'SELECT progress_seconds, last_watched_at, completed FROM watch_progress WHERE user_id = ? AND episode_id = ?',
    [userId, episodeId]
  );

  if (!existing) {
    await db.run(
      'INSERT INTO watch_progress (user_id, episode_id, progress_seconds, last_watched_at, completed) VALUES (?, ?, ?, ?, ?)',
      [userId, episodeId, progress, lastWatchedAt, completed ? 1 : 0]
    );
    return { progress_seconds: progress, last_watched_at: lastWatchedAt, completed: !!completed };
  }

  // Conflict resolution: take the greater of progress, the later timestamp,
  // and OR the completed flag. This is monotonic — never goes backwards.
  const resolvedProgress = Math.max(existing.progress_seconds, progress);
  const resolvedTs = lastWatchedAt > existing.last_watched_at ? lastWatchedAt : existing.last_watched_at;
  const resolvedCompleted = (existing.completed || (completed ? 1 : 0)) ? 1 : 0;

  await db.run(
    'UPDATE watch_progress SET progress_seconds = ?, last_watched_at = ?, completed = ? WHERE user_id = ? AND episode_id = ?',
    [resolvedProgress, resolvedTs, resolvedCompleted, userId, episodeId]
  );

  return {
    progress_seconds: resolvedProgress,
    last_watched_at: resolvedTs,
    completed: !!resolvedCompleted,
  };
}

// Routes ----------------------------------------------------------------

app.get('/health', (_req, res) => res.json({ ok: true, driver: db.driver }));

// GET /reels?cursor=0&limit=20 — paginated reel feed
app.get('/reels', async (req, res, next) => {
  try {
    const cursor = parseInt(req.query.cursor || '0', 10);
    const limit = Math.min(parseInt(req.query.limit || '20', 10), 50);

    // thumbnail_url comes from the joined episode (per-episode thumbs already
    // exist in the seed). Frontend uses it as a placeholder under the video so
    // users never see a white spinner during init — it makes the feed feel like
    // Instagram instead of "loading…".
    const rows = await db.all(
      `SELECT r.id, r.series_id, r.episode_id, r.video_url, r.duration_sec, r.rank,
              s.title AS series_title,
              e.title AS episode_title, e.episode_number,
              e.thumbnail_url AS thumbnail_url
         FROM reels r
         JOIN series s ON s.id = r.series_id
         JOIN episodes e ON e.id = r.episode_id
        WHERE r.rank >= ?
        ORDER BY r.rank ASC
        LIMIT ?`,
      [cursor, limit]
    );

    const nextCursor = rows.length === limit ? rows[rows.length - 1].rank + 1 : null;
    res.json({ items: rows, next_cursor: nextCursor });
  } catch (e) { next(e); }
});

// GET /series/:id — series detail with episodes + per-episode progress for caller
app.get('/series/:id', async (req, res, next) => {
  try {
    const userId = userIdFromReq(req);
    const series = await db.get('SELECT * FROM series WHERE id = ?', [req.params.id]);
    if (!series) return res.status(404).json({ error: 'series_not_found' });

    const episodes = await db.all(
      `SELECT e.*,
              COALESCE(p.progress_seconds, 0) AS progress_seconds,
              COALESCE(p.completed, 0)        AS completed,
              p.last_watched_at
         FROM episodes e
         LEFT JOIN watch_progress p
                ON p.episode_id = e.id AND p.user_id = ?
        WHERE e.series_id = ?
        ORDER BY e.episode_number ASC`,
      [userId, req.params.id]
    );

    res.json({ ...series, episodes });
  } catch (e) { next(e); }
});

// GET /progress/:episodeId — fetch progress for one episode
app.get('/progress/:episodeId', async (req, res, next) => {
  try {
    const userId = userIdFromReq(req);
    const row = await db.get(
      'SELECT episode_id, progress_seconds, last_watched_at, completed FROM watch_progress WHERE user_id = ? AND episode_id = ?',
      [userId, req.params.episodeId]
    );
    if (!row) {
      return res.json({
        episode_id: req.params.episodeId,
        progress_seconds: 0,
        last_watched_at: null,
        completed: false,
      });
    }
    res.json({ ...row, completed: !!row.completed });
  } catch (e) { next(e); }
});

// PUT /progress/:episodeId — save progress (monotonic)
app.put('/progress/:episodeId', async (req, res, next) => {
  try {
    const userId = userIdFromReq(req);
    const { progress_seconds, last_watched_at, completed } = req.body || {};
    if (typeof progress_seconds !== 'number' || progress_seconds < 0) {
      return res.status(400).json({ error: 'invalid_progress_seconds' });
    }
    const ts = last_watched_at || nowIso();
    const result = await upsertProgress(
      userId,
      req.params.episodeId,
      Math.floor(progress_seconds),
      ts,
      !!completed
    );
    res.json({ episode_id: req.params.episodeId, ...result });
  } catch (e) { next(e); }
});

// POST /progress/bulk-sync — accept array, return per-episode resolved values
app.post('/progress/bulk-sync', async (req, res, next) => {
  try {
    const userId = userIdFromReq(req);
    const items = Array.isArray(req.body?.items) ? req.body.items : null;
    if (!items) return res.status(400).json({ error: 'items_required' });

    const resolved = [];
    for (const item of items) {
      if (!item.episode_id || typeof item.progress_seconds !== 'number') continue;
      const r = await upsertProgress(
        userId,
        item.episode_id,
        Math.floor(item.progress_seconds),
        item.last_watched_at || nowIso(),
        !!item.completed
      );
      resolved.push({ episode_id: item.episode_id, ...r });
    }
    res.json({ resolved });
  } catch (e) { next(e); }
});

// Continue Watching — one row per in-progress *series* (matches the spec
// wording "in-progress series" and the Netflix/Prime/YouTube convention).
// We rank each user's in-progress episodes within their series by recency
// and keep only rank=1 — i.e. the latest episode the user touched in that
// series. Window functions are supported by SQLite ≥3.25 and Postgres,
// the two backends we target.
app.get('/continue-watching', async (req, res, next) => {
  try {
    const userId = userIdFromReq(req);
    const rows = await db.all(
      `WITH ranked AS (
         SELECT p.episode_id, p.progress_seconds, p.last_watched_at,
                e.title AS episode_title, e.episode_number, e.duration_sec,
                e.thumbnail_url AS episode_thumb,
                s.id AS series_id, s.title AS series_title,
                s.thumbnail_url AS series_thumb,
                ROW_NUMBER() OVER (
                  PARTITION BY e.series_id
                  ORDER BY p.last_watched_at DESC
                ) AS rn
           FROM watch_progress p
           JOIN episodes e ON e.id = p.episode_id
           JOIN series   s ON s.id = e.series_id
          WHERE p.user_id = ?
            AND p.completed = 0
            AND p.progress_seconds > 0
       )
       SELECT episode_id, episode_title, episode_number, duration_sec, episode_thumb,
              series_id, series_title, series_thumb,
              progress_seconds, last_watched_at
         FROM ranked
        WHERE rn = 1
        ORDER BY last_watched_at DESC
        LIMIT 10`,
      [userId]
    );
    res.json({ items: rows });
  } catch (e) { next(e); }
});

// Error handler
app.use((err, _req, res, _next) => {
  console.error(err);
  res.status(500).json({ error: 'internal', message: err.message });
});

app.listen(PORT, () => {
  console.log(`ReelVault backend on :${PORT} (${db.driver})`);
});
