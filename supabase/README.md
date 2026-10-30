# Endless Road online (Supabase)

The game talks to the Supabase project `ntvuqakhgcogxxhzkvex` with its publishable key, which is safe in a browser.
All protection lives in the database:

- Row Level Security on every table. Players read only their own save; profiles and hiscores are public.
- No insert/update/delete rights for browsers at all. Writes go through `claim_name` and `sync_save`.
- `sync_save` compares every upload with the last accepted save using the server clock and refuses
  impossible progress (XP per skill and in total, wealth, kills). Refusals are logged in `cheat_flags`
  and the player gets the last good save back.

## Setup

1. Supabase → SQL Editor → New query → paste `schema.sql` → Run. Running it again is safe
   (do it after item values change).
2. Authentication → Sign In / Providers → Email → turn off **Confirm email**
   (accounts use a hero name, not a real email address).

## Moderation

- Suspicious uploads: `select * from cheat_flags order by created_at desc;`
- Ban: `update profiles set banned = true where name = 'Name';` (hidden from hiscores, uploads refused).
