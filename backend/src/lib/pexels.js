// Pexels Videos API client.
// Free key from https://www.pexels.com/api/, set as env PEXELS_API_KEY.
// Caches responses to .cache/pexels.json so reseeding is fast and offline-safe.

const fs = require('node:fs');
const path = require('node:path');

const API_BASE = 'https://api.pexels.com/videos/search';
const CACHE_PATH = path.join(__dirname, '..', '..', '.cache', 'pexels.json');

function loadCache() {
  try {
    return JSON.parse(fs.readFileSync(CACHE_PATH, 'utf-8'));
  } catch (_) {
    return {};
  }
}

function saveCache(cache) {
  fs.mkdirSync(path.dirname(CACHE_PATH), { recursive: true });
  fs.writeFileSync(CACHE_PATH, JSON.stringify(cache, null, 2));
}

// Pexels returns multiple renditions per video. Prefer 720p H.264 — small enough
// to stream over a phone connection, large enough to look fine on a phone screen.
function pickVideoFile(files) {
  const mp4s = files.filter((f) => f.file_type === 'video/mp4');
  return (
    mp4s.find((f) => f.height === 720 && f.quality === 'hd') ||
    mp4s.find((f) => f.quality === 'hd' && f.height && f.height <= 1080) ||
    mp4s.find((f) => f.quality === 'sd') ||
    mp4s[0]
  );
}

async function search(query, { minDuration, maxDuration, perPage = 30 } = {}) {
  const apiKey = process.env.PEXELS_API_KEY;
  if (!apiKey) {
    throw new Error(
      'PEXELS_API_KEY env var not set. Get a free key at https://www.pexels.com/api/ and set it before running seed.'
    );
  }

  const cache = loadCache();
  const cacheKey = `${query}|min=${minDuration || ''}|max=${maxDuration || ''}|n=${perPage}`;
  if (cache[cacheKey]) return cache[cacheKey];

  const params = new URLSearchParams({ query, per_page: String(perPage) });
  if (minDuration) params.set('min_duration', String(minDuration));
  if (maxDuration) params.set('max_duration', String(maxDuration));

  const res = await fetch(`${API_BASE}?${params.toString()}`, {
    headers: { Authorization: apiKey },
  });
  if (!res.ok) {
    const body = await res.text();
    throw new Error(`Pexels API ${res.status}: ${body.slice(0, 300)}`);
  }
  const data = await res.json();

  const videos = (data.videos || [])
    .map((v) => {
      const file = pickVideoFile(v.video_files || []);
      if (!file || !file.link) return null;
      return {
        pexelsId: v.id,
        duration: v.duration,
        url: file.link,
        width: file.width,
        height: file.height,
        thumbnail: v.image,
        attribution: { user: v.user && v.user.name, link: v.url },
      };
    })
    .filter(Boolean)
    .filter(
      (v) =>
        (!minDuration || v.duration >= minDuration) &&
        (!maxDuration || v.duration <= maxDuration)
    );

  cache[cacheKey] = videos;
  saveCache(cache);
  return videos;
}

module.exports = { search };
