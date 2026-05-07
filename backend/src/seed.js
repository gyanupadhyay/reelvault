// CLI: wipe + reseed 5 series × 5 episodes + 25 reels. DESTRUCTIVE —
// gated behind NODE_ENV=production unless ALLOW_DESTRUCTIVE_SEED=1.
//
// Content source: Pexels Videos API (free, https://www.pexels.com/api/).
// Set PEXELS_API_KEY in env. Per-series themed queries fetch episode-length
// (2-10 min) and reel-length (15-60s) clips. URLs point at Pexels CDN — no
// local mp4s, no LFS, no ffmpeg slicing.

const db = require('./db');
const pexels = require('./lib/pexels');

const SERIES = [
  {
    id: 'ser_01',
    title: 'Cosmic Drifters',
    description: 'A scrappy crew rides the edge of the galaxy in search of a lost sister ship.',
    episodeQuery: 'space galaxy stars',
    reelQuery: 'space',
  },
  {
    id: 'ser_02',
    title: 'Neon Hours',
    description: 'Detective noir set in a rain-soaked future city where memories are currency.',
    episodeQuery: 'city night street',
    reelQuery: 'neon city night',
  },
  {
    id: 'ser_03',
    title: 'Wild Coast',
    description: 'Nature photographers document the last untouched coastlines on Earth.',
    episodeQuery: 'ocean coast waves',
    reelQuery: 'ocean waves',
  },
  {
    id: 'ser_04',
    title: 'Garage Built',
    description: 'Mechanics resurrect forgotten machines, one weekend at a time.',
    episodeQuery: 'workshop tools mechanic',
    reelQuery: 'tools workshop',
  },
  {
    id: 'ser_05',
    title: 'Quiet Kitchens',
    description: 'Slow, wordless cooking from grandmothers across five continents.',
    episodeQuery: 'cooking kitchen food',
    reelQuery: 'cooking food',
  },
];

const EPISODES_PER_SERIES = 5;

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
  if (process.env.NODE_ENV === 'production' && process.env.ALLOW_DESTRUCTIVE_SEED !== '1') {
    console.error(
      '❌ Refusing to run seed.js with NODE_ENV=production. This script wipes all tables.\n' +
      '   If you really want to seed a production DB, set ALLOW_DESTRUCTIVE_SEED=1.'
    );
    process.exit(1);
  }

  if (!process.env.PEXELS_API_KEY) {
    console.error(
      '❌ PEXELS_API_KEY not set.\n' +
      '   Get a free key at https://www.pexels.com/api/ then run:\n' +
      '   PowerShell:  $env:PEXELS_API_KEY = "your_key"\n' +
      '   bash:        export PEXELS_API_KEY=your_key'
    );
    process.exit(1);
  }

  console.log(`Seeding on ${db.driver}…`);
  console.log('✓ Content source: Pexels Videos API');

  // Fetch all series content in parallel — 10 API calls total (one per series
  // × episode/reel range). Cached on disk so reruns are free.
  const seriesContent = await Promise.all(
    SERIES.map(async (s) => {
      const [episodes, reels] = await Promise.all([
        pexels.search(s.episodeQuery, { minDuration: 120, maxDuration: 600, perPage: 30 }),
        pexels.search(s.reelQuery, { minDuration: 15, maxDuration: 60, perPage: 30 }),
      ]);
      return { series: s, episodes, reels };
    })
  );

  for (const { series, episodes, reels } of seriesContent) {
    if (episodes.length < EPISODES_PER_SERIES) {
      console.warn(
        `⚠ ${series.title}: only ${episodes.length} episode-length videos found ` +
        `(need ${EPISODES_PER_SERIES}). Will repeat to fill.`
      );
    }
    if (reels.length < EPISODES_PER_SERIES) {
      console.warn(
        `⚠ ${series.title}: only ${reels.length} reel-length videos found ` +
        `(need ${EPISODES_PER_SERIES}). Will repeat to fill.`
      );
    }
  }

  await db.run('DELETE FROM watch_progress', []);
  await db.run('DELETE FROM reels', []);
  await db.run('DELETE FROM episodes', []);
  await db.run('DELETE FROM series', []);

  let reelRank = 0;
  let totalEpisodes = 0;
  let totalReels = 0;

  for (let s = 0; s < seriesContent.length; s++) {
    const { series, episodes, reels } = seriesContent[s];

    // Series thumbnail: use the first episode video's thumbnail when available.
    const seriesThumb = (episodes[0] && episodes[0].thumbnail) || `https://picsum.photos/seed/reelvault${s}/400/600`;

    await upsert(
      'series',
      ['id', 'title', 'description', 'thumbnail_url', 'episode_count', 'created_at'],
      [series.id, series.title, series.description, seriesThumb, EPISODES_PER_SERIES, nowIso()],
      'id'
    );

    for (let e = 1; e <= EPISODES_PER_SERIES; e++) {
      const epVid = episodes[(e - 1) % Math.max(episodes.length, 1)];
      const reelVid = reels[(e - 1) % Math.max(reels.length, 1)];
      if (!epVid || !reelVid) {
        console.warn(`⚠ Skipping ${series.id}_ep${e}: no Pexels video available`);
        continue;
      }

      const episodeId = `${series.id}_ep${e}`;
      await upsert(
        'episodes',
        ['id', 'series_id', 'title', 'description', 'video_url', 'thumbnail_url', 'duration_sec', 'episode_number'],
        [
          episodeId,
          series.id,
          `Episode ${e}: ${['Pilot', 'Currents', 'The Long Quiet', 'Crosswinds', 'Origin'][e - 1]}`,
          'A pivotal moment in the season unfolds across distant locations.',
          epVid.url,
          epVid.thumbnail,
          epVid.duration,
          e,
        ],
        'id'
      );
      totalEpisodes++;

      const reelId = `${series.id}_reel${e}`;
      await upsert(
        'reels',
        ['id', 'series_id', 'episode_id', 'video_url', 'duration_sec', 'rank'],
        [reelId, series.id, episodeId, reelVid.url, reelVid.duration, reelRank++],
        'id'
      );
      totalReels++;

      console.log(`  • ${episodeId}: ep ${epVid.duration}s, reel ${reelVid.duration}s`);
    }
  }

  console.log(`✓ Seeded ${SERIES.length} series, ${totalEpisodes} episodes, ${totalReels} reels`);
  process.exit(0);
})().catch((e) => {
  console.error(e);
  process.exit(1);
});
