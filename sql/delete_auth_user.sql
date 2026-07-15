-- WARNING: This will delete the user authentication account permanently.
-- This allows you to register again with the same email.

-- Delete from auth.users (Cascade should handle public.users if configured, otherwise delete manually first)
-- Replace the placeholder below with the target account's email before running.
DELETE FROM auth.users WHERE email = 'REPLACE_WITH_TARGET_EMAIL@example.com';

-- If you want to clean up ALL users to start fresh (BE CAREFUL):
-- DELETE FROM auth.users;
