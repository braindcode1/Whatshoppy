-- Supabase Database Schema
-- Run this ENTIRE script in the Supabase SQL Editor after any migration.

-- ═══════════════════════════════════════════════════════════════════════════════
-- 1. PROFILES TABLE (created by Supabase Auth – included for reference)
-- ═══════════════════════════════════════════════════════════════════════════════
-- If not already created, run:
-- CREATE TABLE IF NOT EXISTS public.profiles (
--     id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
--     email TEXT NOT NULL,
--     role TEXT NOT NULL DEFAULT 'admin',
--     created_at TIMESTAMPTZ DEFAULT now()
-- );

-- ═══════════════════════════════════════════════════════════════════════════════
-- 2. CATEGORIES TABLE
-- ═══════════════════════════════════════════════════════════════════════════════
CREATE TABLE IF NOT EXISTS public.categories (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    nom VARCHAR(255) NOT NULL,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now())
);

-- ═══════════════════════════════════════════════════════════════════════════════
-- 3. PRODUCTS TABLE
-- ═══════════════════════════════════════════════════════════════════════════════
CREATE TABLE IF NOT EXISTS public.products (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    name VARCHAR(255) NOT NULL,
    sku VARCHAR(100),
    category VARCHAR(100) DEFAULT 'General',
    price NUMERIC(12,2) NOT NULL DEFAULT 0,
    stock INTEGER NOT NULL DEFAULT 0,
    description TEXT DEFAULT '',
    image TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now())
);

-- ═══════════════════════════════════════════════════════════════════════════════
-- 4. CLIENTS TABLE
-- ═══════════════════════════════════════════════════════════════════════════════
CREATE TABLE IF NOT EXISTS public.clients (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    name VARCHAR(255) NOT NULL,
    phone VARCHAR(50) DEFAULT '',
    address TEXT DEFAULT '',
    last_active TIMESTAMP WITH TIME ZONE,
    orders_count INTEGER DEFAULT 0,
    avatar_color VARCHAR(20),
    tags JSONB DEFAULT '[]'::jsonb,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now())
);

-- ═══════════════════════════════════════════════════════════════════════════════
-- 5. ORDERS TABLE
-- ═══════════════════════════════════════════════════════════════════════════════
CREATE TABLE IF NOT EXISTS public.orders (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    client_id UUID NOT NULL REFERENCES public.clients(id) ON DELETE CASCADE,
    order_number VARCHAR(100),
    items_count INTEGER DEFAULT 0,
    total NUMERIC(12,2) DEFAULT 0,
    status VARCHAR(50) NOT NULL DEFAULT 'Pending'
        CHECK (status IN ('Pending','Processing','Shipped','Delivered','Cancelled')),
    placed_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now())
);

-- ═══════════════════════════════════════════════════════════════════════════════
-- 6. ORDER LINE ITEMS TABLE
-- ═══════════════════════════════════════════════════════════════════════════════
CREATE TABLE IF NOT EXISTS public.order_line_items (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    order_id UUID NOT NULL REFERENCES public.orders(id) ON DELETE CASCADE,
    product_name VARCHAR(255) NOT NULL,
    quantity INTEGER NOT NULL DEFAULT 1,
    unit_price NUMERIC(12,2) NOT NULL DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now())
);

-- ═══════════════════════════════════════════════════════════════════════════════
-- 7. CONVERSATIONS TABLE
-- ═══════════════════════════════════════════════════════════════════════════════
CREATE TABLE IF NOT EXISTS public.conversations (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    client_id UUID NOT NULL REFERENCES public.clients(id) ON DELETE CASCADE,
    last_message TEXT,
    unread_count INTEGER DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()),
    UNIQUE(user_id, client_id)
);

-- ═══════════════════════════════════════════════════════════════════════════════
-- 8. MESSAGES TABLE
-- ═══════════════════════════════════════════════════════════════════════════════
CREATE TABLE IF NOT EXISTS public.messages (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    conversation_id UUID NOT NULL REFERENCES public.conversations(id) ON DELETE CASCADE,
    sender_type VARCHAR(50) NOT NULL CHECK (sender_type IN ('business', 'client')),
    text TEXT NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now())
);

-- ═══════════════════════════════════════════════════════════════════════════════
-- 9. BUSINESS SETTINGS TABLE
-- ═══════════════════════════════════════════════════════════════════════════════
CREATE TABLE IF NOT EXISTS public.business_settings (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE UNIQUE,
    business_name VARCHAR(255) NOT NULL,
    whatsapp_number VARCHAR(50) NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now())
);

-- ═══════════════════════════════════════════════════════════════════════════════
-- INDEXES
-- ═══════════════════════════════════════════════════════════════════════════════
CREATE INDEX IF NOT EXISTS idx_products_user_id ON public.products(user_id);
CREATE INDEX IF NOT EXISTS idx_clients_user_id ON public.clients(user_id);
CREATE INDEX IF NOT EXISTS idx_orders_user_id ON public.orders(user_id);
CREATE INDEX IF NOT EXISTS idx_categories_user_id ON public.categories(user_id);
CREATE INDEX IF NOT EXISTS idx_conversations_user_id ON public.conversations(user_id);
CREATE INDEX IF NOT EXISTS idx_messages_conversation_id ON public.messages(conversation_id);
CREATE INDEX IF NOT EXISTS idx_business_settings_user_id ON public.business_settings(user_id);
CREATE INDEX IF NOT EXISTS idx_order_line_items_order_id ON public.order_line_items(order_id);

-- ═══════════════════════════════════════════════════════════════════════════════
-- ENABLE ROW LEVEL SECURITY ON ALL TABLES
-- ═══════════════════════════════════════════════════════════════════════════════
ALTER TABLE public.products ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.clients ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.orders ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.order_line_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.categories ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.conversations ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.messages ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.business_settings ENABLE ROW LEVEL SECURITY;

-- ═══════════════════════════════════════════════════════════════════════════════
-- RLS POLICIES  (service_role bypasses all of these, but these allow direct
-- client access if needed in future + protect against anon key leaks)
-- ═══════════════════════════════════════════════════════════════════════════════

-- Products: Users can manage their own products
CREATE POLICY "Users can manage their own products"
    ON public.products FOR ALL USING (auth.uid() = user_id);

-- Clients: Users can manage their own clients
CREATE POLICY "Users can manage their own clients"
    ON public.clients FOR ALL USING (auth.uid() = user_id);

-- Orders: Users can manage their own orders
CREATE POLICY "Users can manage their own orders"
    ON public.orders FOR ALL USING (auth.uid() = user_id);

-- Order line items: Users can manage items of their orders
CREATE POLICY "Users can manage items of their orders"
    ON public.order_line_items FOR ALL USING (
        order_id IN (SELECT id FROM public.orders WHERE user_id = auth.uid())
    );

-- Categories: Users can manage their own categories
CREATE POLICY "Users can manage their own categories"
    ON public.categories FOR ALL USING (auth.uid() = user_id);

-- Conversations: Users can manage their own conversations
CREATE POLICY "Users can manage their own conversations"
    ON public.conversations FOR ALL USING (auth.uid() = user_id);

-- Messages: Users can see and manage messages of their conversations
CREATE POLICY "Users can manage messages of their conversations"
    ON public.messages FOR ALL USING (
        conversation_id IN (
            SELECT id FROM public.conversations WHERE user_id = auth.uid()
        )
    );

-- Business Settings: Users can manage their own settings
CREATE POLICY "Users can manage their own business settings"
    ON public.business_settings FOR ALL USING (auth.uid() = user_id);

-- ═══════════════════════════════════════════════════════════════════════════════
-- FIX: Drop and recreate the orders_status_check constraint to match
-- the valid statuses used by the backend.
-- ═══════════════════════════════════════════════════════════════════════════════
DO $$
BEGIN
    -- Drop old constraint if it exists with possibly wrong values
    IF EXISTS (
        SELECT 1 FROM pg_constraint
        WHERE conname = 'orders_status_check'
          AND conrelid = 'public.orders'::regclass
    ) THEN
        ALTER TABLE public.orders DROP CONSTRAINT orders_status_check;
    END IF;
END $$;

-- Add the correct constraint matching backend VALID_STATUSES
ALTER TABLE public.orders
    ADD CONSTRAINT orders_status_check
    CHECK (status IN ('Pending','Processing','Shipped','Delivered','Cancelled'));

-- ═══════════════════════════════════════════════════════════════════════════════
-- TRIGGERS
-- ═══════════════════════════════════════════════════════════════════════════════
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = timezone('utc'::text, now());
    RETURN NEW;
END;
$$ language 'plpgsql';

CREATE TRIGGER update_conversations_updated_at
    BEFORE UPDATE ON public.conversations
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_business_settings_updated_at
    BEFORE UPDATE ON public.business_settings
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();
