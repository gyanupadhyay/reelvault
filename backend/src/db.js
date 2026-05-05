// Postgres if DATABASE_URL is set, else local SQLite. Both expose the same
// .all/.get/.run/.exec surface. Routes write SQL with `?` placeholders; the pg
// branch rewrites those to `$1, $2, ...` at query time.

const useSqlite = !process.env.DATABASE_URL;

let impl;

if (useSqlite) {
  const Database = require('better-sqlite3');
  const path = require('path');
  const dbFile = process.env.SQLITE_PATH || path.join(__dirname, '..', 'reelvault.db');
  const sqlite = new Database(dbFile);
  sqlite.pragma('journal_mode = WAL');
  sqlite.pragma('foreign_keys = ON');

  impl = {
    driver: 'sqlite',
    all: async (sql, params = []) => sqlite.prepare(sql).all(...params),
    get: async (sql, params = []) => sqlite.prepare(sql).get(...params),
    run: async (sql, params = []) => {
      const r = sqlite.prepare(sql).run(...params);
      return { changes: r.changes, lastInsertRowid: r.lastInsertRowid };
    },
    exec: async (sql) => sqlite.exec(sql),
  };
} else {
  const { Pool } = require('pg');

  // Auto-enable SSL for the usual managed Postgres hosts. PGSSL=true|false
  // overrides if you need to.
  const url = process.env.DATABASE_URL;
  const explicitSsl = process.env.PGSSL === 'true';
  const explicitNoSsl = process.env.PGSSL === 'false';
  const looksManaged = /(render\.com|amazonaws\.com|heroku|neon\.tech|supabase\.co|railway\.app|fly\.dev)/.test(url);
  const useSsl = explicitSsl || (looksManaged && !explicitNoSsl);

  const pool = new Pool({
    connectionString: url,
    // Managed providers chain through intermediates Node's default CA store
    // doesn't know about — standard Render/Heroku workaround.
    ssl: useSsl ? { rejectUnauthorized: false } : false,
  });

  const toPg = (sql) => {
    let i = 0;
    return sql.replace(/\?/g, () => `$${++i}`);
  };

  impl = {
    driver: 'pg',
    all: async (sql, params = []) => (await pool.query(toPg(sql), params)).rows,
    get: async (sql, params = []) => (await pool.query(toPg(sql), params)).rows[0],
    run: async (sql, params = []) => {
      const r = await pool.query(toPg(sql), params);
      return { changes: r.rowCount };
    },
    exec: async (sql) => pool.query(sql),
  };
}

module.exports = impl;
