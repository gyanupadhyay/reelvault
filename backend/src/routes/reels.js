const { Router } = require('express');
const db = require('../db');

const router = Router();

// GET /reels?cursor=0&limit=20
router.get('/', async (req, res, next) => {
  try {
    const cursor = parseInt(req.query.cursor || '0', 10);
    const limit = Math.min(parseInt(req.query.limit || '20', 10), 50);

    // thumbnail_url piggybacks on the existing episodes column; the client
    // uses it as the under-video placeholder.
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
  } catch (e) {
    next(e);
  }
});

module.exports = router;
