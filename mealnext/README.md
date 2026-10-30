# MealNext

Recipe platform: browse 30 recipes with embedded YouTube videos, like and comment, and find recipes by the ingredients you have (match percentage).

## Tech stack
| Part | Technology |
|---|---|
| Front-end | HTML5, CSS, JavaScript |
| Backend services | Supabase Authentication + Supabase JS SDK |
| Database | Supabase PostgreSQL |
| Security | Row Level Security (RLS) |
| Automation | PostgreSQL triggers |
| Video | YouTube embeds |
| Editor | Visual Studio Code |

## Setup
1. Create a free project at https://supabase.com
2. SQL Editor -> New query -> paste `supabase/schema.sql` -> Run
3. Authentication -> Sign In / Providers -> Email -> turn OFF "Confirm email" (for easy demo)
4. Project Settings -> API: copy the Project URL and the anon/publishable key into `js/config.js`
5. In VS Code install the "Live Server" extension, right-click `index.html` -> Open with Live Server

## Triggers
- `on_auth_user_created`: creates a profile row when a user signs up
- `trg_like_count` / `trg_comment_count`: keep counters correct
- `trg_clean_comment`: trims and validates comments before saving

## RLS summary
- Recipes, ingredients, links: read-only for everyone
- Comments and likes: anyone reads; only logged-in users add as themselves; only owners delete

## Match percentage
match % = |recipe ingredients ∩ selected ingredients| / |recipe ingredients| x 100
