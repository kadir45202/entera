-- Fix Analytics RLS Policy for Guest and User Access

-- 1. Ensure the analytics table exists and has the correct foreign key (optional but good to verify)
-- Make user_id nullable to allow guest logs if needed, but we prefer linking to guest users
ALTER TABLE IF EXISTS public.analytics 
ALTER COLUMN user_id DROP NOT NULL;

-- 2. Drop existing policies to avoid conflicts
DROP POLICY IF EXISTS "Enable insert for authenticated users only" ON public.analytics;
DROP POLICY IF EXISTS "Enable insert for everyone" ON public.analytics;
DROP POLICY IF EXISTS "Enable select for users based on user_id" ON public.analytics;

-- 3. Create comprehensive INSERT policy
-- Allows any authenticated user (including anonymous/guest) to insert logs
CREATE POLICY "Enable insert for all authenticated users"
ON public.analytics
FOR INSERT
TO authenticated
WITH CHECK (true);  -- Expand to (auth.uid() = user_id) if strict ownership needed, but 'true' is safer for analytics

-- 4. Create SELECT policy (optional, usually analytics are write-only for client)
CREATE POLICY "Enable select for own analytics"
ON public.analytics
FOR SELECT
TO authenticated
USING (auth.uid() = user_id);

-- 5. Fix Foreign Key Constraint
-- The error "violates foreign key constraint analytics_user_id_fkey" means we are trying to insert
-- a user_id into 'analytics' that does not exist in 'users'.
-- This happens if the storage trigger or guest creation logic failed to create the user row first.

-- Ensure we don't have a strict foreign key that blocks valid auth users who might be missing from public.users table due to race conditions
-- Option A: Remove the FK constraint (Safest for raw analytics)
ALTER TABLE public.analytics DROP CONSTRAINT IF EXISTS analytics_user_id_fkey;

-- Option B: Re-add it with ON DELETE SET NULL (Better for data integrity if you want links)
ALTER TABLE public.analytics 
ADD CONSTRAINT analytics_user_id_fkey 
FOREIGN KEY (user_id) 
REFERENCES auth.users(id) 
ON DELETE SET NULL;
-- Note: referencing auth.users is safer than public.users for raw analytics if public.users is managed by triggers

