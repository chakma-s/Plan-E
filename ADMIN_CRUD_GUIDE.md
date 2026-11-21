# Plan-E: Admin & Vendor Business Operations Guide
## The Easiest Way to Perform CRUD on Hotels, Resorts, Room Pricing & Inventory

This guide explains how to manage hotels, resorts, room categories, pricing (in **৳ BDT**), and business inventory on **Plan-E** with zero coding required.

---

### Table of Contents
1. [Method 1: The Admin Web Portal (Easiest & Recommended)](#method-1-the-admin-web-portal-easiest--recommended)
2. [Step-by-Step Operations in the Admin Portal](#step-by-step-operations-in-the-admin-portal)
   - [A. Creating a New Hotel or Resort](#a-creating-a-new-hotel-or-resort)
   - [B. Editing an Existing Property](#b-editing-an-existing-property)
   - [C. Managing Room Types & Base Prices (৳)](#c-managing-room-types--base-prices-)
   - [D. Unpublishing or Deleting a Property](#d-unpublishing-or-deleting-a-property)
   - [E. Verifying & Managing Tour Guides](#e-verifying--managing-tour-guides)
3. [Method 2: The Vendor Portal (Host Inventory & Dynamic Multipliers)](#method-2-the-vendor-portal-host-inventory--dynamic-multipliers)
4. [Method 3: Interactive Swagger API Docs (For Developers)](#method-3-interactive-swagger-api-docs-for-developers)
5. [Method 4: Modifying Default Seed Data in Code](#method-4-modifying-default-seed-data-in-code)

---

### Method 1: The Admin Web Portal (Easiest & Recommended)

The **Plan-E Admin Portal** provides a full visual dashboard designed specifically for platform operators to manage all accommodations in real time.

* **URL:** [http://127.0.0.1:8000/admin/](http://127.0.0.1:8000/admin/)
* **Default Admin Credentials:**
  * **Email:** `admin@plane-travel.com`
  * **Password:** `Password123!`
  * *(Tip: A 1-click login button is available in the sign-in modal for instant access)*

---

### Step-by-Step Operations in the Admin Portal

#### A. Creating a New Hotel or Resort
1. Navigate to [http://127.0.0.1:8000/admin/](http://127.0.0.1:8000/admin/).
2. Click the blue **"+ Add New Property"** button at the top right of the inventory table.
3. **Use 1-Click Fast Presets (Optional):**
   * Click **Grand Diplomatic Gulshan**, **Bhawal Eco-Resort Gazipur**, or **Padma Riverfront Retreat** to autofill the form with authentic Dhaka details.
4. **Or fill in custom property details:**
   * **Category:** Choose `HOTEL` (City/Business) or `RESORT` (Sanctuary/Retreat).
   * **Name & Tagline:** e.g., *The Grand Diplomatic Hotel*, *Gulshan-2 Diplomatic Zone*.
   * **Location:** Address, City (`Dhaka`), State (`Dhaka Division`), Country (`Bangladesh`), Postal Code (`1212`).
   * **GPS Coordinates:** Latitude (e.g., `23.7937`) and Longitude (e.g., `90.4066`). This automatically renders the pin on the traveler Leaflet map!
   * **Media:** Cover image URL and gallery image URLs (comma or newline separated).
   * **Initial Room Type & Price:** Set the room name (e.g., *Executive King Suite*) and Nightly Base Price in **৳ BDT** (e.g., `220.00`).
5. Click **"Save Property"**. It will immediately appear on the Consumer portal and map!

#### B. Editing an Existing Property
1. Find the property in the table (use the search bar to search by name or city).
2. Click the **"Edit"** button (pencil icon) on the right side of the row.
3. Update any field (name, tagline, description, address, coordinates, star rating, cover image).
4. Click **"Update Property"**. Changes reflect instantly.

#### C. Managing Room Types & Base Prices (৳)
1. On any property row, click the **"Rooms"** button (bed icon).
2. The Room Management drawer expands:
   * **Edit Existing Room Rate:** Update the **Nightly Base Rate (৳)** input directly and click the checkmark button to save.
   * **Add New Room Category:** Fill in room name (e.g., *Presidential Lake View Suite*), nightly base rate in **৳**, max occupancy, and click **"Add Room"**.
   * **Remove Room Category:** Click the trash icon next to any obsolete room type.

#### D. Unpublishing or Deleting a Property
1. **Soft Delete / Unpublish (Safe):**
   * Click the **"Unpublish"** toggle on the property row.
   * The property is hidden from traveler searches immediately without deleting historical booking records.
   * You can restore it at any time with a single click.
2. **Hard Delete (Permanent):**
   * Click the red trash icon on the far right of the row and confirm the prompt to permanently remove the property from the database.

#### E. Verifying & Managing Tour Guides
1. Scroll down to the **Local Guide Verification & Background Vetting** section.
2. View guide profiles, license numbers, language proficiencies, and daily exclusivity fees in **৳/day**.
3. Toggle the **"Verified"** badge to activate certified guides for resort bundling.

---

### Method 2: The Vendor Portal (Host Inventory & Dynamic Multipliers)

For individual property owners and hosts who only manage their own listings:

* **URL:** [http://127.0.0.1:8000/vendor/](http://127.0.0.1:8000/vendor/)
* **Demo Vendor Accounts:**
  * Dhaka Host: `vendor.dhaka@heritagepalace.com` / `Password123!`
  * Hotel Host: `host@grandmetropolis.com` / `Password123!`
  * Resort Host: `host@azurebayresort.com` / `Password123!`
* **Key Features:**
  * **Dynamic Pricing Multipliers:** Apply surge multipliers (e.g., `1.25x` for weekend getaways or `1.50x` for Eid holidays) to adjust effective pricing automatically.
  * **Allocation Blocks:** Allocate guaranteed blocks of rooms for specific check-in dates to prevent overbooking with database-level concurrency locks.

---

### Method 3: Interactive Swagger API Docs (For Developers)

If you prefer testing or executing CRUD operations via REST API calls:

* **URL:** [http://127.0.0.1:8000/api/v1/docs](http://127.0.0.1:8000/api/v1/docs)
* **How to Authenticate:**
  1. Click the green **"Authorize"** button at the top right.
  2. Sign in via `POST /api/v1/auth/login` with `admin@plane-travel.com` to get your access token.
  3. Enter `Bearer <your_token>` in the authorize dialog.
* **Core Endpoints:**
  * `GET /api/v1/admin/properties`: List all properties with rooms and pricing.
  * `POST /api/v1/admin/properties`: Create a new hotel or resort.
  * `GET /api/v1/admin/properties/{property_id}`: Fetch single property details.
  * `PUT /api/v1/admin/properties/{property_id}`: Update property fields.
  * `DELETE /api/v1/admin/properties/{property_id}`: Soft-delete property.
  * `POST /api/v1/admin/properties/{property_id}/restore`: Restore soft-deleted property.
  * `DELETE /api/v1/admin/properties/{property_id}/hard-delete`: Permanently delete property.
  * `POST /api/v1/admin/properties/{property_id}/rooms`: Add a room category.
  * `PUT /api/v1/admin/rooms/{room_id}`: Update room category details or base price.
  * `DELETE /api/v1/admin/rooms/{room_id}`: Delete a room category.

---

### Method 4: Modifying Default Seed Data in Code

If you ever wish to permanently alter the baseline data that seeds when the database is initialized or reset:

1. Open [backend/app/seed_data.py](file:///c:/Users/cshan/Desktop/PLAN-E/backend/app/seed_data.py):
   * Lines 125–235 define `hotel_prop`, `resort_prop`, `bangalore_hotel_prop` (The Heritage Palace Hotel Dhaka), and `bangalore_resort_prop` (Padma Riverside Sanctuary).
   * Modify names, descriptions, coordinates, or room base rates (`base_price_per_night=Decimal("...")`).
2. Open [backend/app/seed_500_users.py](file:///c:/Users/cshan/Desktop/PLAN-E/backend/app/seed_500_users.py):
   * Lines 85–150 define additional ecosystem properties (Sreepur Green Palms, Bhawal Forest Lodge, Lumina Banani).
3. Reset local database if desired by removing `backend/plane.db` and restarting uvicorn; the startup lifespan will auto-seed with your new parameters.

---

### Quick Reference Summary

| Task | Recommended Place | Time Required |
| :--- | :--- | :--- |
| **Add / Edit Hotel or Resort** | Admin Portal (`/admin/`) -> `+ Add New Property` or `Edit` | 30 Seconds |
| **Change Nightly Room Rate (৳)** | Admin Portal (`/admin/`) -> `Rooms` -> Edit price field | 5 Seconds |
| **Set Holiday Peak Multipliers** | Vendor Portal (`/vendor/`) -> `Allocations` -> `Multiplier` | 10 Seconds |
| **Verify Certified Local Guides** | Admin Portal (`/admin/`) -> `Local Guide Verification` | 5 Seconds |
| **Automated / Scripted CRUD** | Swagger Docs (`/api/v1/docs`) -> Admin endpoints | Instant via API |
