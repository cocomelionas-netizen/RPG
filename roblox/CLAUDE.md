# Endless Road – Roblox version: notes for Claude

These rules override the root CLAUDE.md for any work on the Roblox version:

- Talk to the user in Lithuanian; game text stays in English.
- Work only inside `roblox/` on branch `roblox` (`git push -u origin roblox`).
- Never push to `main` (it deploys the live web game) and never touch the web game files
  (`index.html`, `sw.js`, `build.js`, `supabase/`, `wrangler.jsonc`, ...). Use them only as the source of data and rules.
- Rojo project: `default.project.json`, `src/server`, `src/client`, `src/shared`. Test in Roblox Studio via `rojo serve`.
- Never ask for passwords, tokens or API keys in chat.
- LICENSE: all rights reserved.
- Plan: 1) road, gathering, bag, XP, DataStore saves, offline progress (done) 2) combat, enemies, weapons, armour
  3) crafting skills, quests, agility 4) house, pets, PvP, clans, Robux shop.
