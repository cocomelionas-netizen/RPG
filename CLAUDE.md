# Endless Road RPG – notes for Claude

- Talk to the user in Lithuanian; game text stays in English.
- The game is hosted for free on GitHub Pages: https://cocomelionas-netizen.github.io/RPG/ (workflow `.github/workflows/pages.yml`,
  deploys on every push to `main`). Push fixes to `main` straight away – the user wants them live immediately.
- Netlify is retired: `netlify.toml` skips every build (credits). Its last deploy only shows a "moved" banner. Don't re-enable it.
- Bump the cache version in `sw.js` once per release.
- Server SQL lives in `supabase/schema.sql` (idempotent). The user runs it in the Supabase SQL Editor, often from a phone:
  it is readable as plain text at https://cocomelionas-netizen.github.io/RPG/schema.txt (copied there by the Pages workflow).
- Never ask for or put the Supabase secret key in the game; the publishable key is fine.
