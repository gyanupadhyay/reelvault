const { Router } = require('express');
const db = require('../db');
const { upsertProgress } = require('../repositories/progressRepo');

const router = Router();
const nowIso = () => new Date().toISOString();

// GET /progress/:episodeId
router.get('/:episodeId', async (req, res, next) => {
  try {
    const row = await db.get(
      'SELECT episode_id, progress_seconds, last_watched_at, completed FROM watch_progress WHERE user_id = ? AND episode_id = ?',
      [req.userId, req.params.episodeId]
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
  } catch (e) {
    next(e);
  }
});

// PUT /progress/:episodeId — single-episode save
router.put('/:episodeId', async (req, res, next) => {
  try {
    const { progress_seconds, last_watched_at, completed } = req.body || {};
    if (typeof progress_seconds !== 'number' || progress_seconds < 0) {
      return res.status(400).json({ error: 'invalid_progress_seconds' });
    }
    const result = await upsertProgress(
      req.userId,
      req.params.episodeId,
      Math.floor(progress_seconds),
      last_watched_at || nowIso(),
      !!completed
    );
    res.json({ episode_id: req.params.episodeId, ...result });
  } catch (e) {
    next(e);
  }
});

// POST /progress/bulk-sync — flush an offline-accumulated batch in one shot
router.post('/bulk-sync', async (req, res, next) => {
  try {
    const items = Array.isArray(req.body?.items) ? req.body.items : null;
    if (!items) return res.status(400).json({ error: 'items_required' });

    const resolved = [];
    for (const item of items) {
      if (!item.episode_id || typeof item.progress_seconds !== 'number') continue;
      const r = await upsertProgress(
        req.userId,
        item.episode_id,
        Math.floor(item.progress_seconds),
        item.last_watched_at || nowIso(),
        !!item.completed
      );
      resolved.push({ episode_id: item.episode_id, ...r });
    }
    res.json({ resolved });
  } catch (e) {
    next(e);
  }
});

module.exports = router;
