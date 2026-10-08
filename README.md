# SWE3003 SQL Practice

A practice website for SQL, written for students of SWE3003 (Database Systems). Pick a question,
type your SQL, press **Run & Submit**, and see right away whether it is correct. If it is not, you
see your output next to the expected output.

It runs entirely in your browser. The database is [PGlite](https://pglite.dev) (PostgreSQL compiled
to WebAssembly), so there is nothing to install and no server to set up.

## What is in it

63 questions:

- 12 lesson questions on a small shop schema (`seller`, `item`, `buyer`, `orders`, `order_details`)
- 51 questions on the university schema: `SELECT`, `NULL`, `GROUP BY` / `HAVING`, joins and
  self-joins, subqueries, `EXISTS`, `WITH`, outer joins, views, and PL/pgSQL functions and triggers

Hints, solutions (after two real attempts), table previews, and your progress are included.

## How to use it

Open the site in a current Chrome, Edge, Firefox or Safari, on Windows, macOS or Linux.

- The first visit takes about 10 seconds: the browser downloads the database engine and creates the
  practice data. After that the site starts quickly.
- Left: the questions. Green = passed, red = tried.
- **Run** just runs your SQL without grading. **Run & Submit** (or Ctrl+Enter) grades it.
- Row order is only checked when the question says so. Column names do not matter; column order does.
- For function, view and trigger questions, write the `CREATE` statement; Run & Submit creates it
  and then checks it.
- A query that runs for more than 10 seconds is stopped (a missing join condition is the usual
  cause). Your progress is not lost.
- **Reset progress** (top right) deletes your attempts and the objects you created and starts over.

Your progress and drafts are stored in this browser (IndexedDB and localStorage). Clearing the
site data, or using a private window, removes them. Open the site in one tab at a time.

PGlite currently runs PostgreSQL 18, so a few error messages can differ from an older PostgreSQL
server.

## Publish it with GitHub Pages

1. Put this folder at the root of a GitHub repository (`index.html` at the top level).
2. In the repository: **Settings -> Pages -> Build and deployment -> Deploy from a branch**.
3. Choose branch `main` and folder `/ (root)`, then Save.
4. After a minute the site is live at `https://<user>.github.io/<repository>/`.

The empty `.nojekyll` file tells GitHub Pages to serve the files as they are.

## Run it locally

Opening `index.html` directly from the disk does not work (browsers block the scripts it needs).
Start any small web server in this folder, for example:

```
python3 -m http.server 8000
```

and open <http://localhost:8000>.

## Files

- `index.html`, `app.js`: the page and its logic
- `worker.js`: runs PGlite in a Web Worker, so a slow query can be stopped
- `data/setup.sql`: the practice database (tables, sample data, questions, checker)
- `data/meta.json`: the version of `setup.sql` and the list of question sets. When the version
  changes, the site rebuilds the data and keeps your attempts.

## Privacy

There is no server, no account and no tracking. Nothing you type is uploaded anywhere. The only
network requests are for this site's own files and for the PGlite engine files, which are loaded
from the jsDelivr CDN (`cdn.jsdelivr.net`).

## Disclaimer

This is an unofficial practice site. It is not affiliated with SKKU or with the course, and it may
contain mistakes. Always follow your course's own instructions and materials.

## Credits

- The university schema and its sample data are adapted from Silberschatz, Korth and Sudarshan,
  *Database System Concepts*, [db-book.com](https://www.db-book.com).
- [PGlite](https://pglite.dev) by ElectricSQL (Apache-2.0 / PostgreSQL license).
- [PostgreSQL](https://www.postgresql.org).

## License

MIT, see [LICENSE](LICENSE).
