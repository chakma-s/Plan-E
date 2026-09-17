import asyncio
import uuid
from datetime import date, timedelta
from decimal import Decimal
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.database import AsyncSessionLocal, engine
from app.core.security import get_password_hash
from app.models import (
    Base,
    User,
    VendorProfile,
    UserRole,
    Property,
    PropertyType,
    RoomType,
    RoomAllocation,
    LocalGuide,
    ResortGuideAssociation,
    GuideAvailability,
)


async def init_db(db: AsyncSession):
    # 1. Users
    pw_hash = get_password_hash("Password123!")

    admin_user = User(
        id=uuid.UUID("a0000000-0000-0000-0000-000000000001"),
        email="admin@plane-travel.com",
        password_hash=pw_hash,
        full_name="System Administrator",
        phone_number="+1-555-0100",
        role=UserRole.ADMIN,
        is_active=True,
        is_verified=True,
    )
    hotel_vendor_user = User(
        id=uuid.UUID("a0000000-0000-0000-0000-000000000002"),
        email="host@grandmetropolis.com",
        password_hash=pw_hash,
        full_name="Marcus Vance",
        phone_number="+1-555-0101",
        role=UserRole.VENDOR,
        is_active=True,
        is_verified=True,
    )
    resort_vendor_user = User(
        id=uuid.UUID("a0000000-0000-0000-0000-000000000003"),
        email="host@azurebayresort.com",
        password_hash=pw_hash,
        full_name="Elena Rostova",
        phone_number="+1-555-0102",
        role=UserRole.VENDOR,
        is_active=True,
        is_verified=True,
    )
    customer_user = User(
        id=uuid.UUID("a0000000-0000-0000-0000-000000000006"),
        email="john.doe@example.com",
        password_hash=pw_hash,
        full_name="John Doe",
        phone_number="+1-555-0105",
        role=UserRole.CUSTOMER,
        is_active=True,
        is_verified=True,
    )
    bangalore_vendor_user = User(
        id=uuid.UUID("a0000000-0000-0000-0000-000000000010"),
        email="vendor.bangalore@leelapalace.com",
        password_hash=pw_hash,
        full_name="Devraj Sharma (Leela Hospitality)",
        phone_number="+91-80-2521-1234",
        role=UserRole.VENDOR,
        is_active=True,
        is_verified=True,
    )
    bangalore_guide_user = User(
        id=uuid.UUID("a0000000-0000-0000-0000-000000000015"),
        email="guide.arjun@travelguides.com",
        password_hash=pw_hash,
        full_name="Arjun Rao",
        phone_number="+91-98-4501-2345",
        role=UserRole.GUIDE,
        is_active=True,
        is_verified=True,
    )
    db.add_all([admin_user, hotel_vendor_user, resort_vendor_user, customer_user, bangalore_vendor_user, bangalore_guide_user])
    await db.flush()

    # 2. Vendor Profiles
    hotel_vendor_profile = VendorProfile(
        id=uuid.UUID("b0000000-0000-0000-0000-000000000001"),
        user_id=hotel_vendor_user.id,
        business_name="Metropolis Hotel Group LLC",
        tax_id="US-TAX-9823411",
        contact_email="operations@grandmetropolis.com",
        contact_phone="+1-555-0101",
        is_verified=True,
    )
    resort_vendor_profile = VendorProfile(
        id=uuid.UUID("b0000000-0000-0000-0000-000000000002"),
        user_id=resort_vendor_user.id,
        business_name="Azure Luxury Hospitality Group",
        tax_id="US-TAX-4523190",
        contact_email="concierge@azurebayresort.com",
        contact_phone="+1-555-0102",
        is_verified=True,
    )
    bangalore_vendor_profile = VendorProfile(
        id=uuid.UUID("b0000000-0000-0000-0000-000000000010"),
        user_id=bangalore_vendor_user.id,
        business_name="Royal Heritage Hospitality India Pvt Ltd",
        tax_id="IN-GST-29AABCU9603R1ZM",
        contact_email="concierge@leelapalace.com",
        contact_phone="+91-80-2521-1234",
        is_verified=True,
    )
    db.add_all([hotel_vendor_profile, resort_vendor_profile, bangalore_vendor_profile])
    await db.flush()

    # 3. Properties (Hotel vs Resort)
    hotel_prop = Property(
        id=uuid.UUID("c0000000-0000-0000-0000-000000000001"),
        vendor_id=hotel_vendor_profile.id,
        property_type=PropertyType.HOTEL,
        name="The Grand Metropolis Hotel",
        slug="the-grand-metropolis-hotel",
        description="Prime business & transit hotel situated in the heart of downtown. Features ultra-fast fiber WiFi, express 24/7 check-in, soundproof executive suites, and direct subway connectivity.",
        tagline="Speed, Luxury & Seamless Connectivity for the Modern Traveler",
        address="742 Financial Boulevard",
        city="San Francisco",
        state="California",
        country="United States",
        postal_code="94104",
        latitude=Decimal("37.7915000"),
        longitude=Decimal("-122.4010000"),
        star_rating=Decimal("4.5"),
        review_score=Decimal("4.72"),
        review_count=148,
        cover_image_url="https://images.unsplash.com/photo-1566073771259-6a8506099945?auto=format&fit=crop&w=1200&q=80",
        gallery_images=[
            "https://images.unsplash.com/photo-1582719478250-c89cae4dc85b",
            "https://images.unsplash.com/photo-1590490360182-c33d57733427",
        ],
        amenities=["Fast Fiber WiFi", "24/7 Check-in", "Executive Lounge", "Fitness Center", "Meeting Rooms", "Airport Shuttle"],
        is_published=True,
    )

    resort_prop = Property(
        id=uuid.UUID("c0000000-0000-0000-0000-000000000002"),
        vendor_id=resort_vendor_profile.id,
        property_type=PropertyType.RESORT,
        name="Azure Bay Oceanfront Resort & Sanctuary",
        slug="azure-bay-oceanfront-resort",
        description="An exclusive coastal haven featuring private overwater villas, infinity pools facing panoramic sunsets, world-class Thalasso spa therapies, and curated marine excursions led by certified resident guides.",
        tagline="Immerse in Untamed Coastal Wonder & Unrivaled Luxury",
        address="101 Coral Reef Way",
        city="Carmel-by-the-Sea",
        state="California",
        country="United States",
        postal_code="93923",
        latitude=Decimal("36.5552000"),
        longitude=Decimal("-121.9233000"),
        star_rating=Decimal("5.0"),
        review_score=Decimal("4.94"),
        review_count=312,
        cover_image_url="https://images.unsplash.com/photo-1540555700478-4be289fbecef?auto=format&fit=crop&w=1200&q=80",
        gallery_images=[
            "https://images.unsplash.com/photo-1571896349842-33c89424de2d",
            "https://images.unsplash.com/photo-1520250497591-112f2f40a3f4",
        ],
        amenities=["Private Beach Access", "Infinity Pool", "Full-Service Spa", "Local Guide Concierge", "Michelin Dining", "Water Sports", "Yoga Pavilion"],
        is_published=True,
    )

    bangalore_hotel_prop = Property(
        id=uuid.UUID("c0000000-0000-0000-0000-000000000011"),
        vendor_id=bangalore_vendor_profile.id,
        property_type=PropertyType.HOTEL,
        name="The Leela Palace Bengaluru",
        slug="the-leela-palace-bengaluru",
        description="Nestled in the lush greenery of the Garden City, The Leela Palace Bengaluru stands as a tribute to the grandeur of the Vijayanagara Empire. Offering state-of-the-art business amenities, award-winning dining, and tranquil gardens.",
        tagline="Palatial Splendor & Modern Opulence in the Garden City",
        address="23 HAL Old Airport Rd, Kodihalli",
        city="Bangalore",
        state="Karnataka",
        country="India",
        postal_code="560008",
        latitude=Decimal("12.9606000"),
        longitude=Decimal("77.6484000"),
        star_rating=Decimal("5.0"),
        review_score=Decimal("4.91"),
        review_count=524,
        cover_image_url="https://images.unsplash.com/photo-1566073771259-6a8506099945?auto=format&fit=crop&w=1200&q=80",
        gallery_images=[
            "https://images.unsplash.com/photo-1582719478250-c89cae4dc85b",
            "https://images.unsplash.com/photo-1590490360182-c33d57733427",
        ],
        amenities=["Fast Fiber WiFi", "24/7 Check-in", "Royal Club Lounge", "Luxury Spa", "Outdoor Pool", "Airport Limousine"],
        is_published=True,
    )

    bangalore_resort_prop = Property(
        id=uuid.UUID("c0000000-0000-0000-0000-000000000012"),
        vendor_id=bangalore_vendor_profile.id,
        property_type=PropertyType.RESORT,
        name="Nandi Hills Heritage Sanctuary & Ayurvedic Retreat",
        slug="nandi-hills-heritage-retreat",
        description="Perched amidst the serene clouds and rolling mist of Nandi Hills, this Ayurvedic sanctuary blends historic heritage with holistic wellness. Complete with panoramic cliffside sunrise views and curated Western Ghats expeditions.",
        tagline="Misty Valley Vistas, Ancient Ruins & Ayurvedic Healing",
        address="Nandi Foothills Sanctuary Road",
        city="Bangalore",
        state="Karnataka",
        country="India",
        postal_code="562101",
        latitude=Decimal("13.3702000"),
        longitude=Decimal("77.6835000"),
        star_rating=Decimal("4.8"),
        review_score=Decimal("4.88"),
        review_count=219,
        cover_image_url="https://images.unsplash.com/photo-1540555700478-4be289fbecef?auto=format&fit=crop&w=1200&q=80",
        gallery_images=[
            "https://images.unsplash.com/photo-1571896349842-33c89424de2d",
            "https://images.unsplash.com/photo-1520250497591-112f2f40a3f4",
        ],
        amenities=["Ayurvedic Spa & Panchakarma", "Heritage Trail Excursions", "Sunrise Yoga Pavilion", "Infinity Mountain Pool", "Resident Naturalist Guides", "Organic Farm-to-Table Dining"],
        is_published=True,
    )

    db.add_all([hotel_prop, resort_prop, bangalore_hotel_prop, bangalore_resort_prop])
    await db.flush()

    # 4. Room Types
    hotel_room_1 = RoomType(
        id=uuid.UUID("d0000000-0000-0000-0000-000000000001"),
        property_id=hotel_prop.id,
        name="Urban Executive King",
        description="Ergonomic workstation, soundproof double-glazed glass, Nespresso bar, and rain shower.",
        max_occupancy=2,
        bed_configuration="1 King Bed",
        base_price_per_night=Decimal("220.00"),
        amenities=["Smart TV", "Ergonomic Desk", "Rain Shower", "High-speed WiFi", "Minibar"],
        images=["https://images.unsplash.com/photo-1618773928121-c32242e63f39"],
        is_active=True,
    )
    hotel_room_2 = RoomType(
        id=uuid.UUID("d0000000-0000-0000-0000-000000000002"),
        property_id=hotel_prop.id,
        name="Metropolis Skyline Suite",
        description="Panoramic corner views of the downtown skyline with separate living lounge.",
        max_occupancy=3,
        bed_configuration="1 King Bed + 1 Sofa Bed",
        base_price_per_night=Decimal("380.00"),
        amenities=["Skyline View", "Bathtub", "Living Lounge", "Complimentary Breakfast", "Soundproof"],
        images=["https://images.unsplash.com/photo-1591088398332-8a7791972843"],
        is_active=True,
    )
    resort_room_1 = RoomType(
        id=uuid.UUID("d0000000-0000-0000-0000-000000000003"),
        property_id=resort_prop.id,
        name="Overwater Sunset Pavilion",
        description="Direct glass bottom reef view, outdoor plunge pool, and private sun deck over the bay.",
        max_occupancy=2,
        bed_configuration="1 California King Bed",
        base_price_per_night=Decimal("750.00"),
        amenities=["Private Plunge Pool", "Glass Floor", "Butler Service", "Direct Ocean Access", "Wine Cellar"],
        images=["https://images.unsplash.com/photo-1582719478250-c89cae4dc85b"],
        is_active=True,
    )
    resort_room_2 = RoomType(
        id=uuid.UUID("d0000000-0000-0000-0000-000000000004"),
        property_id=resort_prop.id,
        name="Beachfront Garden Villa",
        description="Surrounded by lush tropical flora steps away from the golden sands.",
        max_occupancy=4,
        bed_configuration="2 Queen Beds",
        base_price_per_night=Decimal("520.00"),
        amenities=["Private Garden", "Outdoor Stone Shower", "Direct Beach Walkway", "Espresso Bar"],
        images=["https://images.unsplash.com/photo-1590490360182-c33d57733427"],
        is_active=True,
    )

    bangalore_hotel_room_1 = RoomType(
        id=uuid.UUID("d0000000-0000-0000-0000-000000000011"),
        property_id=bangalore_hotel_prop.id,
        name="Royal Premiere Heritage Room",
        description="Inspired by Mysore royal motifs, featuring Italian marble bathroom, high-speed fiber internet, and private balcony.",
        max_occupancy=2,
        bed_configuration="1 King Bed",
        base_price_per_night=Decimal("180.00"),
        amenities=["Smart TV", "Ergonomic Desk", "Italian Marble Bath", "High-speed WiFi", "Minibar"],
        images=["https://images.unsplash.com/photo-1618773928121-c32242e63f39"],
        is_active=True,
    )
    bangalore_hotel_room_2 = RoomType(
        id=uuid.UUID("d0000000-0000-0000-0000-000000000012"),
        property_id=bangalore_hotel_prop.id,
        name="Maharaja Executive Suite",
        description="Lavish duplex suite with panoramic view of the gardens, butler service, and dedicated dining lounge.",
        max_occupancy=3,
        bed_configuration="1 King Bed + 1 Daybed",
        base_price_per_night=Decimal("340.00"),
        amenities=["Garden View", "Jacuzzi Bathtub", "Butler Service", "Complimentary High Tea", "Executive Lounge Access"],
        images=["https://images.unsplash.com/photo-1591088398332-8a7791972843"],
        is_active=True,
    )
    bangalore_resort_room_1 = RoomType(
        id=uuid.UUID("d0000000-0000-0000-0000-000000000013"),
        property_id=bangalore_resort_prop.id,
        name="Valley View Heritage Chalet",
        description="Overlooking the misty valley gorge with handcrafted teakwood furniture and private Ayurvedic soaking tub.",
        max_occupancy=2,
        bed_configuration="1 King Bed",
        base_price_per_night=Decimal("290.00"),
        amenities=["Misty Valley View", "Stone Soaking Tub", "Ayurvedic Herbal Bar", "Fireplace", "Yoga Mat & Props"],
        images=["https://images.unsplash.com/photo-1582719478250-c89cae4dc85b"],
        is_active=True,
    )
    bangalore_resort_room_2 = RoomType(
        id=uuid.UUID("d0000000-0000-0000-0000-000000000014"),
        property_id=bangalore_resort_prop.id,
        name="Misty Cliff Plantation Villa",
        description="Sprawling two-bedroom villa nestled amongst aromatic coffee and eucalyptus trees with private infinity deck.",
        max_occupancy=4,
        bed_configuration="2 King Beds",
        base_price_per_night=Decimal("480.00"),
        amenities=["Private Infinity Deck", "Eucalyptus Garden View", "Dedicated Yoga Master", "Outdoor Shower", "Dining Gazebo"],
        images=["https://images.unsplash.com/photo-1590490360182-c33d57733427"],
        is_active=True,
    )

    db.add_all([
        hotel_room_1, hotel_room_2, resort_room_1, resort_room_2,
        bangalore_hotel_room_1, bangalore_hotel_room_2,
        bangalore_resort_room_1, bangalore_resort_room_2,
    ])
    await db.flush()

    # 5. Local Guides
    guide_1 = LocalGuide(
        id=uuid.UUID("e0000000-0000-0000-0000-000000000001"),
        vendor_id=resort_vendor_profile.id,
        full_name="Captain Kai Tanaka",
        headline="Certified Marine Biologist & Coastal Sailing Master",
        bio="With over 12 years navigating the Monterey Bay marine sanctuary, Kai leads intimate snorkeling, whale watching, and underwater ecology expeditions for all skill levels.",
        profile_photo_url="https://images.unsplash.com/photo-1534528741775-53994a69daeb?auto=format&fit=crop&w=400&q=80",
        languages=["English", "Japanese"],
        years_of_experience=12,
        license_number="USCG-MAR-77341",
        hourly_rate=Decimal("50.00"),
        daily_rate=Decimal("300.00"),
        specialties=["Kelp Forest Snorkeling", "Whale Watching", "Sunset Sailing", "Marine Ecology"],
        rating=Decimal("4.98"),
        review_count=86,
        is_verified=True,
        is_active=True,
    )
    guide_2 = LocalGuide(
        id=uuid.UUID("e0000000-0000-0000-0000-000000000002"),
        vendor_id=resort_vendor_profile.id,
        full_name="Dr. Maya Lin",
        headline="Cultural Anthropologist & Wilderness Trek Leader",
        bio="Dr. Lin specializes in native flora foraging, indigenous history hikes along the rugged Big Sur cliffs, and immersive stargazing tours.",
        profile_photo_url="https://images.unsplash.com/photo-1573496359142-b8d87734a5a2?auto=format&fit=crop&w=400&q=80",
        languages=["English", "Mandarin", "Spanish"],
        years_of_experience=8,
        license_number="CA-NAT-29188",
        hourly_rate=Decimal("45.00"),
        daily_rate=Decimal("260.00"),
        specialties=["Cliffside Hiking", "Foraging & Botanical Tours", "Night Sky Astronomy", "Coastal Photography"],
        rating=Decimal("4.95"),
        review_count=64,
        is_verified=True,
        is_active=True,
    )
    bangalore_guide = LocalGuide(
        id=uuid.UUID("e0000000-0000-0000-0000-000000000011"),
        user_id=bangalore_guide_user.id,
        vendor_id=bangalore_vendor_profile.id,
        full_name="Arjun Rao",
        headline="Karnataka Heritage Historian & Western Ghats Naturalist",
        bio="Passionate naturalist and cultural custodian with 10+ years exploring Bangalore heritage sites, Tipu Sultan fortresses, and Nandi valley birding trails.",
        profile_photo_url="https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?auto=format&fit=crop&w=400&q=80",
        languages=["English", "Kannada", "Hindi"],
        years_of_experience=10,
        license_number="KA-TOUR-44091",
        hourly_rate=Decimal("25.00"),
        daily_rate=Decimal("140.00"),
        specialties=["Nandi Sunrise Trekking", "Chola Architecture Walks", "Western Ghats Birding", "Botanical & Spice Walks"],
        rating=Decimal("4.97"),
        review_count=112,
        is_verified=True,
        is_active=True,
    )
    db.add_all([guide_1, guide_2, bangalore_guide])
    await db.flush()

    # 6. Resort Guide Associations
    assoc_1 = ResortGuideAssociation(
        resort_id=resort_prop.id,
        guide_id=guide_1.id,
        is_primary=True,
    )
    assoc_2 = ResortGuideAssociation(
        resort_id=resort_prop.id,
        guide_id=guide_2.id,
        is_primary=False,
    )
    assoc_3 = ResortGuideAssociation(
        resort_id=bangalore_resort_prop.id,
        guide_id=bangalore_guide.id,
        is_primary=True,
    )
    db.add_all([assoc_1, assoc_2, assoc_3])
    await db.flush()

    # 7. Generate 365-Day Room Allocations & Guide Calendars
    today = date.today()
    allocations = []
    guide_avails = []

    for d in range(365):
        target_d = today + timedelta(days=d)

        # Hotel Room 1: 10 rooms
        allocations.append(
            RoomAllocation(
                room_type_id=hotel_room_1.id,
                allocation_date=target_d,
                total_allocated=10,
                booked_count=0,
                rate_multiplier=Decimal("1.00"),
                is_closed=False,
            )
        )
        # Hotel Room 2: 5 rooms
        allocations.append(
            RoomAllocation(
                room_type_id=hotel_room_2.id,
                allocation_date=target_d,
                total_allocated=5,
                booked_count=0,
                rate_multiplier=Decimal("1.00"),
                is_closed=False,
            )
        )
        # Resort Room 1: 4 rooms
        allocations.append(
            RoomAllocation(
                room_type_id=resort_room_1.id,
                allocation_date=target_d,
                total_allocated=4,
                booked_count=0,
                rate_multiplier=Decimal("1.00"),
                is_closed=False,
            )
        )
        # Resort Room 2: 6 rooms
        allocations.append(
            RoomAllocation(
                room_type_id=resort_room_2.id,
                allocation_date=target_d,
                total_allocated=6,
                booked_count=0,
                rate_multiplier=Decimal("1.00"),
                is_closed=False,
            )
        )
        # Bangalore Hotel Room 1: 12 rooms
        allocations.append(
            RoomAllocation(
                room_type_id=bangalore_hotel_room_1.id,
                allocation_date=target_d,
                total_allocated=12,
                booked_count=0,
                rate_multiplier=Decimal("1.00"),
                is_closed=False,
            )
        )
        # Bangalore Hotel Room 2: 6 rooms
        allocations.append(
            RoomAllocation(
                room_type_id=bangalore_hotel_room_2.id,
                allocation_date=target_d,
                total_allocated=6,
                booked_count=0,
                rate_multiplier=Decimal("1.00"),
                is_closed=False,
            )
        )
        # Bangalore Resort Room 1: 8 rooms
        allocations.append(
            RoomAllocation(
                room_type_id=bangalore_resort_room_1.id,
                allocation_date=target_d,
                total_allocated=8,
                booked_count=0,
                rate_multiplier=Decimal("1.00"),
                is_closed=False,
            )
        )
        # Bangalore Resort Room 2: 4 rooms
        allocations.append(
            RoomAllocation(
                room_type_id=bangalore_resort_room_2.id,
                allocation_date=target_d,
                total_allocated=4,
                booked_count=0,
                rate_multiplier=Decimal("1.00"),
                is_closed=False,
            )
        )
        # Guide 1 Availability
        guide_avails.append(
            GuideAvailability(
                guide_id=guide_1.id,
                availability_date=target_d,
                is_available=True,
                is_booked=False,
            )
        )
        # Guide 2 Availability
        guide_avails.append(
            GuideAvailability(
                guide_id=guide_2.id,
                availability_date=target_d,
                is_available=True,
                is_booked=False,
            )
        )
        # Bangalore Guide Availability
        guide_avails.append(
            GuideAvailability(
                guide_id=bangalore_guide.id,
                availability_date=target_d,
                is_available=True,
                is_booked=False,
            )
        )

    db.add_all(allocations)
    db.add_all(guide_avails)
    await db.commit()
    print("Database seeding completed successfully!")


async def main():
    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.create_all)
    async with AsyncSessionLocal() as session:
        await init_db(session)


if __name__ == "__main__":
    asyncio.run(main())
