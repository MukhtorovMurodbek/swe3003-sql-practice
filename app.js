/* SWE3003 Practice: browser-only version.
   The database is PGlite (PostgreSQL in WebAssembly) running in worker.js; progress is kept in IndexedDB. */

const $ = id => document.getElementById(id);
let meta = null, sets = [], questions = [], current = null;
const tableCache = {};
let currentTableSet = null, currentTab = null;

const MAX_ROWS = 500;
const QUERY_TIMEOUT_MS = 10000;
const SETUP_TIMEOUT_MS = 5 * 60 * 1000;
const TIMEOUT_MSG = 'Your query ran for more than 10 seconds and was stopped. A missing join condition is the usual cause ' +
  '(it multiplies rows). The database was restarted; your saved progress is fine.';

const TableSets = {
  shop: ['seller', 'item', 'buyer', 'orders', 'order_details'],
  uni: ['department', 'instructor', 'student', 'course', 'section', 'teaches', 'takes',
        'advisor', 'prereq', 'classroom', 'time_slot'],
  plpg: ['instructor', 'department', 'salary_log', 'dept_stats', 'teaches', 'takes', 'course', 'time_slot'],
};

/* ---------- helpers ---------- */
function esc(s) {
  return String(s).replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;').replace(/"/g, '&quot;');
}
function inline(s) {
  return esc(s)
    .replace(/&lt;(\/?)sub&gt;/g, '<$1sub>')
    .replace(/`([^`]+)`/g, '<code>$1</code>')
    .replace(/\*\*([^*]+)\*\*/g, '<b>$1</b>');
}
function md(src) {
  const lines = String(src || '').split('\n');
  let html = '', inCode = false, code = [], inList = false, para = [];
  const flushPara = () => { if (para.length) { html += '<p>' + inline(para.join(' ')) + '</p>'; para = []; } };
  const closeList = () => { if (inList) { html += '</ul>'; inList = false; } };
  for (const line of lines) {
    if (line.trim().startsWith('```')) {
      if (inCode) { html += '<pre><code>' + esc(code.join('\n')) + '</code></pre>'; code = []; inCode = false; }
      else { flushPara(); closeList(); inCode = true; }
      continue;
    }
    if (inCode) { code.push(line); continue; }
    const li = line.match(/^\s*[-*]\s+(.*)$/);
    if (li) { flushPara(); if (!inList) { html += '<ul>'; inList = true; } html += '<li>' + inline(li[1]) + '</li>'; continue; }
    if (line.trim() === '') { flushPara(); closeList(); continue; }
    closeList(); para.push(line);
  }
  flushPara(); closeList();
  if (inCode) html += '<pre><code>' + esc(code.join('\n')) + '</code></pre>';
  return html;
}
function store(key, val) { try { localStorage.setItem(key, val); } catch {} }
function load(key) { try { return localStorage.getItem(key); } catch { return null; } }

function tableHtml(t, emptyNote) {
  if (!t) return '';
  if (t.error) return '<div class="error">' + esc(t.error) + '</div>';
  const cols = t.columns || [];
  let h = '<div class="tablebox"><table><thead><tr>' + cols.map(c => '<th>' + esc(c) + '</th>').join('') + '</tr></thead><tbody>';
  for (const row of (t.rows || [])) {
    h += '<tr>' + row.map(v => v === null ? '<td class="null">NULL</td>' : '<td>' + esc(v) + '</td>').join('') + '</tr>';
  }
  h += '</tbody></table></div>';
  const total = t.total !== undefined ? t.total : (t.rows || []).length;
  const shown = (t.rows || []).length;
  h += '<div class="rowcount">' + (total === 1 ? '1 row' : total + ' rows') +
       (shown < total ? ' (first ' + shown + ' shown)' : '') + (total === 0 && emptyNote ? ' · ' + emptyNote : '') + '</div>';
  return h;
}

/* ---------- the database (PGlite in a Web Worker) ---------- */
class TimeoutError extends Error {}
class SqlError extends Error {
  constructor(e) {
    super(e.message);
    this.position = e.position; this.detail = e.detail; this.hint = e.hint;
  }
}

let worker = null, readyP = null, seq = 0, queue = Promise.resolve();
const pending = new Map();

function request(w, req, timeoutMs, timeoutMessage) {
  return new Promise((resolve, reject) => {
    const id = ++seq;
    const timer = setTimeout(() => { pending.delete(id); reject(new TimeoutError(timeoutMessage)); }, timeoutMs);
    pending.set(id, m => { clearTimeout(timer); resolve(m); });
    w.postMessage({ id, ...req });
  });
}

function startWorker() {
  const w = new Worker('worker.js', { type: 'module' });
  worker = w;
  w.onmessage = e => {
    const m = e.data;
    const done = pending.get(m.id);
    if (done) { pending.delete(m.id); done(m); }
  };
  w.onerror = () => {
    const m = { ok: false, error: { message: 'The database engine could not be loaded. Check your internet connection ' +
      '(it is downloaded from cdn.jsdelivr.net the first time) and reload the page.' } };
    for (const [id, done] of [...pending]) { pending.delete(id); done(m); }
  };
  // Opening the database (and downloading the engine the first time) can take a while.
  readyP = request(w, { op: 'query', sql: 'select 1', params: [] }, SETUP_TIMEOUT_MS,
    'The database did not start within 5 minutes. Reload the page to try again.')
    .then(m => { if (!m.ok) throw new SqlError(m.error); });
  readyP.catch(() => {});
}
function restartWorker() {
  try { worker.terminate(); } catch {}
  pending.clear();
  startWorker();
}

// op: 'exec' (a whole script, no parameters) or 'query' (one statement with $1, $2 ... parameters).
// Resolves to the array of results [{fields, rows, affectedRows, rowCount, command}] (with .notices).
// `cont` = this request continues a script: an open transaction from the previous statement is kept.
function db(op, sql, params, timeoutMs = QUERY_TIMEOUT_MS, cont = false) {
  const job = queue.then(async () => {
    await readyP;
    try {
      const m = await request(worker, { op, sql, params, cont }, timeoutMs, TIMEOUT_MSG);
      if (!m.ok) throw new SqlError(m.error);
      m.results.notices = m.notices || [];
      return m.results;
    } catch (e) {
      if (e instanceof TimeoutError && timeoutMs === QUERY_TIMEOUT_MS) restartWorker();
      throw e;
    }
  });
  queue = job.catch(() => {});
  return job;
}
async function rows(sql, params, timeoutMs) { return (await db('query', sql, params, timeoutMs))[0].rows; }
async function oneJson(sql, params) { const r = await rows(sql, params); return r.length ? JSON.parse(r[0][0]) : null; }

// psql-style error text: ERROR:, LINE n with a caret, DETAIL, HINT.
function psqlError(e, sql, offset) {
  if (!(e instanceof SqlError)) return e.message;
  let out = 'ERROR:  ' + e.message;
  const pos = parseInt(e.position, 10) - (offset || 0);
  if (typeof sql === 'string' && pos >= 1 && pos <= sql.length + 1) {
    const before = sql.slice(0, pos - 1);
    const lineNo = before.split('\n').length;
    const start = before.lastIndexOf('\n') + 1;
    let end = sql.indexOf('\n', start);
    if (end < 0) end = sql.length;
    const prefix = 'LINE ' + lineNo + ': ';
    out += '\n' + prefix + sql.slice(start, end).replace(/\r$/, '').replace(/\t/g, ' ') +
           '\n' + ' '.repeat(prefix.length + (pos - 1 - start)) + '^';
  }
  if (e.detail) out += '\nDETAIL:  ' + e.detail;
  if (e.hint) out += '\nHINT:  ' + e.hint;
  return out;
}

/* ---------- query helpers (ported from the Windows kit's server.ps1) ---------- */
// True if the text is exactly one read-only query (comments and a trailing ; ignored).
function isSingleQuery(sql) {
  let s = sql.split(/\r?\n/).map(l => l.replace(/--.*$/, '')).join('\n');
  s = s.trim().replace(/;+$/, '').trim();
  if (s === '' || s.includes(';')) return false;
  return /^(select|with|values|table|\()/i.test(s);
}
function tableFrom(r) {
  if (!r) return { columns: [], rows: [], total: 0 };
  return { columns: r.fields, rows: r.rows.slice(0, MAX_ROWS), total: r.rows.length };
}
function firstTable(results) {
  return tableFrom(results.find(r => r.fields.length > 0) || results[0]);
}
const TX_PREFIX = 'begin;\n';
// Runs one query and throws the changes away: returns a table, or { error } with psql-style text.
async function queryTable(query, inTransaction) {
  try {
    if (!inTransaction) return firstTable(await db('exec', query));
    const res = await db('exec', TX_PREFIX + query + '\n;\nrollback;');
    return firstTable(res.slice(1));
  } catch (e) {
    if (e instanceof SqlError) return { error: psqlError(e, query, inTransaction ? TX_PREFIX.length : 0) };
    throw e;
  }
}
// Splits a script into statements at top-level semicolons, like psql does: semicolons inside quotes,
// "identifiers", $$ dollar quotes $$ and comments do not count. Each item: { text, start } (start = offset).
function splitStatements(sql) {
  const out = [], n = sql.length;
  let i = 0, start = 0;
  const push = end => {
    const text = sql.slice(start, end);
    if (text.replace(/--[^\n]*|\/\*[\s\S]*?\*\//g, '').replace(/[\s;]/g, '') !== '') out.push({ text, start });
    start = end;
  };
  while (i < n) {
    const c = sql[i], d = sql[i + 1];
    if (c === '-' && d === '-') { const j = sql.indexOf('\n', i); i = j < 0 ? n : j; continue; }
    if (c === '/' && d === '*') {
      let depth = 1; i += 2;
      while (i < n && depth > 0) {
        if (sql[i] === '/' && sql[i + 1] === '*') { depth++; i += 2; }
        else if (sql[i] === '*' && sql[i + 1] === '/') { depth--; i += 2; }
        else i++;
      }
      continue;
    }
    if (c === "'") {
      const backslash = i > 0 && (sql[i - 1] === 'e' || sql[i - 1] === 'E') && (i < 2 || !/[\w$]/.test(sql[i - 2]));
      i++;
      while (i < n) {
        if (backslash && sql[i] === '\\') { i += 2; continue; }
        if (sql[i] === "'") { if (sql[i + 1] === "'") { i += 2; continue; } break; }
        i++;
      }
      i++; continue;
    }
    if (c === '"') {
      i++;
      while (i < n) {
        if (sql[i] === '"') { if (sql[i + 1] === '"') { i += 2; continue; } break; }
        i++;
      }
      i++; continue;
    }
    if (c === '$' && (i === 0 || !/[\w$]/.test(sql[i - 1]))) {
      const m = /^\$([A-Za-z_\u0080-￿][\w\u0080-￿]*)?\$/.exec(sql.slice(i, i + 200));
      if (m) {
        const j = sql.indexOf(m[0], i + m[0].length);
        i = j < 0 ? n : j + m[0].length;
        continue;
      }
    }
    if (c === ';') { i++; push(i); continue; }
    i++;
  }
  push(n);
  return out;
}

// Runs a script statement by statement, like psql -f: an error is reported in place and the next
// statement still runs. Returns { parts: [{table} | {text} | {error}], hadError }.
async function runScript(sql) {
  const parts = [];
  let hadError = false, first = true;
  for (const st of splitStatements(sql)) {
    try {
      const res = await db('exec', st.text, undefined, QUERY_TIMEOUT_MS, !first);
      first = false;
      for (const note of res.notices) parts.push({ text: note });
      for (const r of res) {
        if (r.fields.length > 0) { parts.push({ table: tableFrom(r) }); continue; }
        const dml = /^(INSERT|UPDATE|DELETE|MERGE|COPY)/i.test(r.command || '');
        const k = r.rowCount !== undefined && r.rowCount !== null ? r.rowCount : (r.affectedRows || 0);
        parts.push({ text: dml ? 'OK, ' + k + (k === 1 ? ' row' : ' rows') + ' affected' : 'OK' });
      }
    } catch (e) {
      if (!(e instanceof SqlError)) throw e;
      first = false;
      hadError = true;
      parts.push({ error: psqlError(e, sql, -st.start) });
    }
  }
  return { parts, hadError };
}
// Display parts as HTML. `quiet` hides the plain "OK" lines (only tables, notices and errors remain).
function partsHtml(parts, quiet) {
  let h = '', buf = [];
  const flush = () => { if (buf.length) { h += '<pre class="out">' + esc(buf.join('\n')) + '</pre>'; buf = []; } };
  for (const p of parts) {
    if (p.table) { flush(); h += tableHtml(p.table); }
    else if (p.error) { flush(); h += '<div class="error" style="margin:6px 0">' + esc(p.error) + '</div>'; }
    else if (!quiet || !/^OK/.test(p.text)) buf.push(p.text);
  }
  flush();
  return h;
}

async function loadQuestions() {
  const text = (await rows(`
select coalesce(json_agg(json_build_object(
  'qid', k.qid, 'set', left(k.qid, 1), 'ordered', k.ordered, 'title', k.title,
  'question', k.question, 'hint', k.hint, 'check_sql', k.check_sql,
  'passed', coalesce((select bool_or(a.passed) from attempts a where a.qid = k.qid), false),
  'tries', (select count(*) from attempts a where a.qid = k.qid),
  'fails', (select count(*) from attempts a where a.qid = k.qid and not a.passed),
  'last_sql', (select a.sql_text from attempts a where a.qid = k.qid order by a.tried_at desc limit 1)
) order by k.seq), '[]')
from answer_key k`))[0][0];
  return JSON.parse(text);
}

async function loadTables(set) {
  const names = TableSets[set];
  if (!names) throw new Error('unknown table set ' + set);
  const arr = names.map(n => "'" + n + "'").join(', ');
  return JSON.parse((await rows(
    'select json_agg(table_preview(n) order by o) from unnest(array[' + arr + ']) with ordinality as x(n, o)'))[0][0]);
}

async function runSql(sql) {
  if (isSingleQuery(sql)) {
    try { return { kind: 'table', table: firstTable(await db('exec', sql)) }; }
    catch (e) { if (e instanceof SqlError) return { kind: 'error', error: psqlError(e, sql) }; throw e; }
  }
  const s = await runScript(sql);
  return { kind: 'script', parts: s.parts };
}

async function submitSql(qid, sql) {
  const infoRows = await rows("select check_sql, title, convert_from(decode(ref, 'base64'), 'UTF8') from answer_key where qid = upper($1)", [qid]);
  if (!infoRows.length) throw new Error('no question ' + qid);
  const info = { check_sql: infoRows[0][0], title: infoRows[0][1], ref: infoRows[0][2] };
  const result = { qid: qid.toUpperCase() };

  let graded = sql, src = null;
  if (info.check_sql) {
    // Run the student's code (CREATE FUNCTION / VIEW / TRIGGER ...) for real, then grade check_sql.
    if (sql.trim() !== '') {
      result.script = await runScript(sql);
    }
    graded = info.check_sql;
    src = sql;
  }

  let lines;
  try {
    const out = await rows('select * from practice.submit($1, $2, $3)', [qid, graded, src]);
    lines = out.map(r => String(r[0])).filter(l => l.trim() !== '')
      .filter(l => !l.includes('Rows print as')).map(l => l.trim());
  } catch (e) {
    if (!(e instanceof SqlError)) throw e;
    lines = [psqlError(e, null)];
  }
  // The Windows kit told the student to "run it on its own in psql"; there is no psql here.
  lines = lines.filter(l => !l.startsWith('Your query did not run. Run it on its own in psql'));

  const passed = lines.length > 0 && /^PASS/.test(lines[0]);
  result.passed = passed;
  result.skipped = lines.length > 0 && lines[0].startsWith('-');
  result.messages = lines;
  if (passed) result.title = info.title;

  const sqlError = lines.length > 0 && lines[0].startsWith('X  SQL error');
  if (sqlError && !info.check_sql) result.messages = ["Your query has an error. PostgreSQL's message is below."];

  if (isSingleQuery(graded)) {
    result.mine = await queryTable(graded, true);
  } else if (!info.check_sql && sql.trim() !== '') {
    // Not a plain query (typo, several statements, ...): show what PostgreSQL says, without keeping changes.
    const body = sql.trim().replace(/;+$/, '');
    try {
      await db('exec', TX_PREFIX + body + '\n;\nrollback;');
      result.mine = { error: 'Only a single SELECT query can be graded here.' };
    } catch (e) {
      if (!(e instanceof SqlError)) throw e;
      result.mine = { error: psqlError(e, body, TX_PREFIX.length) };
    }
  }
  if (!passed && !result.skipped && isSingleQuery(info.ref)) {
    result.expected = await queryTable(info.ref, true);
  }
  return result;
}

async function getSolution(qid) {
  return oneJson("select json_build_object('title', title, 'check_sql', check_sql, " +
    "'ref', convert_from(decode(ref, 'base64'), 'UTF8'), 'explain', b64d(explain)) " +
    'from answer_key where qid = upper($1)', [qid]);
}

/* ---------- installing / updating the practice data ---------- */
// (Re)creates the practice schema from data/setup.sql, checks the answer key, keeps `backup` attempts.
// Returns the failing rows of the answer-key self-test (empty when all is well).
async function installSetup(backup) {
  const resp = await fetch('data/setup.sql', { cache: 'no-cache' });
  if (!resp.ok) throw new Error('Could not download data/setup.sql (' + resp.status + ').');
  await db('exec', await resp.text(), undefined, SETUP_TIMEOUT_MS);
  // verify_key() empties the attempts table, so it runs before the old attempts are put back.
  const bad = await rows("select question, result from practice.verify_key() where result not like 'PASS%'", undefined, SETUP_TIMEOUT_MS);
  if (backup.length) {
    await rows(
      'insert into practice.attempts (qid, passed, tried_at, sql_text) ' +
      'select x.qid, x.passed::boolean, x.tried_at::timestamp, x.sql_text ' +
      'from json_to_recordset(($1::text)::json) as x(qid text, passed text, tried_at text, sql_text text) ' +
      'where x.qid in (select qid from practice.answer_key) order by x.tried_at::timestamp',
      [JSON.stringify(backup)], SETUP_TIMEOUT_MS);
  }
  await db('exec', 'create table practice.kit_info(version text); insert into practice.kit_info values (' +
    "'" + String(meta.version).replace(/'/g, "''") + "');");
  return bad;
}

async function bootDatabase() {
  await readyP;
  const st = (await rows("select to_regclass('practice.kit_info') is not null, to_regclass('practice.attempts') is not null"))[0];
  const hasInfo = st[0] === 't', hasAttempts = st[1] === 't';
  let stored = null;
  if (hasInfo) {
    const r = await rows('select version from practice.kit_info limit 1');
    stored = r.length ? r[0][0] : null;
  }
  if (hasInfo && stored === meta.version) return { updated: false, bad: [] };
  let backup = [];
  if (hasAttempts) {
    try {
      backup = (await rows('select qid, passed, tried_at::text, sql_text from practice.attempts'))
        .map(r => ({ qid: r[0], passed: r[1], tried_at: r[2], sql_text: r[3] }));
    } catch { backup = []; }
  }
  const bad = await installSetup(backup);
  return { updated: hasInfo, bad };
}

function showAlerts(boot) {
  const box = $('alerts');
  box.innerHTML = '';
  if (boot.bad && boot.bad.length) {
    box.innerHTML += '<div class="banner bad"><div class="big">The answer key failed its self-test</div>' +
      '<div class="msg">Some reference answers did not pass. Please report this.</div><pre>' +
      esc(boot.bad.map(r => r[0] + '  ' + r[1]).join('\n')) + '</pre></div>';
  }
  if (boot.updated) {
    const div = document.createElement('div');
    div.className = 'banner info';
    div.innerHTML = '<button class="btn small dismiss">Dismiss</button><div class="msg">' +
      esc('The question set was updated. Your progress was kept; functions, views and triggers you created were reset.') + '</div>';
    div.querySelector('button').onclick = () => div.remove();
    box.appendChild(div);
  }
}

/* ---------- sidebar & progress ---------- */
function setOf(q) { return sets.find(s => s.letter === q.set) || { title: q.set }; }
function renderNav() {
  const nav = $('nav');
  nav.innerHTML = '';
  for (const s of sets) {
    const qs = questions.filter(q => q.set === s.letter);
    if (!qs.length) continue;
    const done = qs.filter(q => q.passed).length;
    const div = document.createElement('div');
    div.className = 'set' + (load('collapsed:' + s.letter) === '1' ? ' collapsed' : '');
    div.innerHTML = '<div class="set-head"><span>' + esc(s.title) + '</span><span class="count">' + done + '/' + qs.length + '</span></div><div class="qlist"></div>';
    div.querySelector('.set-head').onclick = () => {
      div.classList.toggle('collapsed');
      store('collapsed:' + s.letter, div.classList.contains('collapsed') ? '1' : '0');
    };
    const list = div.querySelector('.qlist');
    for (const q of qs) {
      const b = document.createElement('button');
      b.className = 'qbtn' + (q.passed ? ' passed' : q.tries > 0 ? ' tried' : '') + (current && q.qid === current.qid ? ' current' : '');
      b.textContent = q.qid;
      b.title = q.passed ? 'Passed' : q.tries > 0 ? 'Tried ' + q.tries + 'x' : 'Not tried yet';
      b.onclick = () => select(q.qid);
      list.appendChild(b);
    }
    nav.appendChild(div);
  }
  const done = questions.filter(q => q.passed).length;
  const pct = questions.length ? Math.round(100 * done / questions.length) : 0;
  $('bar').style.width = pct + '%';
  $('pct').textContent = done + ' / ' + questions.length + ' passed · ' + pct + '% complete';
  if (current) {
    const qs = questions.filter(q => q.set === current.set);
    $('qpos').textContent = setOf(current).title + ' · question ' + (qs.indexOf(current) + 1) + ' of ' + qs.length;
  }
}

/* ---------- question card ---------- */
function tableSetFor(q) { return q.set === 'L' ? 'shop' : q.set === 'G' ? 'plpg' : 'uni'; }
const tableSetNames = { shop: 'shop schema', uni: 'university schema', plpg: 'university schema + PL/pgSQL tables' };

function select(qid) {
  const q = questions.find(x => x.qid === qid);
  if (!q) return;
  if (current) store('draft:' + current.qid, $('editor').value);
  current = q;
  store('current', qid);
  location.hash = qid;
  $('qtitle').textContent = q.qid + (q.passed && q.title ? ' · ' + q.title : '');
  $('qsub').innerHTML = esc(setOf(q).title) + (q.ordered ? '<span class="tag">row order is checked</span>' : '');
  $('qtext').innerHTML = (q.question || '').split('\n').map(inline).join('<br>');
  $('checknote').innerHTML = q.check_sql
    ? '<div class="note">Run &amp; Submit first runs <b>your code</b> (creating your function / view / trigger), then grades: <code>' + esc(q.check_sql) + '</code></div>'
    : '';
  $('hintbox').innerHTML = '';
  $('hintBtn').style.display = q.hint ? '' : 'none';
  $('hintBtn').textContent = 'Show a hint';
  $('editor').placeholder = q.check_sql ? 'Write your CREATE ... statement here...' : 'Write your SELECT statement here...';
  const draft = load('draft:' + qid);
  $('editor').value = draft !== null ? draft : (q.last_sql || '');
  $('result').innerHTML = '';
  $('solution').innerHTML = '';
  updateAttempts();
  renderNav();
  showTables(tableSetFor(q));
  $('editor').focus();
}
function updateAttempts() {
  const q = current;
  $('attempts').textContent = q.passed ? '✓ Passed (' + q.tries + ' attempt' + (q.tries === 1 ? '' : 's') + ')'
    : q.tries ? 'Attempt ' + (q.tries + 1) + ', keep trying, there is no limit' : 'Attempt 1';
}
function nextQuestion() {
  const i = questions.indexOf(current);
  const after = questions.slice(i + 1).concat(questions.slice(0, i));
  const next = after.find(q => q.set === current.set && !q.passed) || after.find(q => !q.passed) || questions[(i + 1) % questions.length];
  select(next.qid);
}

/* ---------- actions ---------- */
async function run() {
  const sql = $('editor').value;
  if (!sql.trim()) return;
  store('draft:' + current.qid, sql);
  busy(true);
  try {
    const r = await runSql(sql);
    let h = '<div class="outputs"><div><h4>Output (not graded)</h4>';
    if (r.kind === 'table') h += tableHtml(r.table);
    else if (r.kind === 'error') h += '<div class="error">' + esc(r.error) + '</div>';
    else h += partsHtml(r.parts, false) || '<pre class="out">(done, no output)</pre>';
    $('result').innerHTML = h + '</div></div>';
    if (r.kind === 'script') refreshTables();
  } catch (e) { showError(e); }
  busy(false);
}

async function submit() {
  const sql = $('editor').value;
  store('draft:' + current.qid, sql);
  busy(true);
  try {
    const q = current;
    const r = await submitSql(q.qid, sql);
    let h = '';
    if (r.skipped) {
      h += '<div class="banner info"><div class="big">Nothing to submit yet</div><div class="msg">Write a query in the box first.</div></div>';
    } else {
      q.tries += 1;
      if (r.passed) { q.passed = true; if (r.title) q.title = r.title; }
      else q.fails += 1;
      q.last_sql = sql;
      if (r.passed) {
        h += '<div class="banner ok"><div class="big">✓ Correct!</div><div class="msg">' + esc(r.messages[0].replace(/^PASS\s+\S+\s*/, '')) +
             (q.title ? ' · Topic: ' + esc(q.title) : '') + '</div></div>';
      } else {
        const msgs = r.messages.map(m => m.replace(/^X\s+/, '')).join('\n');
        h += '<div class="banner bad"><div class="big">✗ Not yet</div><div class="msg">' + esc(msgs) + '</div></div>';
      }
    }
    if (r.script !== undefined) {
      let body;
      body = partsHtml(r.script.parts, true) || '<pre class="out">Your code ran without errors.</pre>';
      h += '<div style="margin-bottom:12px"><h4 style="margin:0 0 6px;font-size:12px;color:var(--muted);text-transform:uppercase;letter-spacing:.04em">Running your code</h4>' +
           body + '</div>';
    }
    if (r.mine || r.expected) {
      h += '<div class="outputs">';
      if (r.mine) h += '<div><h4>Your output</h4>' + tableHtml(r.mine) + '</div>';
      if (r.expected) h += '<div><h4>Expected output</h4>' + tableHtml(r.expected) + '</div>';
      h += '</div>';
    }
    $('result').innerHTML = h;
    $('qtitle').textContent = q.qid + (q.passed && q.title ? ' · ' + q.title : '');
    updateAttempts();
    renderNav();
    if (q.check_sql) refreshTables();
  } catch (e) { showError(e); }
  busy(false);
}

async function showSolution() {
  const q = current;
  if (!q.passed && q.fails < 2) {
    $('solution').innerHTML = '<div class="banner info">Submit at least two real attempts first. Being stuck for a while is the part that teaches you. Try the hint!</div>';
    return;
  }
  if (!q.passed && !confirm('Show the solution? You learn more from one more try. After reading it, come back to this question later and write it again from scratch.')) return;
  try {
    const s = await getSolution(q.qid);
    let h = '<div class="solution"><h3 style="margin:0 0 6px">Solution · ' + esc(s.title || '') + '</h3>';
    if (s.check_sql) h += md(s.explain) + '<p class="qsub">Checked with this equivalent query:</p><pre><code>' + esc(s.ref) + '</code></pre>';
    else h += '<pre><code>' + esc(s.ref) + '</code></pre>' + md(s.explain);
    $('solution').innerHTML = h + '</div>';
  } catch (e) { showError(e); }
}

function showError(e) {
  const stopped = e instanceof TimeoutError;
  $('result').innerHTML = '<div class="banner bad"><div class="big">' + (stopped ? 'Query stopped' : 'Something went wrong') +
    '</div><div class="msg">' + esc(psqlError(e, null)) + '</div></div>';
}
function busy(on) {
  for (const id of ['runBtn', 'submitBtn', 'resetBtn']) $(id).disabled = on;
  $('submitBtn').textContent = on ? 'Running…' : 'Run & Submit';
}

/* ---------- tables panel ---------- */
async function showTables(set, force) {
  if (set !== currentTableSet) { currentTableSet = set; currentTab = null; }
  $('schemaName').textContent = '· ' + tableSetNames[set];
  if (!tableCache[set] || force) {
    try { tableCache[set] = await loadTables(set); }
    catch (e) { $('tableView').innerHTML = '<div class="error">' + esc(psqlError(e, null)) + '</div>'; return; }
  }
  const tabs = tableCache[set].filter(Boolean);
  if (!currentTab || !tabs.find(t => t.name === currentTab)) currentTab = tabs[0].name;
  $('tabs').innerHTML = '';
  for (const t of tabs) {
    const b = document.createElement('button');
    b.className = 'tab' + (t.name === currentTab ? ' active' : '');
    b.textContent = t.name + ' (' + t.rows.length + ')';
    b.onclick = () => { currentTab = t.name; showTables(set); };
    $('tabs').appendChild(b);
  }
  const t = tabs.find(x => x.name === currentTab);
  $('tableView').innerHTML = '<div class="mono" style="font-size:13px;color:var(--muted);margin-bottom:6px">' +
    esc(t.name) + '(' + t.columns.map(esc).join(', ') + ')</div>' + tableHtml(t);
}
function refreshTables() { if (currentTableSet) showTables(currentTableSet, true); }

/* ---------- reset ---------- */
async function resetProgress() {
  if (!confirm('Reset all progress? Your passed questions, attempts and the functions, views and triggers you created will be deleted, and the practice data starts fresh.')) return;
  busy(true);
  try {
    const bad = await installSetup([]);
    try {
      for (let i = localStorage.length - 1; i >= 0; i--) {
        const k = localStorage.key(i);
        if (k && k.startsWith('draft:')) localStorage.removeItem(k);
      }
    } catch {}
    for (const k of Object.keys(tableCache)) delete tableCache[k];
    questions = await loadQuestions();
    showAlerts({ updated: false, bad });
    const id = current ? current.qid : null;
    current = null;
    select(questions.find(q => q.qid === id) ? id : questions[0].qid);
    $('result').innerHTML = '<div class="banner info"><div class="msg">Progress was reset.</div></div>';
  } catch (e) { showError(e); }
  busy(false);
}

/* ---------- wiring ---------- */
$('runBtn').onclick = run;
$('submitBtn').onclick = submit;
$('nextBtn').onclick = nextQuestion;
$('solBtn').onclick = showSolution;
$('refreshTables').onclick = refreshTables;
$('resetBtn').onclick = resetProgress;
$('hintBtn').onclick = () => {
  const open = $('hintbox').innerHTML !== '';
  $('hintbox').innerHTML = open ? '' : '<div class="hint">' + inline(current.hint) + '</div>';
  $('hintBtn').textContent = open ? 'Show a hint' : 'Hide hint';
};
$('editor').addEventListener('input', () => { if (current) store('draft:' + current.qid, $('editor').value); });
$('editor').addEventListener('keydown', e => {
  if (e.key === 'Enter' && (e.ctrlKey || e.metaKey)) { e.preventDefault(); if (current) submit(); return; }
  if (e.key === 'Tab' && !e.shiftKey) {
    e.preventDefault();
    const t = e.target, s = t.selectionStart;
    t.setRangeText('  ', s, t.selectionEnd, 'end');
  }
});
window.addEventListener('hashchange', () => {
  const id = decodeURIComponent(location.hash.slice(1));
  if (current && id !== current.qid && questions.find(q => q.qid === id)) select(id);
});

function showStartupProblem(title, html) {
  $('qtitle').textContent = title;
  $('qtext').innerHTML = html;
  $('qpos').textContent = 'Not connected';
  for (const id of ['hintBtn', 'solBtn', 'runBtn', 'submitBtn', 'nextBtn']) $(id).style.display = 'none';
  $('editor').style.display = 'none';
  document.querySelector('.kbd').style.display = 'none';
}

(async function init() {
  if (!/^https?:$/.test(location.protocol)) return;   // index.html already explains this
  $('resetBtn').disabled = true;
  $('qtitle').textContent = 'Loading…';
  $('qtext').textContent = 'Setting up the practice database (first time only, about 10 seconds)…';
  let boot;
  try {
    const resp = await fetch('data/meta.json', { cache: 'no-cache' });
    if (!resp.ok) throw new Error('Could not download data/meta.json (' + resp.status + ').');
    meta = await resp.json();
    sets = meta.sets;
    startWorker();
    boot = await bootDatabase();
    questions = await loadQuestions();
  } catch (e) {
    showStartupProblem('The practice database could not start',
      esc(psqlError(e, null)) + '<br><br>Reload the page to try again. Private or incognito windows can block the browser ' +
      'storage the database needs; try a normal window.');
    return;
  }
  $('resetBtn').disabled = false;
  showAlerts(boot);
  const fromHash = decodeURIComponent(location.hash.slice(1));
  const saved = load('current');
  const start = questions.find(q => q.qid === fromHash) || questions.find(q => q.qid === saved)
             || questions.find(q => q.set === 'L' && !q.passed) || questions[0];
  select(start.qid);
})();
