-- ═══════════════════════════════════════════════════════════════════════════════
-- MIGRATION: Fix RLS policies and order status constraint
-- Run this in Supabase SQL Editor to fix the existing database.
-- This is safe to run multiple times (uses IF NOT EXISTS / DROP IF EXISTS).
-- ═══════════════════════════════════════════════════════════════════════════════

-- 1. Add user_id column to categories if it doesn't exist
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_schema = 'public' AND table_name = 'categories' AND column_name = 'user_id'
    ) THEN
        ALTER TABLE public.categories ADD COLUMN user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE;
    END IF;
END $$;

-- 2. Add indexes if they don't exist
CREATE INDEX IF NOT EXISTS idx_products_user_id ON public.products(user_id);
CREATE INDEX IF NOT EXISTS idx_clients_user_id ON public.clients(user_id);
CREATE INDEX IF NOT EXISTS idx_orders_user_id ON public.orders(user_id);
CREATE INDEX IF NOT EXISTS idx_categories_user_id ON public.categories(user_id);
CREATE INDEX IF NOT EXISTS idx_order_line_items_order_id ON public.order_line_items(order_id);

-- 3. Enable RLS on ALL tables
ALTER TABLE public.products ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.clients ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.orders ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.order_line_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.categories ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.conversations ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.messages ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.business_settings ENABLE ROW LEVEL SECURITY;

-- 4. Drop existing RLS policies and recreate them (safe, idempotent)
DROP POLICY IF EXISTS "Users can manage their own products" ON public.products;
DROP POLICY IF EXISTS "Users can manage their own clients" ON public.clients;
DROP POLICY IF EXISTS "Users can manage their own orders" ON public.orders;
DROP POLICY IF EXISTS "Users can manage items of their orders" ON public.order_line_items;
DROP POLICY IF EXISTS "Users can manage their own categories" ON public.categories;
DROP POLICY IF EXISTS "Users can manage their own conversations" ON public.conversations;
DROP POLICY IF EXISTS "Users can manage messages of their conversations" ON public.messages;
DROP POLICY IF EXISTS "Users can manage their own business settings" ON public.business_settings;

-- Products
CREATE POLICY "Users can manage their own products"
    ON public.products FOR ALL USING (auth.uid() = user_id);

-- Clients
CREATE POLICY "Users can manage their own clients"
    ON public.clients FOR ALL USING (auth.uid() = user_id);

-- Orders
CREATE POLICY "Users can manage their own orders"
    ON public.orders FOR ALL USING (auth.uid() = user_id);

-- Order line items
CREATE POLICY "Users can manage items of their orders"
    ON public.order_line_items FOR ALL USING (
        order_id IN (SELECT id FROM public.orders WHERE user_id = auth.uid())
    );

-- Categories
CREATE POLICY "Users can manage their own categories"
    ON public.categories FOR ALL USING (auth.uid() = user_id);

-- Conversations
CREATE POLICY "Users can manage their own conversations"
    ON public.conversations FOR ALL USING (auth.uid() = user_id);

-- Messages
CREATE POLICY "Users can manage messages of their conversations"
    ON public.messages FOR ALL USING (
        conversation_id IN (
            SELECT id FROM public.conversations WHERE user_id = auth.uid()
        )
    );

-- Business Settings
CREATE POLICY "Users can manage their own business settings"
    ON public.business_settings FOR ALL USING (auth.uid() = user_id);

-- 5. Fix the orders_status_check constraint
--    Drop the old one (might have wrong values) and recreate with correct ones.
DO $$
BEGIN
    IF EXISTS (
        SELECT 1 FROM pg_constraint
        WHERE conname = 'orders_status_check'
          AND conrelid = 'public.orders'::regclass
    ) THEN
        ALTER TABLE public.orders DROP CONSTRAINT orders_status_check;
    END IF;
END $$;

ALTER TABLE public.orders
    ADD CONSTRAINT orders_status_check
    CHECK (status IN ('Pending','Processing','Shipped','Delivered','Cancelled'));

-- ═══════════════════════════════════════════════════════════════════════════════
-- DONE! After running this:
--   • service_role key (used by Node.js backend) bypasses all RLS → always works
--   • If a user token is ever used, RLS policies now exist for all tables
--   • orders_status_check now accepts: Pending, Processing, Shipped, Delivered, Cancelled
-- ═══════════════════════════════════════════════════════════════════════════════
