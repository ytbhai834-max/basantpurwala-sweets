BASANTPURWALA SWEETS — UPDATED PACKAGE

Files:
- index.html: original customer website preserved with customer account, Google/email auth, My Orders, offers, notifications, reviews and loyalty display.
- admin.html: existing owner panel preserved with offers/reviews/notification/loyalty management sections.
- supabase_migration.sql: additive database migration. BACKUP first and review policies before running.

IMPORTANT SETUP
1. Keep your existing config.js in the same GitHub Pages folder. Do not replace its public Supabase URL/key. Never add service-role key.
2. Back up the Supabase database and current GitHub files.
3. Review and run supabase_migration.sql in Supabase SQL Editor. This migration adds user_id to orders and new tables/policies. It does NOT automatically remove the old permissive anonymous order-insert policy; review that policy after the authenticated checkout is verified.
4. Supabase Auth: enable Email provider and configure Google provider. Add https://ytbhai834-max.github.io/basantpurwala-sweets/ to Site URL/Redirect URLs. Google OAuth also needs its provider callback configured in Google Cloud.
5. Existing storage bucket product-images and its policies remain required for admin product image uploads.
6. Customer notifications in this package are in-site notifications. True background push delivery requires a secure server-side Edge Function and VAPID keys. No private key is included.
7. Loyalty earn trigger awards points after an order becomes Completed and reverses earned points on cancellation. Values are admin-configurable in loyalty_config. Redemption UI is not enabled in this build because secure redemption needs a server-validated checkout RPC and the existing checkout schema has no verified discount fields.

DEPLOY
Replace index.html and admin.html in the existing GitHub repository root. Keep config.js, product assets, and shop QR image unchanged. Commit changes and wait for GitHub Pages deployment. Test with a separate customer account and a small test order before real orders.

TEST STATUS
Static file generation and JavaScript syntax validation are performed before delivery. Live Supabase CRUD, OAuth, RLS, Storage upload, and GitHub Pages behavior are NOT verified from this package build.
