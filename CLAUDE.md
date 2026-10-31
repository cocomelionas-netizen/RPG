# Endless Road RPG – notes for Claude

- Talk to the user in Lithuanian; game text stays in English.
- Netlify (https://endless-road-rpg.netlify.app) auto-deploys every push to `main`, and every production deploy costs Netlify credits.
  **Work and push on the `dev` branch.** Merge `dev` into `main` and push `main` only when the user asks to release ("išleisk").
  Batch changes so a release is one deploy.
- Bump the cache version in `sw.js` once per release.
- Server SQL lives in `supabase/schema.sql` (idempotent). The user runs it in the Supabase SQL Editor, often from a phone:
  it is readable at https://endless-road-rpg.netlify.app/supabase/schema.sql (served as plain text via `_headers`).
- Never ask for or put the Supabase secret key in the game; the publishable key is fine.
