// Runs PGlite (PostgreSQL compiled to WebAssembly) off the main thread, so a slow query can be
// stopped by terminating this worker. The page talks to it with the protocol described in app.js:
//   in : { id, op: 'exec' | 'query', sql, params, cont }
//   out: { id, ok: true, results: [{ fields: [names], rows: [[...]], affectedRows, rowCount, command }], notices: [...] }
//        { id, ok: false, error: { message, position, detail, hint } }
import { PGlite } from 'https://cdn.jsdelivr.net/npm/@electric-sql/pglite@0.5.8/dist/index.js';

// Identity parsers: every value stays the text PostgreSQL sends (numeric 25.50, date 2026-03-02,
// bool t/f, bigint digits, json text), exactly as psql prints it. NULL stays null.
const parsers = {};
const identity = v => v;
for (let oid = 1; oid < 7000; oid++) parsers[oid] = identity;

let dbPromise = null;
function getDb() {
  if (!dbPromise) {
    dbPromise = (async () => {
      const db = new PGlite('idb://swe3003-sql-practice', { parsers });
      await db.waitReady;
      return db;
    })();
  }
  return dbPromise;
}

function pack(r) {
  return {
    fields: (r.fields || []).map(f => f.name),
    rows: r.rows || [],
    affectedRows: r.affectedRows,
    rowCount: r.rowCount,
    command: r.command,
  };
}

async function handle({ id, op, sql, params, cont }) {
  const notices = [];
  try {
    const db = await getDb();
    // Like a fresh psql session per request: an unfinished or failed transaction from before is rolled back.
    // (A script keeps its transaction open from one statement to the next: cont = true.)
    try { if (!cont && db.isInTransaction()) await db.exec('rollback'); } catch (e) { /* best effort */ }
    try { await db.exec('set search_path to practice'); } catch (e) { /* best effort */ }
    const opts = {
      rowMode: 'array',
      parsers,
      onNotice: n => notices.push((n.severity || 'NOTICE') + ':  ' + n.message),
    };
    let results;
    if (op === 'exec') {
      results = (await db.exec(sql, opts)).map(pack);
    } else {
      results = [pack(await db.query(sql, params || [], opts))];
    }
    postMessage({ id, ok: true, results, notices });
  } catch (e) {
    postMessage({
      id, ok: false,
      error: { message: String((e && e.message) || e), position: e && e.position, detail: e && e.detail, hint: e && e.hint },
    });
  }
}

let chain = Promise.resolve();
self.onmessage = ev => { chain = chain.then(() => handle(ev.data)); };
