-- ============================================================================
-- Plan-E: PostgreSQL Relational Database Schema
-- Architecture: High-Performance OTA with Dual-Path Search & Guide Bundling
-- ============================================================================

CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- ----------------------------------------------------------------------------
-- 1. ENUMS
-- ----------------------------------------------------------------------------
DO $$ BEGIN
    CREATE TYPE user_role AS ENUM ('CUSTOMER', 'VENDOR', 'ADMIN', 'GUIDE');
EXCEPTION WHEN duplicate_object THEN null; END $$;

DO $$ BEGIN
    CREATE TYPE property_type AS ENUM ('HOTEL', 'RESORT');
EXCEPTION WHEN duplicate_object THEN null; END $$;

DO $$ BEGIN
    CREATE TYPE booking_type AS ENUM ('HOTEL_ONLY', 'RESORT_ONLY', 'RESORT_WITH_GUIDE');
EXCEPTION WHEN duplicate_object THEN null; END $$;

DO $$ BEGIN
    CREATE TYPE booking_status AS ENUM ('PENDING', 'CONFIRMED', 'CANCELLED', 'COMPLETED', 'REFUNDED');
EXCEPTION WHEN duplicate_object THEN null; END $$;

DO $$ BEGIN
    CREATE TYPE payment_status AS ENUM ('UNPAID', 'PAID', 'REFUNDED', 'FAILED');
EXCEPTION WHEN duplicate_object THEN null; END $$;

DO $$ BEGIN
    CREATE TYPE review_target_type AS ENUM ('PROPERTY', 'GUIDE');
EXCEPTION WHEN duplicate_object THEN null; END $$;

-- ----------------------------------------------------------------------------
-- 2. TRIGGER FUNCTION: AUTO-UPDATE `updated_at`
-- ----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION trigger_set_timestamp()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- ----------------------------------------------------------------------------
-- 3. USERS & PROFILES
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS users (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    email VARCHAR(255) NOT NULL UNIQUE,
    password_hash VARCHAR(255) NOT NULL,
    full_name VARCHAR(255) NOT NULL,
    phone_number VARCHAR(50),
    role user_role NOT NULL DEFAULT 'CUSTOMER',
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    is_verified BOOLEAN NOT NULL DEFAULT FALSE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TRIGGER set_timestamp_users
BEFORE UPDATE ON users
FOR EACH ROW EXECUTE FUNCTION trigger_set_timestamp();

CREATE TABLE IF NOT EXISTS vendor_profiles (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL UNIQUE REFERENCES users(id) ON DELETE CASCADE,
    business_name VARCHAR(255) NOT NULL,
    tax_id VARCHAR(100),
    contact_email VARCHAR(255) NOT NULL,
    contact_phone VARCHAR(50) NOT NULL,
    is_verified BOOLEAN NOT NULL DEFAULT FALSE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TRIGGER set_timestamp_vendor_profiles
BEFORE UPDATE ON vendor_profiles
FOR EACH ROW EXECUTE FUNCTION trigger_set_timestamp();

-- ----------------------------------------------------------------------------
-- 4. PROPERTIES (HOTELS & RESORTS)
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS properties (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    vendor_id UUID NOT NULL REFERENCES vendor_profiles(id) ON DELETE RESTRICT,
    property_type property_type NOT NULL,
    name VARCHAR(255) NOT NULL,
    slug VARCHAR(255) NOT NULL UNIQUE,
    description TEXT NOT NULL,
    tagline VARCHAR(255),
    address VARCHAR(255) NOT NULL,
    city VARCHAR(100) NOT NULL,
    state VARCHAR(100),
    country VARCHAR(100) NOT NULL,
    postal_code VARCHAR(50),
    latitude NUMERIC(10, 7) NOT NULL,
    longitude NUMERIC(10, 7) NOT NULL,
    star_rating NUMERIC(2, 1) DEFAULT 4.0 CHECK (star_rating >= 1.0 AND star_rating <= 5.0),
    review_score NUMERIC(3, 2) DEFAULT 0.00 CHECK (review_score >= 0.00 AND review_score <= 5.00),
    review_count INT NOT NULL DEFAULT 0 CHECK (review_count >= 0),
    cover_image_url VARCHAR(500) NOT NULL,
    gallery_images JSONB NOT NULL DEFAULT '[]'::jsonb,
    amenities JSONB NOT NULL DEFAULT '[]'::jsonb,
    check_in_time TIME NOT NULL DEFAULT '15:00:00',
    check_out_time TIME NOT NULL DEFAULT '11:00:00',
    cancellation_policy TEXT NOT NULL DEFAULT 'Free cancellation up to 48 hours before check-in.',
    is_published BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TRIGGER set_timestamp_properties
BEFORE UPDATE ON properties
FOR EACH ROW EXECUTE FUNCTION trigger_set_timestamp();

CREATE INDEX IF NOT EXISTS idx_properties_type ON properties(property_type);
CREATE INDEX IF NOT EXISTS idx_properties_city ON properties(city);
CREATE INDEX IF NOT EXISTS idx_properties_geo ON properties(latitude, longitude);
CREATE INDEX IF NOT EXISTS idx_properties_type_geo ON properties(property_type, latitude, longitude);
CREATE INDEX IF NOT EXISTS idx_properties_vendor ON properties(vendor_id);

-- ----------------------------------------------------------------------------
-- 5. ROOM TYPES & ALLOCATION INVENTORY
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS room_types (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    property_id UUID NOT NULL REFERENCES properties(id) ON DELETE CASCADE,
    name VARCHAR(255) NOT NULL,
    description TEXT,
    max_occupancy INT NOT NULL DEFAULT 2 CHECK (max_occupancy > 0),
    bed_configuration VARCHAR(100) NOT NULL DEFAULT '1 King Bed',
    base_price_per_night NUMERIC(10, 2) NOT NULL CHECK (base_price_per_night >= 0),
    amenities JSONB NOT NULL DEFAULT '[]'::jsonb,
    images JSONB NOT NULL DEFAULT '[]'::jsonb,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TRIGGER set_timestamp_room_types
BEFORE UPDATE ON room_types
FOR EACH ROW EXECUTE FUNCTION trigger_set_timestamp();

CREATE INDEX IF NOT EXISTS idx_room_types_property ON room_types(property_id);

-- The Core Vendor Allocation Model Table
CREATE TABLE IF NOT EXISTS room_allocations (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    room_type_id UUID NOT NULL REFERENCES room_types(id) ON DELETE CASCADE,
    allocation_date DATE NOT NULL,
    total_allocated INT NOT NULL CHECK (total_allocated >= 0),
    booked_count INT NOT NULL DEFAULT 0 CHECK (booked_count >= 0),
    rate_multiplier NUMERIC(4, 2) NOT NULL DEFAULT 1.00 CHECK (rate_multiplier > 0),
    is_closed BOOLEAN NOT NULL DEFAULT FALSE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT uq_room_type_date UNIQUE (room_type_id, allocation_date),
    CONSTRAINT chk_booked_le_allocated CHECK (booked_count <= total_allocated)
);

CREATE TRIGGER set_timestamp_room_allocations
BEFORE UPDATE ON room_allocations
FOR EACH ROW EXECUTE FUNCTION trigger_set_timestamp();

CREATE INDEX IF NOT EXISTS idx_allocations_lookup ON room_allocations(room_type_id, allocation_date, is_closed);

-- ----------------------------------------------------------------------------
-- 6. LOCAL GUIDES & RESORT BUNDLING
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS local_guides (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID UNIQUE REFERENCES users(id) ON DELETE SET NULL,
    vendor_id UUID REFERENCES vendor_profiles(id) ON DELETE SET NULL,
    full_name VARCHAR(255) NOT NULL,
    headline VARCHAR(255) NOT NULL,
    bio TEXT NOT NULL,
    profile_photo_url VARCHAR(500) NOT NULL,
    languages JSONB NOT NULL DEFAULT '["English"]'::jsonb,
    years_of_experience INT NOT NULL DEFAULT 1 CHECK (years_of_experience >= 0),
    license_number VARCHAR(100),
    hourly_rate NUMERIC(10, 2) NOT NULL DEFAULT 35.00 CHECK (hourly_rate >= 0),
    daily_rate NUMERIC(10, 2) NOT NULL DEFAULT 200.00 CHECK (daily_rate >= 0),
    specialties JSONB NOT NULL DEFAULT '[]'::jsonb,
    rating NUMERIC(3, 2) NOT NULL DEFAULT 5.00 CHECK (rating >= 1.00 AND rating <= 5.00),
    review_count INT NOT NULL DEFAULT 0 CHECK (review_count >= 0),
    is_verified BOOLEAN NOT NULL DEFAULT FALSE,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TRIGGER set_timestamp_local_guides
BEFORE UPDATE ON local_guides
FOR EACH ROW EXECUTE FUNCTION trigger_set_timestamp();

CREATE INDEX IF NOT EXISTS idx_local_guides_rating ON local_guides(rating DESC);

-- Resort to Guide Association (Many-to-Many)
CREATE TABLE IF NOT EXISTS resort_guide_associations (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    resort_id UUID NOT NULL REFERENCES properties(id) ON DELETE CASCADE,
    guide_id UUID NOT NULL REFERENCES local_guides(id) ON DELETE CASCADE,
    is_primary BOOLEAN NOT NULL DEFAULT FALSE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT uq_resort_guide UNIQUE (resort_id, guide_id)
);

CREATE INDEX IF NOT EXISTS idx_resort_guide_lookup ON resort_guide_associations(resort_id, guide_id);

-- Guide Calendar Availability
CREATE TABLE IF NOT EXISTS guide_availabilities (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    guide_id UUID NOT NULL REFERENCES local_guides(id) ON DELETE CASCADE,
    availability_date DATE NOT NULL,
    is_available BOOLEAN NOT NULL DEFAULT TRUE,
    is_booked BOOLEAN NOT NULL DEFAULT FALSE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT uq_guide_date UNIQUE (guide_id, availability_date)
);

CREATE TRIGGER set_timestamp_guide_availabilities
BEFORE UPDATE ON guide_availabilities
FOR EACH ROW EXECUTE FUNCTION trigger_set_timestamp();

CREATE INDEX IF NOT EXISTS idx_guide_avail_lookup ON guide_availabilities(guide_id, availability_date, is_available, is_booked);

-- ----------------------------------------------------------------------------
-- 7. RESERVATIONS & BOOKING ITEMS (BUNDLED & UNIFIED)
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS reservations (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    reservation_code VARCHAR(20) NOT NULL UNIQUE,
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE RESTRICT,
    property_id UUID NOT NULL REFERENCES properties(id) ON DELETE RESTRICT,
    booking_type booking_type NOT NULL,
    status booking_status NOT NULL DEFAULT 'PENDING',
    payment_status payment_status NOT NULL DEFAULT 'UNPAID',
    idempotency_key VARCHAR(100) UNIQUE,
    check_in_date DATE NOT NULL,
    check_out_date DATE NOT NULL,
    total_nights INT NOT NULL CHECK (total_nights > 0),
    guest_count INT NOT NULL DEFAULT 1 CHECK (guest_count > 0),
    room_subtotal NUMERIC(10, 2) NOT NULL DEFAULT 0.00 CHECK (room_subtotal >= 0),
    guide_subtotal NUMERIC(10, 2) NOT NULL DEFAULT 0.00 CHECK (guide_subtotal >= 0),
    platform_fee NUMERIC(10, 2) NOT NULL DEFAULT 0.00 CHECK (platform_fee >= 0),
    tax_amount NUMERIC(10, 2) NOT NULL DEFAULT 0.00 CHECK (tax_amount >= 0),
    total_amount NUMERIC(10, 2) NOT NULL CHECK (total_amount >= 0),
    currency VARCHAR(3) NOT NULL DEFAULT 'USD',
    special_requests TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT chk_checkin_checkout CHECK (check_out_date > check_in_date)
);

CREATE TRIGGER set_timestamp_reservations
BEFORE UPDATE ON reservations
FOR EACH ROW EXECUTE FUNCTION trigger_set_timestamp();

CREATE INDEX IF NOT EXISTS idx_reservations_user ON reservations(user_id);
CREATE INDEX IF NOT EXISTS idx_reservations_property ON reservations(property_id);
CREATE INDEX IF NOT EXISTS idx_reservations_status ON reservations(status);
CREATE INDEX IF NOT EXISTS idx_reservations_code ON reservations(reservation_code);

CREATE TABLE IF NOT EXISTS room_booking_items (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    reservation_id UUID NOT NULL REFERENCES reservations(id) ON DELETE CASCADE,
    room_type_id UUID NOT NULL REFERENCES room_types(id) ON DELETE RESTRICT,
    rooms_count INT NOT NULL DEFAULT 1 CHECK (rooms_count > 0),
    price_per_night NUMERIC(10, 2) NOT NULL CHECK (price_per_night >= 0),
    total_price NUMERIC(10, 2) NOT NULL CHECK (total_price >= 0),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_room_booking_items_res ON room_booking_items(reservation_id);

CREATE TABLE IF NOT EXISTS guide_booking_items (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    reservation_id UUID NOT NULL REFERENCES reservations(id) ON DELETE CASCADE,
    guide_id UUID NOT NULL REFERENCES local_guides(id) ON DELETE RESTRICT,
    service_date DATE NOT NULL,
    duration_days INT NOT NULL DEFAULT 1 CHECK (duration_days > 0),
    daily_rate NUMERIC(10, 2) NOT NULL CHECK (daily_rate >= 0),
    total_guide_fee NUMERIC(10, 2) NOT NULL CHECK (total_guide_fee >= 0),
    special_requirements TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_guide_booking_items_res ON guide_booking_items(reservation_id);

-- ----------------------------------------------------------------------------
-- 8. REVIEWS & RATINGS
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS reviews (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    reservation_id UUID NOT NULL REFERENCES reservations(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    target_type review_target_type NOT NULL,
    property_id UUID REFERENCES properties(id) ON DELETE CASCADE,
    guide_id UUID REFERENCES local_guides(id) ON DELETE CASCADE,
    rating INT NOT NULL CHECK (rating >= 1 AND rating <= 5),
    comment TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT chk_review_target CHECK (
        (target_type = 'PROPERTY' AND property_id IS NOT NULL AND guide_id IS NULL) OR
        (target_type = 'GUIDE' AND guide_id IS NOT NULL AND property_id IS NULL)
    )
);

CREATE INDEX IF NOT EXISTS idx_reviews_property ON reviews(property_id) WHERE property_id IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_reviews_guide ON reviews(guide_id) WHERE guide_id IS NOT NULL;
