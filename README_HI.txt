BASANTPURWALA SWEETS — SECURE STARTER
=====================================

Is package mein:
- Customer website (index.html): menu browse, category filter, cart, order submission
- Owner admin (admin.html): Supabase login ke baad products aur orders manage karne ka starter panel
- supabase_schema.sql: database tables + Row Level Security (RLS) policies

IMPORTANT:
Yeh abhi LIVE/DEPLOYED website nahi hai. Secure login/database chalane ke liye Supabase project banana, SQL chalana, public project URL + anon key config karna, owner account create karna, aur hosting par deploy karna zaroori hai.
Service-role key kabhi browser mein mat daalna.

SETUP:
1. supabase.com par project create karein.
2. SQL Editor mein supabase_schema.sql ka poora SQL run karein.
3. Authentication > Users mein owner ka account create karein (email/password).
4. SQL Editor mein neeche wali command run karke owner UID set karein:
   insert into public.shop_admins (user_id) values ('OWNER-AUTH-USER-UUID');
   UUID ko Authentication > Users mein owner ke actual UID se replace karein.
5. index.html aur admin.html mein SUPABASE_URL aur SUPABASE_ANON_KEY values apne Project Settings > API se replace karein.
6. index.html, admin.html ko HTTPS hosting par publish karein (e.g. Netlify/Vercel/static host). Database Supabase mein rahega.
7. Customer link public share karein. Admin page ka URL sirf owner ko batayein. Security asal mein database RLS se enforce hoti hai, URL chhupane se nahi.

Payment:
Starter checkout order ko database mein save karta hai aur Cash/UPI QR payment preference record karta hai. QR image abhi configured nahi. UPI payment ka auto verification is package mein nahi hai. Owner ko apna QR upload/host karna aur verified payment flow separately setup karna hoga.


PICTURES:
assets/ folder mein named SVG product illustrations bundled hain. Ye website ke demo/fallback product visuals hain; asli product photography available hone par admin panel mein image URLs ko apni product photos se replace karein. Hero aur product pictures local hain, isliye in visuals ke liye external image hosting ki zaroorat nahi.
