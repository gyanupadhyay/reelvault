const { Router } = require('express');
const db = require('../db');

const router = Router();

// One row per in-progress series (Netflix-style), not per episode. ROW_NUMBER
// over (series_id ORDER BY last_watched_at DESC) keeps only the user's most
// recent in-progress episode per series. SQLite ≥3.25 + Postgres both support
// window functions, so this SQL ships unchanged.
router.get('/', async (req, res, next) => {
  try {
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
      [req.userId]
    );
    res.json({ items: rows });
  } catch (e) {
    next(e);
  }
});

module.exports = router;
