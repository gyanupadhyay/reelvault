const db = require('../db');

// Monotonic upsert: progress can only move forward.
// Rules: keep max(progress_seconds), keep latest last_watched_at, OR the
// completed flag. A stale write (offline queue replays an old value, retried
// request lands late) can never rewind the user.
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

  const resolvedProgress = Math.max(existing.progress_seconds, progress);
  const resolvedTs =
    lastWatchedAt > existing.last_watched_at ? lastWatchedAt : existing.last_watched_at;
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

module.exports = { upsertProgress };
