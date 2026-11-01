# Endless Road RPG – notes for Claude

- Talk to the user in Lithuanian; game text stays in English.
- The game lives at https://endless-road.cocomelionas.workers.dev/ (Cloudflare, deploys on every push to `main`).
  The old https://cocomelionas-netizen.github.io/RPG/ (workflow `.github/workflows/pages.yml`) forwards players there with their save
  (`NEW_HOME`). Push fixes to `main` straight away – the user wants them live immediately.
- Netlify is retired: `netlify.toml` skips every build (credits). Its last deploy only shows a "moved" banner. Don't re-enable it.
- Bump the cache version in `sw.js` once per release.
- Server SQL lives in `supabase/schema.sql` (idempotent). The user runs it in the Supabase SQL Editor, often from a phone:
  it is readable as plain text at https://endless-road.cocomelionas.workers.dev/schema.txt (copied by build.js).
  On iPhone send them https://endless-road.cocomelionas.workers.dev/sql.html instead: it has a one-tap "Copy all" button.
- Never ask for or put the Supabase secret key in the game; the publishable key is fine.
- Moving to Cloudflare Workers static assets (project `endless-road` → https://endless-road.cocomelionas.workers.dev,
  git-connected: build `npm run build`, deploy `npx wrangler deploy` with `wrangler.jsonc` serving dist/).
  `build.js` minifies/mangles the game into dist/ (both GitHub Pages and Cloudflare deploy dist/). Test the source, then smoke-test dist.
  When the new address works, set `NEW_HOME` in index.html: the old github.io page then forwards players with their local save (#move=).
  After that the repo can go private (GitHub Pages then stops).
- The server only answers the game's own addresses: `check_origin()` + table `allowed_origins` in schema.sql. A new domain must be added there.
- LICENSE: all rights reserved.
