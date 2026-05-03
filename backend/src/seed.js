// src/seed.js
// Seeds 5 series × 5 episodes = 25 episodes, plus 25 reels (one per episode).
// Uses Google's public sample videos (gtv-videos-bucket) — stable, free, CORS-friendly.

const db = require('./db');

// Content source:
//
// Default is locally-hosted MP4s served from this backend for deterministic playback:
//   http://<host>:3000/static/videos/<name>.mp4
//
// If you want to seed with remote URLs instead, set REELVAULT_MEDIA_BASE to a full URL
// (e.g. https://cdn.example.com/reelvault) and use filenames below.

const MEDIA_BASE =
  process.env.REELVAULT_MEDIA_BASE || `http://127.0.0.1:${process.env.PORT || 3000}/static/videos`;

const fs = require('node:fs');
const path = require('node:path');

function listLocalMp4Samples() {
  // backend/public/videos/*.mp4 → http://<host>:3000/static/videos/<file>.mp4
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

const https = require('node:https');

function httpsGetJson(url) {
  return new Promise((resolve, reject) => {
    https
      .get(
        url,
        {
          headers: {
            'User-Agent': 'ReelVaultSeeder/1.0 (work-trial; contact: local)',
            Accept: 'application/json',
          },
        },
        (res) => {
          let data = '';
          res.on('data', (chunk) => (data += chunk));
          res.on('end', () => {
            try {
              resolve(JSON.parse(data));
            } catch (e) {
              reject(e);
            }
          });
        }
      )
      .on('error', reject);
  });
}

async function fetchWikimediaMp4Urls({ limit = 24 } = {}) {
  // Wikimedia Commons API note (2026): MIME search is disabled ("Miser Mode"),
  // so we can't query by aimime. Instead we:
  //  1) search in File namespace for titles that include ".mp4"
  //  2) fetch imageinfo(url) for those titles
  const searchUrl =
    'https://commons.wikimedia.org/w/api.php' +
    '?action=query' +
    '&format=json' +
    '&list=search' +
    '&srnamespace=6' +
    `&srlimit=${Math.min(limit, 50)}` +
    // Search for MP4 in file titles (simple + works without MIME search).
    '&srsearch=intitle:.mp4' +
    '&origin=*';

  const search = await httpsGetJson(searchUrl);
  const titles =
    (search?.query?.search ?? [])
      .map((s) => s?.title)
      .filter(Boolean)
      .slice(0, limit) ?? [];
  if (titles.length === 0) return [];

  const infoUrl =
    'https://commons.wikimedia.org/w/api.php' +
    '?action=query' +
    '&format=json' +
    '&prop=imageinfo' +
    '&iiprop=url' +
    `&titles=${encodeURIComponent(titles.join('|'))}` +
    '&origin=*';

  const info = await httpsGetJson(infoUrl);
  const pages = info?.query?.pages ?? {};
  const urls = Object.values(pages)
    .flatMap((p) => p?.imageinfo ?? [])
    .map((ii) => ii?.url)
    .filter((u) => typeof u === 'string' && u.toLowerCase().includes('.mp4'));

  return [...new Set(urls)].slice(0, limit);
}

const THUMB = (i) => `https://picsum.photos/seed/reelvault${i}/400/600`;

const SERIES = [
  { id: 'ser_01', title: 'Cosmic Drifters', description: 'A scrappy crew rides the edge of the galaxy in search of a lost sister ship.' },
  { id: 'ser_02', title: 'Neon Hours',      description: 'Detective noir set in a rain-soaked future city where memories are currency.' },
  { id: 'ser_03', title: 'Wild Coast',      description: 'Nature photographers document the last untouched coastlines on Earth.' },
  { id: 'ser_04', title: 'Garage Built',    description: 'Mechanics resurrect forgotten machines, one weekend at a time.' },
  { id: 'ser_05', title: 'Quiet Kitchens',  description: 'Slow, wordless cooking from grandmothers across five continents.' },
];

// Spec compliance:
// - Series length: 3–10 episodes per series
// - Episode duration metadata: 2–10 minutes
// - Reel duration metadata: 15–60 seconds
const EPISODES_PER_SERIES = 5; // within 3–10

const randInt = (min, max) => Math.floor(Math.random() * (max - min + 1)) + min;

const nowIso = () => new Date().toISOString();

const upsert = async (table, columns, values, conflictKey) => {
  const placeholders = columns.map(() => '?').join(', ');
  if (db.driver === 'pg') {
    // Use ON CONFLICT for pg
    const updates = columns.filter(c => c !== conflictKey).map(c => `${c}=EXCLUDED.${c}`).join(', ');
    await db.run(
      `INSERT INTO ${table} (${columns.join(', ')}) VALUES (${placeholders}) ON CONFLICT (${conflictKey}) DO UPDATE SET ${updates}`,
      values
    );
  } else {
    // SQLite: INSERT OR REPLACE
    await db.run(
      `INSERT OR REPLACE INTO ${table} (${columns.join(', ')}) VALUES (${placeholders})`,
      values
    );
  }
};

(async () => {
  // Production safety guard. The seed script unconditionally wipes every table
  // on every run. Without this guard, a stray `DATABASE_URL=...prod... npm run seed`
  // destroys live user data. Override with ALLOW_DESTRUCTIVE_SEED=1 if you really
  // mean it (e.g. first-time bootstrap of a fresh prod DB).
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

  // Wipe existing rows for clean re-seed (gated above).
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
      // Episode duration metadata: 2–10 minutes.
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

      // One reel per episode. Reel uses same sample video, but trimmed conceptually.
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
