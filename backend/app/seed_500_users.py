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


async def seed_500_user_ecosystem(db: AsyncSession):
    """
    Expands the inventory and guide ecosystem to support 500+ active beta travelers
    across top high-demand destinations (San Francisco, Carmel, Maui, Aspen, Miami).
    """
    pw_hash = get_password_hash("Password123!")

    # 1. Additional Vendors
    v_maui_user = User(
        email="host@mauiparadise.com",
        password_hash=pw_hash,
        full_name="Keanu Akana",
        role=UserRole.VENDOR,
        is_active=True,
        is_verified=True,
    )
    v_aspen_user = User(
        email="host@aspenpeaks.com",
        password_hash=pw_hash,
        full_name="Sarah Sterling",
        role=UserRole.VENDOR,
        is_active=True,
        is_verified=True,
    )
    v_miami_user = User(
        email="host@miamibeachclub.com",
        password_hash=pw_hash,
        full_name="Carlos Mendez",
        role=UserRole.VENDOR,
        is_active=True,
        is_verified=True,
    )
    db.add_all([v_maui_user, v_aspen_user, v_miami_user])
    await db.flush()

    v_maui_prof = VendorProfile(
        user_id=v_maui_user.id,
        business_name="Maui Luxury Sanctuary Collection",
        contact_email="concierge@mauiparadise.com",
        contact_phone="+1-808-555-0199",
        is_verified=True,
    )
    v_aspen_prof = VendorProfile(
        user_id=v_aspen_user.id,
        business_name="Aspen Alpine Chalets LLC",
        contact_email="host@aspenpeaks.com",
        contact_phone="+1-970-555-0144",
        is_verified=True,
    )
    v_miami_prof = VendorProfile(
        user_id=v_miami_user.id,
        business_name="South Beach Hospitality Group",
        contact_email="reservations@miamibeachclub.com",
        contact_phone="+1-305-555-0188",
        is_verified=True,
    )
    db.add_all([v_maui_prof, v_aspen_prof, v_miami_prof])
    await db.flush()

    # 2. Properties
    # Maui Resort
    prop_maui = Property(
        vendor_id=v_maui_prof.id,
        property_type=PropertyType.RESORT,
        name="Wailea Palms Oceanfront Eco-Sanctuary",
        slug="wailea-palms-oceanfront-eco-sanctuary",
        description="Exclusive secluded Maui haven with private volcanic rock plunge pools, organic farm-to-table dining, and direct access to protected sea turtle reefs.",
        tagline="Where Volcanic Grandeur Meets Pacific Serenity",
        address="3900 Wailea Alanui Dr",
        city="Wailea",
        state="Hawaii",
        country="United States",
        postal_code="96753",
        latitude=Decimal("20.6898000"),
        longitude=Decimal("-156.4422000"),
        star_rating=Decimal("5.0"),
        review_score=Decimal("4.97"),
        review_count=420,
        cover_image_url="https://images.unsplash.com/photo-1540555700478-4be289fbecef?auto=format&fit=crop&w=1200&q=80",
        amenities=["Private Plunge Pools", "Sea Turtle Reef Access", "Organic Spa", "Local Guide Concierge", "Yoga Pavilion"],
        is_published=True,
    )
    # Aspen Resort
    prop_aspen = Property(
        vendor_id=v_aspen_prof.id,
        property_type=PropertyType.RESORT,
        name="Silver Peak Alpine Lodge & Spa",
        slug="silver-peak-alpine-lodge-and-spa",
        description="Ski-in/ski-out luxury chalets nestled in the Colorado Rockies. Heated outdoor mineral pools, fireside master suites, and mountain backcountry guides.",
        tagline="Uncompromising Alpine Luxury in the Heart of the Rockies",
        address="550 S Spring St",
        city="Aspen",
        state="Colorado",
        country="United States",
        postal_code="81611",
        latitude=Decimal("39.1887000"),
        longitude=Decimal("-106.8185000"),
        star_rating=Decimal("4.9"),
        review_score=Decimal("4.91"),
        review_count=215,
        cover_image_url="https://images.unsplash.com/photo-1518684079-3c830dcef090?auto=format&fit=crop&w=1200&q=80",
        amenities=["Ski-in/Ski-out", "Mineral Pools", "Fireplace Suites", "Backcountry Ski Guides", "Michelin Dining"],
        is_published=True,
    )
    # Miami City Hotel
    prop_miami = Property(
        vendor_id=v_miami_prof.id,
        property_type=PropertyType.HOTEL,
        name="The Lumina Miami Beachfront Hotel",
        slug="the-lumina-miami-beachfront-hotel",
        description="Vibrant boutique design hotel steps from Ocean Drive. Ultra-fast WiFi, rooftop cocktail lounge, 24/7 express mobile check-in, and private pool cabanas.",
        tagline="High-Energy Design & Seamless Miami Connectivity",
        address="1120 Ocean Drive",
        city="Miami Beach",
        state="Florida",
        country="United States",
        postal_code="33139",
        latitude=Decimal("25.7825000"),
        longitude=Decimal("-80.1303000"),
        star_rating=Decimal("4.6"),
        review_score=Decimal("4.78"),
        review_count=360,
        cover_image_url="https://images.unsplash.com/photo-1566073771259-6a8506099945?auto=format&fit=crop&w=1200&q=80",
        amenities=["Rooftop Pool", "Fiber WiFi", "24/7 Express Check-in", "Beachside Cabanas", "Valet Parking"],
        is_published=True,
    )
    db.add_all([prop_maui, prop_aspen, prop_miami])
    await db.flush()

    # 3. Room Types
    r_maui = RoomType(
        property_id=prop_maui.id,
        name="Oceanfront Turtle Bay Villa",
        max_occupancy=4,
        bed_configuration="1 King Bed + 2 Daybeds",
        base_price_per_night=Decimal("680.00"),
        amenities=["Private Pool", "Ocean View", "Butler Service"],
        is_active=True,
    )
    r_aspen = RoomType(
        property_id=prop_aspen.id,
        name="Grand Fireplace Alpine Suite",
        max_occupancy=2,
        bed_configuration="1 King Bed",
        base_price_per_night=Decimal("540.00"),
        amenities=["Wood Fireplace", "Mountain View", "Heated Floors"],
        is_active=True,
    )
    r_miami = RoomType(
        property_id=prop_miami.id,
        name="Art Deco King Studio",
        max_occupancy=2,
        bed_configuration="1 King Bed",
        base_price_per_night=Decimal("260.00"),
        amenities=["Smart TV", "Minibar", "Rain Shower"],
        is_active=True,
    )
    db.add_all([r_maui, r_aspen, r_miami])
    await db.flush()

    # 4. Local Guides
    g_maui = LocalGuide(
        full_name="Leilani Kealoha",
        headline="Master Outrigger Navigator & Native Reef Naturalist",
        bio="Born and raised on Maui, Leilani guides authentic outrigger canoe expeditions, whale telemetry listening tours, and secluded waterfall botanical treks.",
        profile_photo_url="https://images.unsplash.com/photo-1573496359142-b8d87734a5a2?auto=format&fit=crop&w=400&q=80",
        languages=["English", "Hawaiian"],
        years_of_experience=15,
        hourly_rate=Decimal("55.00"),
        daily_rate=Decimal("320.00"),
        specialties=["Outrigger Canoe Tours", "Whale Listening Excursions", "Waterfall Trekking", "Hawaiian Ethnobotany"],
        rating=Decimal("4.99"),
        review_count=142,
        is_verified=True,
        is_active=True,
    )
    g_aspen = LocalGuide(
        full_name="Hans Lindqvist",
        headline="IFMGA Certified Mountain Guide & Avalanche Specialist",
        bio="Hans has guided high-altitude ski mountaineering in the Alps and Rockies for over 18 years, leading backcountry powder safaris and wilderness avalanche safety courses.",
        profile_photo_url="https://images.unsplash.com/photo-1534528741775-53994a69daeb?auto=format&fit=crop&w=400&q=80",
        languages=["English", "German", "French"],
        years_of_experience=18,
        hourly_rate=Decimal("65.00"),
        daily_rate=Decimal("380.00"),
        specialties=["Backcountry Ski Safaris", "Glacier Trekking", "Avalanche Safety", "Alpine Photography"],
        rating=Decimal("5.00"),
        review_count=98,
        is_verified=True,
        is_active=True,
    )
    db.add_all([g_maui, g_aspen])
    await db.flush()

    # Link guides to resorts
    assoc_m = ResortGuideAssociation(resort_id=prop_maui.id, guide_id=g_maui.id, is_primary=True)
    assoc_a = ResortGuideAssociation(resort_id=prop_aspen.id, guide_id=g_aspen.id, is_primary=True)
    db.add_all([assoc_m, assoc_a])
    await db.flush()

    # 5. Generate 60-day Allocations & Guide Calendars (Ample inventory for 500 users)
    today = date.today()
    allocs = []
    guide_avs = []

    for d in range(60):
        target_d = today + timedelta(days=d)
        allocs.append(RoomAllocation(room_type_id=r_maui.id, allocation_date=target_d, total_allocated=15, booked_count=0))
        allocs.append(RoomAllocation(room_type_id=r_aspen.id, allocation_date=target_d, total_allocated=12, booked_count=0))
        allocs.append(RoomAllocation(room_type_id=r_miami.id, allocation_date=target_d, total_allocated=20, booked_count=0))
        guide_avs.append(GuideAvailability(guide_id=g_maui.id, availability_date=target_d, is_available=True, is_booked=False))
        guide_avs.append(GuideAvailability(guide_id=g_aspen.id, availability_date=target_d, is_available=True, is_booked=False))

    db.add_all(allocs)
    db.add_all(guide_avs)
    await db.commit()
    print("500-User Ecosystem Expansion Seeded Successfully!")


async def main():
    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.create_all)
    async with AsyncSessionLocal() as session:
        await seed_500_user_ecosystem(session)


if __name__ == "__main__":
    asyncio.run(main())
