// src/db.js
// Database abstraction. Uses Postgres if DATABASE_URL is set, else SQLite for local dev.
// Both expose: db.all(sql, params), db.get(sql, params), db.run(sql, params).
// Postgres uses $1, $2... style; SQLite uses ? style. We translate at the call site
// via the helper `q(sql)` that converts ? to $N for postgres.

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
  const pool = new Pool({ connectionString: process.env.DATABASE_URL });

  // Convert ? placeholders to $1, $2 for pg.
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
