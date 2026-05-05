const { Router } = require('express');
const db = require('../db');

const router = Router();

// GET /series/:id — series + episodes, joined with this user's progress so
// the client can render watched/unwatched state in one round-trip.
router.get('/:id', async (req, res, next) => {
  try {
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
      [req.userId, req.params.id]
    );

    res.json({ ...series, episodes });
  } catch (e) {
    next(e);
  }
});

module.exports = router;
