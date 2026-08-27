-- ============================================================================
-- Plan-E: Initial Seed Data for Beta Testing & Development
-- ============================================================================

-- 1. USERS
-- Password hash corresponds to: "Password123!" using bcrypt
INSERT INTO users (id, email, password_hash, full_name, phone_number, role, is_active, is_verified) VALUES
('a0000000-0000-0000-0000-000000000001', 'admin@plane-travel.com', '$2b$12$K1rY7VdG0JgIuMhBqVpA.uVpA1B2C3D4E5F6G7H8I9J0K1L2M3N4O', 'System Administrator', '+1-555-0100', 'ADMIN', TRUE, TRUE),
('a0000000-0000-0000-0000-000000000002', 'host@grandmetropolis.com', '$2b$12$K1rY7VdG0JgIuMhBqVpA.uVpA1B2C3D4E5F6G7H8I9J0K1L2M3N4O', 'Marcus Vance (Metropolis Hospitality)', '+1-555-0101', 'VENDOR', TRUE, TRUE),
('a0000000-0000-0000-0000-000000000003', 'host@azurebayresort.com', '$2b$12$K1rY7VdG0JgIuMhBqVpA.uVpA1B2C3D4E5F6G7H8I9J0K1L2M3N4O', 'Elena Rostova (Azure Coast Resorts)', '+1-555-0102', 'VENDOR', TRUE, TRUE),
('a0000000-0000-0000-0000-000000000004', 'guide.kai@travelguides.com', '$2b$12$K1rY7VdG0JgIuMhBqVpA.uVpA1B2C3D4E5F6G7H8I9J0K1L2M3N4O', 'Captain Kai Tanaka', '+1-555-0103', 'GUIDE', TRUE, TRUE),
('a0000000-0000-0000-0000-000000000005', 'guide.maya@travelguides.com', '$2b$12$K1rY7VdG0JgIuMhBqVpA.uVpA1B2C3D4E5F6G7H8I9J0K1L2M3N4O', 'Dr. Maya Lin', '+1-555-0104', 'GUIDE', TRUE, TRUE),
('a0000000-0000-0000-0000-000000000006', 'traveler.alex@example.com', '$2b$12$K1rY7VdG0JgIuMhBqVpA.uVpA1B2C3D4E5F6G7H8I9J0K1L2M3N4O', 'Alex Rivera', '+1-555-0105', 'CUSTOMER', TRUE, TRUE)
ON CONFLICT (id) DO NOTHING;

-- 2. VENDOR PROFILES
INSERT INTO vendor_profiles (id, user_id, business_name, tax_id, contact_email, contact_phone, is_verified) VALUES
('b0000000-0000-0000-0000-000000000001', 'a0000000-0000-0000-0000-000000000002', 'Metropolis Hotel Group LLC', 'US-TAX-9823411', 'operations@grandmetropolis.com', '+1-555-0101', TRUE),
('b0000000-0000-0000-0000-000000000002', 'a0000000-0000-0000-0000-000000000003', 'Azure Luxury Hospitality Group', 'US-TAX-4523190', 'concierge@azurebayresort.com', '+1-555-0102', TRUE)
ON CONFLICT (id) DO NOTHING;

-- 3. PROPERTIES (Hotels vs Resorts)
INSERT INTO properties (
    id, vendor_id, property_type, name, slug, description, tagline, 
    address, city, state, country, postal_code, latitude, longitude, 
    star_rating, review_score, review_count, cover_image_url, gallery_images, amenities
) VALUES
-- Transactional City Hotel
(
    'c0000000-0000-0000-0000-000000000001',
    'b0000000-0000-0000-0000-000000000001',
    'HOTEL',
    'The Grand Metropolis Hotel',
    'the-grand-metropolis-hotel',
    'Prime business & transit hotel situated in the heart of downtown. Features ultra-fast fiber WiFi, express 24/7 check-in, soundproof executive suites, and direct subway connectivity.',
    'Speed, Luxury & Seamless Connectivity for the Modern Traveler',
    '742 Financial Boulevard',
    'San Francisco',
    'California',
    'United States',
    '94104',
    37.7915000,
    -122.4010000,
    4.5,
    4.72,
    148,
    'https://images.unsplash.com/photo-1566073771259-6a8506099945?auto=format&fit=crop&w=1200&q=80',
    '["https://images.unsplash.com/photo-1582719478250-c89cae4dc85b", "https://images.unsplash.com/photo-1590490360182-c33d57733427"]'::jsonb,
    '["Fast Fiber WiFi", "24/7 Check-in", "Executive Lounge", "Fitness Center", "Meeting Rooms", "Airport Shuttle"]'::jsonb
),
-- Immersive Vacation Resort
(
    'c0000000-0000-0000-0000-000000000002',
    'b0000000-0000-0000-0000-000000000002',
    'RESORT',
    'Azure Bay Oceanfront Resort & Sanctuary',
    'azure-bay-oceanfront-resort',
    'An exclusive coastal haven featuring private overwater villas, infinity pools facing panoramic sunsets, world-class Thalasso spa therapies, and curated marine excursions led by certified resident guides.',
    'Immerse in Untamed Coastal Wonder & Unrivaled Luxury',
    '101 Coral Reef Way',
    'Carmel-by-the-Sea',
    'California',
    'United States',
    '93923',
    36.5552000,
    -121.9233000,
    5.0,
    4.94,
    312,
    'https://images.unsplash.com/photo-1540555700478-4be289fbecef?auto=format&fit=crop&w=1200&q=80',
    '["https://images.unsplash.com/photo-1571896349842-33c89424de2d", "https://images.unsplash.com/photo-1520250497591-112f2f40a3f4"]'::jsonb,
    '["Private Beach Access", "Infinity Pool", "Full-Service Spa", "Local Guide Concierge", "Michelin Dining", "Water Sports", "Yoga Pavilion"]'::jsonb
)
ON CONFLICT (id) DO NOTHING;

-- 4. ROOM TYPES
INSERT INTO room_types (
    id, property_id, name, description, max_occupancy, bed_configuration, base_price_per_night, amenities, images
) VALUES
-- Hotel Room Types
(
    'd0000000-0000-0000-0000-000000000001',
    'c0000000-0000-0000-0000-000000000001',
    'Urban Executive King',
    'Ergonomic workstation, soundproof double-glazed glass, Nespresso bar, and rain shower.',
    2,
    '1 King Bed',
    220.00,
    '["Smart TV", "Ergonomic Desk", "Rain Shower", "High-speed WiFi", "Minibar"]'::jsonb,
    '["https://images.unsplash.com/photo-1618773928121-c32242e63f39"]'::jsonb
),
(
    'd0000000-0000-0000-0000-000000000002',
    'c0000000-0000-0000-0000-000000000001',
    'Metropolis Skyline Suite',
    'Panoramic corner views of the downtown skyline with separate living lounge.',
    3,
    '1 King Bed + 1 Sofa Bed',
    380.00,
    '["Skyline View", "Bathtub", "Living Lounge", "Complimentary Breakfast", "Soundproof"]'::jsonb,
    '["https://images.unsplash.com/photo-1591088398332-8a7791972843"]'::jsonb
),
-- Resort Room Types
(
    'd0000000-0000-0000-0000-000000000003',
    'c0000000-0000-0000-0000-000000000002',
    'Overwater Sunset Pavilion',
    'Direct glass bottom reef view, outdoor plunge pool, and private sun deck over the bay.',
    2,
    '1 California King Bed',
    750.00,
    '["Private Plunge Pool", "Glass Floor", "Butler Service", "Direct Ocean Access", "Wine Cellar"]'::jsonb,
    '["https://images.unsplash.com/photo-1582719478250-c89cae4dc85b"]'::jsonb
),
(
    'd0000000-0000-0000-0000-000000000004',
    'c0000000-0000-0000-0000-000000000002',
    'Beachfront Garden Villa',
    'Surrounded by lush tropical flora steps away from the golden sands.',
    4,
    '2 Queen Beds',
    520.00,
    '["Private Garden", "Outdoor Stone Shower", "Direct Beach Walkway", "Espresso Bar"]'::jsonb,
    '["https://images.unsplash.com/photo-1590490360182-c33d57733427"]'::jsonb
)
ON CONFLICT (id) DO NOTHING;

-- 5. LOCAL GUIDES
INSERT INTO local_guides (
    id, user_id, vendor_id, full_name, headline, bio, profile_photo_url, 
    languages, years_of_experience, license_number, hourly_rate, daily_rate, specialties, rating, review_count, is_verified
) VALUES
(
    'e0000000-0000-0000-0000-000000000001',
    'a0000000-0000-0000-0000-000000000004',
    'b0000000-0000-0000-0000-000000000002',
    'Captain Kai Tanaka',
    'Certified Marine Biologist & Coastal Sailing Master',
    'With over 12 years navigating the Monterey Bay marine sanctuary, Kai leads intimate snorkeling, whale watching, and underwater ecology expeditions for all skill levels.',
    'https://images.unsplash.com/photo-1534528741775-53994a69daeb?auto=format&fit=crop&w=400&q=80',
    '["English", "Japanese"]'::jsonb,
    12,
    'USCG-MAR-77341',
    50.00,
    300.00,
    '["Kelp Forest Snorkeling", "Whale Watching", "Sunset Sailing", "Marine Ecology"]'::jsonb,
    4.98,
    86,
    TRUE
),
(
    'e0000000-0000-0000-0000-000000000002',
    'a0000000-0000-0000-0000-000000000005',
    'b0000000-0000-0000-0000-000000000002',
    'Dr. Maya Lin',
    'Cultural Anthropologist & Wilderness Trek Leader',
    'Dr. Lin specializes in native flora foraging, indigenous history hikes along the rugged Big Sur cliffs, and immersive stargazing tours.',
    'https://images.unsplash.com/photo-1573496359142-b8d87734a5a2?auto=format&fit=crop&w=400&q=80',
    '["English", "Mandarin", "Spanish"]'::jsonb,
    8,
    'CA-NAT-29188',
    45.00,
    260.00,
    '["Cliffside Hiking", "Foraging & Botanical Tours", "Night Sky Astronomy", "Coastal Photography"]'::jsonb,
    4.95,
    64,
    TRUE
)
ON CONFLICT (id) DO NOTHING;

-- 6. RESORT-GUIDE ASSOCIATIONS
INSERT INTO resort_guide_associations (id, resort_id, guide_id, is_primary) VALUES
('f0000000-0000-0000-0000-000000000001', 'c0000000-0000-0000-0000-000000000002', 'e0000000-0000-0000-0000-000000000001', TRUE),
('f0000000-0000-0000-0000-000000000002', 'c0000000-0000-0000-0000-000000000002', 'e0000000-0000-0000-0000-000000000002', FALSE)
ON CONFLICT (resort_id, guide_id) DO NOTHING;

-- 7. GENERATE 30-DAY INVENTORY ALLOCATIONS & GUIDE AVAILABILITIES
DO $$
DECLARE
    curr_date DATE := CURRENT_DATE;
    d INT;
    target_d DATE;
BEGIN
    FOR d IN 0..30 LOOP
        target_d := curr_date + d;

        -- Room Allocations for Hotel Room 1 (Urban Executive King: 10 rooms allocated)
        INSERT INTO room_allocations (room_type_id, allocation_date, total_allocated, booked_count, rate_multiplier)
        VALUES ('d0000000-0000-0000-0000-000000000001', target_d, 10, 0, 1.00)
        ON CONFLICT (room_type_id, allocation_date) DO NOTHING;

        -- Room Allocations for Hotel Room 2 (Skyline Suite: 5 rooms allocated)
        INSERT INTO room_allocations (room_type_id, allocation_date, total_allocated, booked_count, rate_multiplier)
        VALUES ('d0000000-0000-0000-0000-000000000002', target_d, 5, 0, 1.00)
        ON CONFLICT (room_type_id, allocation_date) DO NOTHING;

        -- Room Allocations for Resort Room 1 (Overwater Sunset Pavilion: 4 rooms allocated)
        INSERT INTO room_allocations (room_type_id, allocation_date, total_allocated, booked_count, rate_multiplier)
        VALUES ('d0000000-0000-0000-0000-000000000003', target_d, 4, 0, 1.00)
        ON CONFLICT (room_type_id, allocation_date) DO NOTHING;

        -- Room Allocations for Resort Room 2 (Beachfront Garden Villa: 6 rooms allocated)
        INSERT INTO room_allocations (room_type_id, allocation_date, total_allocated, booked_count, rate_multiplier)
        VALUES ('d0000000-0000-0000-0000-000000000004', target_d, 6, 0, 1.00)
        ON CONFLICT (room_type_id, allocation_date) DO NOTHING;

        -- Guide Availability: Captain Kai
        INSERT INTO guide_availabilities (guide_id, availability_date, is_available, is_booked)
        VALUES ('e0000000-0000-0000-0000-000000000001', target_d, TRUE, FALSE)
        ON CONFLICT (guide_id, availability_date) DO NOTHING;

        -- Guide Availability: Dr. Maya Lin
        INSERT INTO guide_availabilities (guide_id, availability_date, is_available, is_booked)
        VALUES ('e0000000-0000-0000-0000-000000000002', target_d, TRUE, FALSE)
        ON CONFLICT (guide_id, availability_date) DO NOTHING;

    END LOOP;
END $$;
