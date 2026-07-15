-- ⚠️ DANGER: This will delete ALL users and ALL distinct user data permanently!
-- Use this only for development resets.

-- 1. Clean up public tables (Data linked to users)
-- We use TRUNCATE for speed and to clean everything. 
-- CASCADE ensures dependent rows in other tables are also removed.
TRUNCATE TABLE public.analytics CASCADE;
TRUNCATE TABLE public.user_allergens CASCADE;
TRUNCATE TABLE public.logs CASCADE;
TRUNCATE TABLE public.meals CASCADE;

-- 2. Clean up user profiles
TRUNCATE TABLE public.users CASCADE;

-- 3. Delete all authentication accounts from Supabase Auth
-- This allows you to register again with any email.
DELETE FROM auth.users;

-- 4. Output validation
SELECT count(*) as remaining_users FROM auth.users;
