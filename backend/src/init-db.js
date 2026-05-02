// src/init-db.js
// Creates the schema. Idempotent.
const db = require('./db');

const schema = `
CREATE TABLE IF NOT EXISTS series (
  id            TEXT PRIMARY KEY,
  title         TEXT NOT NULL,
  description   TEXT NOT NULL,
  thumbnail_url TEXT NOT NULL,
  episode_count INTEGER NOT NULL DEFAULT 0,
  created_at    TEXT NOT NULL DEFAULT (datetime('now'))
);

CREATE TABLE IF NOT EXISTS episodes (
  id             TEXT PRIMARY KEY,
  series_id      TEXT NOT NULL REFERENCES series(id) ON DELETE CASCADE,
  title          TEXT NOT NULL,
  description    TEXT NOT NULL,
  video_url      TEXT NOT NULL,
  thumbnail_url  TEXT NOT NULL,
  duration_sec   INTEGER NOT NULL,
  episode_number INTEGER NOT NULL
);
CREATE INDEX IF NOT EXISTS idx_episodes_series ON episodes(series_id, episode_number);

CREATE TABLE IF NOT EXISTS reels (
  id           TEXT PRIMARY KEY,
  series_id    TEXT NOT NULL REFERENCES series(id) ON DELETE CASCADE,
  episode_id   TEXT NOT NULL REFERENCES episodes(id) ON DELETE CASCADE,
  video_url    TEXT NOT NULL,
  duration_sec INTEGER NOT NULL,
  rank         INTEGER NOT NULL
);
CREATE INDEX IF NOT EXISTS idx_reels_rank ON reels(rank);

CREATE TABLE IF NOT EXISTS watch_progress (
  user_id          TEXT NOT NULL,
  episode_id       TEXT NOT NULL REFERENCES episodes(id) ON DELETE CASCADE,
  progress_seconds INTEGER NOT NULL,
  last_watched_at  TEXT NOT NULL,
  completed        INTEGER NOT NULL DEFAULT 0,
  PRIMARY KEY (user_id, episode_id)
);
CREATE INDEX IF NOT EXISTS idx_progress_user ON watch_progress(user_id, last_watched_at DESC);
`;

// Postgres uses NOW() and BOOLEAN; we keep SQL portable with TEXT timestamps and INTEGER bools.
// This works on both engines because we never call datetime('now') on pg — we always pass
// timestamps from the application layer (ISO strings) for inserts/updates.

(async () => {
  if (db.driver === 'pg') {
    // Postgres needs slightly different default. Strip the SQLite-only default.
    const pgSchema = schema.replace("DEFAULT (datetime('now'))", "DEFAULT (NOW()::TEXT)");
    await db.exec(pgSchema);
  } else {
    await db.exec(schema);
  }
  console.log(`✓ Schema initialized on ${db.driver}`);
  process.exit(0);
})().catch((e) => {
  console.error(e);
  process.exit(1);
});
