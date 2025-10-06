-- ============================================================
-- CRITICAL: Run this SQL in your Supabase SQL Editor
-- This fixes schema mismatches causing infinite loops
-- ============================================================

/*
  PROBLEM: Your database schema is missing critical columns
  that the application code expects, causing queries to fail
  and triggering infinite retry loops.

  SOLUTION: Add all missing columns with proper defaults
  to match the application's expectations.
*/

-- ============================================================
-- STEP 1: Fix menu_items table
-- ============================================================

-- Add category column (morning/afternoon/dinner)
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema = 'public'
    AND table_name = 'menu_items'
    AND column_name = 'category'
  ) THEN
    ALTER TABLE public.menu_items
    ADD COLUMN category text NOT NULL DEFAULT 'morning';

    -- Add check constraint
    ALTER TABLE public.menu_items
    ADD CONSTRAINT menu_items_category_check
    CHECK (category IN ('morning', 'afternoon', 'dinner'));

    RAISE NOTICE 'Added category column to menu_items';
  ELSE
    RAISE NOTICE 'Category column already exists in menu_items';
  END IF;
END $$;

-- Add is_vegetarian column
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema = 'public'
    AND table_name = 'menu_items'
    AND column_name = 'is_vegetarian'
  ) THEN
    ALTER TABLE public.menu_items
    ADD COLUMN is_vegetarian boolean DEFAULT false;

    RAISE NOTICE 'Added is_vegetarian column to menu_items';
  ELSE
    RAISE NOTICE 'is_vegetarian column already exists in menu_items';
  END IF;
END $$;

-- Add updated_at column
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema = 'public'
    AND table_name = 'menu_items'
    AND column_name = 'updated_at'
  ) THEN
    ALTER TABLE public.menu_items
    ADD COLUMN updated_at timestamptz DEFAULT now();

    RAISE NOTICE 'Added updated_at column to menu_items';
  ELSE
    RAISE NOTICE 'updated_at column already exists in menu_items';
  END IF;
END $$;

-- ============================================================
-- STEP 2: Fix orders table
-- ============================================================

-- Rename user_id to customer_id if needed
DO $$
BEGIN
  IF EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema = 'public'
    AND table_name = 'orders'
    AND column_name = 'user_id'
  ) AND NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema = 'public'
    AND table_name = 'orders'
    AND column_name = 'customer_id'
  ) THEN
    ALTER TABLE public.orders RENAME COLUMN user_id TO customer_id;
    RAISE NOTICE 'Renamed user_id to customer_id in orders';
  ELSE
    RAISE NOTICE 'customer_id column already exists or user_id does not exist';
  END IF;
END $$;

-- Make customer_id nullable (for guest orders)
DO $$
BEGIN
  ALTER TABLE public.orders ALTER COLUMN customer_id DROP NOT NULL;
  RAISE NOTICE 'Made customer_id nullable in orders';
EXCEPTION
  WHEN OTHERS THEN
    RAISE NOTICE 'customer_id already nullable or does not exist';
END $$;

-- Add customer_name column
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema = 'public'
    AND table_name = 'orders'
    AND column_name = 'customer_name'
  ) THEN
    ALTER TABLE public.orders
    ADD COLUMN customer_name text NOT NULL DEFAULT 'Guest Customer';

    RAISE NOTICE 'Added customer_name column to orders';
  ELSE
    RAISE NOTICE 'customer_name column already exists in orders';
  END IF;
END $$;

-- Add customer_email column
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema = 'public'
    AND table_name = 'orders'
    AND column_name = 'customer_email'
  ) THEN
    ALTER TABLE public.orders
    ADD COLUMN customer_email text NOT NULL DEFAULT 'guest@example.com';

    RAISE NOTICE 'Added customer_email column to orders';
  ELSE
    RAISE NOTICE 'customer_email column already exists in orders';
  END IF;
END $$;

-- Add customer_phone column
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema = 'public'
    AND table_name = 'orders'
    AND column_name = 'customer_phone'
  ) THEN
    ALTER TABLE public.orders
    ADD COLUMN customer_phone text NOT NULL DEFAULT '';

    RAISE NOTICE 'Added customer_phone column to orders';
  ELSE
    RAISE NOTICE 'customer_phone column already exists in orders';
  END IF;
END $$;

-- Add delivery_address column
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema = 'public'
    AND table_name = 'orders'
    AND column_name = 'delivery_address'
  ) THEN
    ALTER TABLE public.orders
    ADD COLUMN delivery_address text NOT NULL DEFAULT '';

    RAISE NOTICE 'Added delivery_address column to orders';
  ELSE
    RAISE NOTICE 'delivery_address column already exists in orders';
  END IF;
END $$;

-- Add special_instructions column
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema = 'public'
    AND table_name = 'orders'
    AND column_name = 'special_instructions'
  ) THEN
    ALTER TABLE public.orders
    ADD COLUMN special_instructions text DEFAULT '';

    RAISE NOTICE 'Added special_instructions column to orders';
  ELSE
    RAISE NOTICE 'special_instructions column already exists in orders';
  END IF;
END $$;

-- Add is_read column (for admin notifications)
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema = 'public'
    AND table_name = 'orders'
    AND column_name = 'is_read'
  ) THEN
    ALTER TABLE public.orders
    ADD COLUMN is_read boolean DEFAULT false;

    RAISE NOTICE 'Added is_read column to orders';
  ELSE
    RAISE NOTICE 'is_read column already exists in orders';
  END IF;
END $$;

-- Add updated_at column
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema = 'public'
    AND table_name = 'orders'
    AND column_name = 'updated_at'
  ) THEN
    ALTER TABLE public.orders
    ADD COLUMN updated_at timestamptz DEFAULT now();

    RAISE NOTICE 'Added updated_at column to orders';
  ELSE
    RAISE NOTICE 'updated_at column already exists in orders';
  END IF;
END $$;

-- Update status constraint to include all statuses
DO $$
BEGIN
  -- Drop old constraint if exists
  ALTER TABLE public.orders DROP CONSTRAINT IF EXISTS orders_status_check;

  -- Add new constraint with all statuses
  ALTER TABLE public.orders
  ADD CONSTRAINT orders_status_check
  CHECK (status IN ('pending', 'confirmed', 'preparing', 'ready', 'delivered', 'cancelled'));

  RAISE NOTICE 'Updated status constraint for orders';
EXCEPTION
  WHEN duplicate_object THEN
    RAISE NOTICE 'Status constraint already exists correctly';
END $$;

-- ============================================================
-- STEP 3: Fix order_items table
-- ============================================================

-- Add item_name column (denormalized for order history)
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema = 'public'
    AND table_name = 'order_items'
    AND column_name = 'item_name'
  ) THEN
    ALTER TABLE public.order_items
    ADD COLUMN item_name text NOT NULL DEFAULT '';

    RAISE NOTICE 'Added item_name column to order_items';
  ELSE
    RAISE NOTICE 'item_name column already exists in order_items';
  END IF;
END $$;

-- Handle subtotal/price column
DO $$
BEGIN
  -- If subtotal exists and price doesn't, rename it
  IF EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema = 'public'
    AND table_name = 'order_items'
    AND column_name = 'subtotal'
  ) AND NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema = 'public'
    AND table_name = 'order_items'
    AND column_name = 'price'
  ) THEN
    ALTER TABLE public.order_items RENAME COLUMN subtotal TO price;
    RAISE NOTICE 'Renamed subtotal to price in order_items';
  -- If neither exists, add price
  ELSIF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema = 'public'
    AND table_name = 'order_items'
    AND column_name = 'price'
  ) THEN
    ALTER TABLE public.order_items
    ADD COLUMN price numeric(10,2) NOT NULL DEFAULT 0
    CHECK (price >= 0);
    RAISE NOTICE 'Added price column to order_items';
  ELSE
    RAISE NOTICE 'price column already exists in order_items';
  END IF;
END $$;

-- ============================================================
-- STEP 4: Create update triggers
-- ============================================================

-- Create or replace trigger function
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Add trigger for menu_items
DROP TRIGGER IF EXISTS update_menu_items_updated_at ON public.menu_items;
CREATE TRIGGER update_menu_items_updated_at
  BEFORE UPDATE ON public.menu_items
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

-- Add trigger for orders
DROP TRIGGER IF EXISTS update_orders_updated_at ON public.orders;
CREATE TRIGGER update_orders_updated_at
  BEFORE UPDATE ON public.orders
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

-- ============================================================
-- STEP 5: Create performance indexes
-- ============================================================

CREATE INDEX IF NOT EXISTS idx_menu_items_category
  ON public.menu_items(category);

CREATE INDEX IF NOT EXISTS idx_menu_items_available
  ON public.menu_items(is_available)
  WHERE is_available = true;

CREATE INDEX IF NOT EXISTS idx_orders_customer
  ON public.orders(customer_id)
  WHERE customer_id IS NOT NULL;

CREATE INDEX IF NOT EXISTS idx_orders_status
  ON public.orders(status);

CREATE INDEX IF NOT EXISTS idx_orders_is_read
  ON public.orders(is_read)
  WHERE is_read = false;

CREATE INDEX IF NOT EXISTS idx_orders_created
  ON public.orders(created_at DESC);

CREATE INDEX IF NOT EXISTS idx_order_items_order
  ON public.order_items(order_id);

CREATE INDEX IF NOT EXISTS idx_order_items_menu_item
  ON public.order_items(menu_item_id);

-- ============================================================
-- STEP 6: Update existing data with proper defaults
-- ============================================================

-- Update menu items without category
UPDATE public.menu_items
SET category = 'morning'
WHERE category IS NULL OR category = '';

-- Update orders without customer info
UPDATE public.orders
SET customer_name = COALESCE(customer_name, 'Guest Customer'),
    customer_email = COALESCE(customer_email, 'guest@example.com'),
    customer_phone = COALESCE(customer_phone, ''),
    delivery_address = COALESCE(delivery_address, ''),
    is_read = COALESCE(is_read, false)
WHERE customer_name IS NULL
   OR customer_email IS NULL
   OR delivery_address IS NULL;

-- Update order items without item_name
UPDATE public.order_items oi
SET item_name = COALESCE(oi.item_name, mi.name)
FROM public.menu_items mi
WHERE oi.menu_item_id = mi.id
  AND (oi.item_name IS NULL OR oi.item_name = '');

-- ============================================================
-- SUCCESS MESSAGE
-- ============================================================

DO $$
BEGIN
  RAISE NOTICE '
  ============================================================
  DATABASE SCHEMA FIX COMPLETED SUCCESSFULLY!
  ============================================================

  All missing columns have been added:
  ✓ menu_items: category, is_vegetarian, updated_at
  ✓ orders: customer_name, customer_email, customer_phone,
           delivery_address, special_instructions, is_read, updated_at
  ✓ order_items: item_name, price

  Performance indexes created
  Update triggers activated
  Existing data updated with defaults

  Your application should now work without infinite loops!
  ============================================================
  ';
END $$;
