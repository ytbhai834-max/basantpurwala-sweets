Basantpur Sweets Royal Admin V2.0.1 — targeted bug-fix build

Contents:
- admin.html: updated admin panel
- config.js is intentionally NOT included. Keep your existing config.js unchanged.

Fixes:
1. New product with no image now sends image_url as an empty string (schema declares image_url NOT NULL).
2. Product insert/update, visibility toggle, product delete, and order update now request the affected row and show success only when Supabase returns a row. Zero-row operations are reported as errors instead of false success.
3. Empty category defaults to 'mithai' to match the provided schema's default/required category semantics.

Installation:
1. Keep a backup of the current admin.html.
2. Replace only admin.html in the GitHub repository with this file and commit.
3. Do not replace config.js or supabase_schema.sql.
4. Test on the live site: login, add a temporary test product without image, edit it, toggle visibility, then delete it; also test an order status update only if safe. Confirm each action in Supabase.

Important:
- Syntax check passed; this is not a live Supabase integration test.
- Row-return checks require SELECT visibility for the affected row. If RLS denies returning rows, the UI will report that instead of falsely claiming success; review existing policies before changing them.
- Use only your existing Supabase public/publishable anon key in config.js. Never use a service-role key in browser code.
