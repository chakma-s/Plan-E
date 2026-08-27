# Plan-E: Entity-Relationship Architecture & Data Dictionary

## 1. Domain ER Diagram (Mermaid)

```mermaid
erDiagram
    USERS ||--o| VENDOR_PROFILES : "owns/operates"
    USERS ||--o| LOCAL_GUIDES : "profile for"
    USERS ||--o{ RESERVATIONS : "places"
    USERS ||--o{ REVIEWS : "writes"

    VENDOR_PROFILES ||--o{ PROPERTIES : "manages"
    VENDOR_PROFILES ||--o{ LOCAL_GUIDES : "employs (optional)"

    PROPERTIES ||--o{ ROOM_TYPES : "contains"
    PROPERTIES ||--o{ RESORT_GUIDE_ASSOCIATIONS : "features (resorts only)"
    PROPERTIES ||--o{ RESERVATIONS : "booked at"
    PROPERTIES ||--o{ REVIEWS : "reviewed in"

    ROOM_TYPES ||--o{ ROOM_ALLOCATIONS : "daily inventory"
    ROOM_TYPES ||--o{ ROOM_BOOKING_ITEMS : "reserved as"

    LOCAL_GUIDES ||--o{ RESORT_GUIDE_ASSOCIATIONS : "associated with"
    LOCAL_GUIDES ||--o{ GUIDE_AVAILABILITIES : "calendar"
    LOCAL_GUIDES ||--o{ GUIDE_BOOKING_ITEMS : "booked in"
    LOCAL_GUIDES ||--o{ REVIEWS : "reviewed in"

    RESERVATIONS ||--o{ ROOM_BOOKING_ITEMS : "includes"
    RESERVATIONS ||--o{ GUIDE_BOOKING_ITEMS : "bundles (optional)"
    RESERVATIONS ||--o{ REVIEWS : "generates"

    USERS {
        uuid id PK
        varchar email UK
        varchar password_hash
        varchar full_name
        varchar phone_number
        user_role role "CUSTOMER | VENDOR | ADMIN | GUIDE"
        boolean is_active
        boolean is_verified
        timestamp created_at
    }

    VENDOR_PROFILES {
        uuid id PK
        uuid user_id FK,UK
        varchar business_name
        varchar tax_id
        varchar contact_email
        varchar contact_phone
        boolean is_verified
        timestamp created_at
    }

    PROPERTIES {
        uuid id PK
        uuid vendor_id FK
        property_type property_type "HOTEL | RESORT"
        varchar name
        varchar slug UK
        text description
        varchar tagline
        varchar address
        varchar city
        varchar state
        varchar country
        varchar postal_code
        decimal latitude
        decimal longitude
        decimal star_rating
        decimal review_score
        int review_count
        varchar cover_image_url
        jsonb gallery_images
        jsonb amenities
        time check_in_time
        time check_out_time
        text cancellation_policy
        boolean is_published
    }

    ROOM_TYPES {
        uuid id PK
        uuid property_id FK
        varchar name
        text description
        int max_occupancy
        varchar bed_configuration
        decimal base_price_per_night
        jsonb amenities
        jsonb images
        boolean is_active
    }

    ROOM_ALLOCATIONS {
        uuid id PK
        uuid room_type_id FK
        date allocation_date
        int total_allocated "CHECK >= 0"
        int booked_count "CHECK >= 0 AND <= total_allocated"
        decimal rate_multiplier
        boolean is_closed
    }

    LOCAL_GUIDES {
        uuid id PK
        uuid user_id FK,UK
        uuid vendor_id FK "nullable"
        varchar full_name
        varchar headline
        text bio
        varchar profile_photo_url
        jsonb languages
        int years_of_experience
        varchar license_number
        decimal hourly_rate
        decimal daily_rate
        jsonb specialties
        decimal rating
        int review_count
        boolean is_verified
        boolean is_active
    }

    RESORT_GUIDE_ASSOCIATIONS {
        uuid id PK
        uuid resort_id FK
        uuid guide_id FK
        boolean is_primary
    }

    GUIDE_AVAILABILITIES {
        uuid id PK
        uuid guide_id FK
        date availability_date
        boolean is_available
        boolean is_booked
    }

    RESERVATIONS {
        uuid id PK
        varchar reservation_code UK
        uuid user_id FK
        uuid property_id FK
        booking_type booking_type "HOTEL_ONLY | RESORT_ONLY | RESORT_WITH_GUIDE"
        booking_status status "PENDING | CONFIRMED | CANCELLED | COMPLETED | REFUNDED"
        payment_status payment_status "UNPAID | PAID | REFUNDED | FAILED"
        varchar idempotency_key UK
        date check_in_date
        date check_out_date
        int total_nights
        int guest_count
        decimal room_subtotal
        decimal guide_subtotal
        decimal platform_fee
        decimal tax_amount
        decimal total_amount
        varchar currency
        text special_requests
    }

    ROOM_BOOKING_ITEMS {
        uuid id PK
        uuid reservation_id FK
        uuid room_type_id FK
        int rooms_count
        decimal price_per_night
        decimal total_price
    }

    GUIDE_BOOKING_ITEMS {
        uuid id PK
        uuid reservation_id FK
        uuid guide_id FK
        date service_date
        int duration_days
        decimal daily_rate
        decimal total_guide_fee
        text special_requirements
    }

    REVIEWS {
        uuid id PK
        uuid reservation_id FK
        uuid user_id FK
        review_target_type target_type "PROPERTY | GUIDE"
        uuid property_id FK "nullable"
        uuid guide_id FK "nullable"
        int rating "CHECK 1..5"
        text comment
    }
```

---

## 2. Core Architectural Guarantees & Transaction Lifecycle

### A. The Allocation Model & Atomic Overbooking Prevention
To guarantee zero overbooking during concurrent booking spikes under the Vendor Allocation model:
1. Every night of a guest's stay maps to a row in `room_allocations`.
2. When creating a reservation, the transaction performs:
   ```sql
   -- Pessimistic Lock & Availability Verification
   SELECT id, total_allocated, booked_count 
   FROM room_allocations
   WHERE room_type_id = :room_type_id 
     AND allocation_date >= :check_in 
     AND allocation_date < :check_out
     AND is_closed = FALSE
   FOR UPDATE;
   ```
3. If `(booked_count + :requested_rooms) <= total_allocated` across all stay dates:
   ```sql
   UPDATE room_allocations
   SET booked_count = booked_count + :requested_rooms
   WHERE room_type_id = :room_type_id
     AND allocation_date >= :check_in
     AND allocation_date < :check_out;
   ```
4. Database-level `CHECK (booked_count <= total_allocated)` provides a secondary hard barrier against race conditions.

### B. Resort & Local Guide Bundling Transaction
When a user books a Resort with a Local Guide:
1. `reservations.booking_type` is tagged as `RESORT_WITH_GUIDE`.
2. The booking engine locks both the `room_allocations` and the `guide_availabilities` for the requested date window within a single atomic database transaction.
3. `guide_availabilities.is_booked` is set to `TRUE`.
4. If either room inventory or guide availability fails, the entire transaction rolls back cleanly.

### C. Spatial Search Performance for Mapbox
- Latitude (`DECIMAL(10, 7)`) and Longitude (`DECIMAL(10, 7)`) are stored on `properties`.
- A composite B-tree index on `(latitude, longitude)` and `(property_type, latitude, longitude)` accelerates viewport bounding box queries (`lat BETWEEN min_lat AND max_lat AND lon BETWEEN min_lon AND max_lon`).
