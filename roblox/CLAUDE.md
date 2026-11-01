# Endless Road – Roblox version: notes for Claude

These rules override the root CLAUDE.md for any work on the Roblox version:

- Talk to the user in Lithuanian; game text stays in English.
- Work only inside `roblox/` on branch `roblox` (`git push -u origin roblox`).
- Never push to `main` (it deploys the live web game) and never touch the web game files
  (`index.html`, `sw.js`, `build.js`, `supabase/`, `wrangler.jsonc`, ...). Use them only as the source of data and rules.
- Rojo project: `default.project.json`, `src/server`, `src/client`, `src/shared`. Test in Roblox Studio via `rojo serve`.
- Never ask for passwords, tokens or API keys in chat.
- LICENSE: all rights reserved.
- Plan (see DESIGN.md): 1) road, gathering, saves, offline (done) 2) house: Construction, Hometown plots, rooms (started)
  3) combat + Wraith Caves PvP 4) Robux shop (gamepasses, boosts, gems, pets, enchants) 5) quests, agility, clans.
- Test with the Roblox Studio MCP (start_stop_play, execute_luau, get_console_output). Use emoji up to Unicode 12 only.
