// CLI: wipe + reseed 5 series × 5 episodes + 25 reels. DESTRUCTIVE —
// gated behind NODE_ENV=production unless ALLOW_DESTRUCTIVE_SEED=1.

const db = require('./db');

// Where the seeded video URLs point. Defaults to this server's /static so the
// flow Just Works locally; override with REELVAULT_MEDIA_BASE when seeding a
// deployed backend (e.g. https://reelvault-umr4.onrender.com/static/videos).
const MEDIA_BASE =
  process.env.REELVAULT_MEDIA_BASE || `http://127.0.0.1:${process.env.PORT || 3000}/static/videos`;

const fs = require('node:fs');
const path = require('node:path');

function listLocalMp4Samples() {
  const dir = path.join(__dirname, '..', 'public', 'videos');
  let files = [];
  try {
    files = fs.readdirSync(dir);
  } catch (_) {
    files = [];
  }
  const mp4s = files
    .filter((f) => typeof f === 'string' && f.toLowerCase().endsWith('.mp4'))
    .sort((a, b) => a.localeCompare(b));
  return mp4s.map((f) => `${MEDIA_BASE}/${encodeURIComponent(f)}`);
}

const THUMB = (i) => `https://picsum.photos/seed/reelvault${i}/400/600`;

const SERIES = [
  { id: 'ser_01', title: 'Cosmic Drifters', description: 'A scrappy crew rides the edge of the galaxy in search of a lost sister ship.' },
  { id: 'ser_02', title: 'Neon Hours',      description: 'Detective noir set in a rain-soaked future city where memories are currency.' },
  { id: 'ser_03', title: 'Wild Coast',      description: 'Nature photographers document the last untouched coastlines on Earth.' },
  { id: 'ser_04', title: 'Garage Built',    description: 'Mechanics resurrect forgotten machines, one weekend at a time.' },
  { id: 'ser_05', title: 'Quiet Kitchens',  description: 'Slow, wordless cooking from grandmothers across five continents.' },
];

// Spec ranges: 3-10 episodes/series, episode 2-10min, reel 15-60s.
const EPISODES_PER_SERIES = 5;

const randInt = (min, max) => Math.floor(Math.random() * (max - min + 1)) + min;

const nowIso = () => new Date().toISOString();

const upsert = async (table, columns, values, conflictKey) => {
  const placeholders = columns.map(() => '?').join(', ');
  if (db.driver === 'pg') {
    const updates = columns.filter(c => c !== conflictKey).map(c => `${c}=EXCLUDED.${c}`).join(', ');
    await db.run(
      `INSERT INTO ${table} (${columns.join(', ')}) VALUES (${placeholders}) ON CONFLICT (${conflictKey}) DO UPDATE SET ${updates}`,
      values
    );
  } else {
    await db.run(
      `INSERT OR REPLACE INTO ${table} (${columns.join(', ')}) VALUES (${placeholders})`,
      values
    );
  }
};

(async () => {
  // This script DELETEs every table before reseeding. In prod, refuse unless
  // someone explicitly opts in.
  if (process.env.NODE_ENV === 'production' && process.env.ALLOW_DESTRUCTIVE_SEED !== '1') {
    console.error(
      '❌ Refusing to run seed.js with NODE_ENV=production. This script wipes all tables.\n' +
      '   If you really want to seed a production DB, set ALLOW_DESTRUCTIVE_SEED=1.'
    );
    process.exit(1);
  }

  console.log(`Seeding on ${db.driver}…`);

  const contentSource = (process.env.REELVAULT_CONTENT_SOURCE || 'local').toLowerCase();
  let SAMPLES = listLocalMp4Samples();
  console.log(
    `✓ Content source: ${contentSource} (media base: ${MEDIA_BASE}, local mp4s: ${SAMPLES.length})`
  );
  if (SAMPLES.length < 25) {
    console.log(
      `⚠ Only ${SAMPLES.length} local mp4(s) found; reels may repeat. Add more files to backend/public/videos/ to make all reels unique.`
    );
  }

  await db.run('DELETE FROM watch_progress', []);
  await db.run('DELETE FROM reels', []);
  await db.run('DELETE FROM episodes', []);
  await db.run('DELETE FROM series', []);

  let sampleIdx = 0;
  let reelRank = 0;

  for (let s = 0; s < SERIES.length; s++) {
    const series = SERIES[s];
    await upsert(
      'series',
      ['id', 'title', 'description', 'thumbnail_url', 'episode_count', 'created_at'],
      [series.id, series.title, series.description, THUMB(s), EPISODES_PER_SERIES, nowIso()],
      'id'
    );

    for (let e = 1; e <= EPISODES_PER_SERIES; e++) {
      const episodeId = `${series.id}_ep${e}`;
      const videoUrl = SAMPLES[sampleIdx % SAMPLES.length];
      sampleIdx++;
      const duration = randInt(120, 600);

      await upsert(
        'episodes',
        ['id', 'series_id', 'title', 'description', 'video_url', 'thumbnail_url', 'duration_sec', 'episode_number'],
        [
          episodeId,
          series.id,
          `Episode ${e}: ${['Pilot', 'Currents', 'The Long Quiet', 'Crosswinds', 'Origin'][e - 1]}`,
          'A pivotal moment in the season unfolds across distant locations.',
          videoUrl,
          THUMB(s * 10 + e),
          duration,
          e,
        ],
        'id'
      );

      // One reel per episode. Reuses the same mp4 — at full production scale
      // this would be a separately encoded short clip.
      const reelId = `${series.id}_reel${e}`;
      const reelDuration = randInt(15, 60);
      await upsert(
        'reels',
        ['id', 'series_id', 'episode_id', 'video_url', 'duration_sec', 'rank'],
        [reelId, series.id, episodeId, videoUrl, reelDuration, reelRank++],
        'id'
      );
    }
  }

  console.log(`✓ Seeded ${SERIES.length} series, ${SERIES.length * EPISODES_PER_SERIES} episodes, ${reelRank} reels`);
  process.exit(0);
})().catch((e) => {
  console.error(e);
  process.exit(1);
});
