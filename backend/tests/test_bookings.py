import pytest
from datetime import date, timedelta
from httpx import AsyncClient


async def get_auth_token(client: AsyncClient) -> str:
    login_payload = {
        "email": "traveler.alex@example.com",
        "password": "Password123!",
    }
    res = await client.post("/api/v1/auth/login", json=login_payload)
    return res.json()["data"]["access_token"]


@pytest.mark.asyncio
async def test_price_quote_with_guide_bundle(client: AsyncClient):
    # Fetch Resort & Room Types
    resort_res = await client.get("/api/v1/resorts")
    resort_id = resort_res.json()["data"][0]["id"]

    detail_res = await client.get(f"/api/v1/resorts/{resort_id}")
    room_type_id = detail_res.json()["data"]["room_types"][0]["id"]
    guide_id = detail_res.json()["data"]["associated_guides"][0]["id"]

    today = date.today()
    check_in = (today + timedelta(days=5)).isoformat()
    check_out = (today + timedelta(days=7)).isoformat()  # 2 nights

    quote_payload = {
        "property_id": resort_id,
        "check_in_date": check_in,
        "check_out_date": check_out,
        "room_items": [{"room_type_id": room_type_id, "rooms_count": 1}],
        "guide_bundle": {
            "guide_id": guide_id,
            "service_date": check_in,
            "duration_days": 1,
            "special_requirements": "Private morning snorkeling reef expedition",
        },
    }

    res = await client.post("/api/v1/bookings/quote", json=quote_payload)
    assert res.status_code == 200
    quote = res.json()["data"]
    assert quote["total_nights"] == 2
    assert float(quote["room_subtotal"]) > 0
    assert float(quote["guide_subtotal"]) == 300.0  # Capt Kai daily rate
    assert float(quote["platform_fee"]) > 0
    assert float(quote["tax_amount"]) > 0
    assert float(quote["total_amount"]) > float(quote["room_subtotal"]) + float(quote["guide_subtotal"])
    assert quote["is_available"] is True


@pytest.mark.asyncio
async def test_create_bundled_resort_reservation(client: AsyncClient):
    token = await get_auth_token(client)
    headers = {"Authorization": f"Bearer {token}"}

    # Fetch Resort, Room Type, and Guide
    resort_res = await client.get("/api/v1/resorts")
    resort_id = resort_res.json()["data"][0]["id"]

    detail_res = await client.get(f"/api/v1/resorts/{resort_id}")
    room_type_id = detail_res.json()["data"]["room_types"][0]["id"]
    guide_id = detail_res.json()["data"]["associated_guides"][0]["id"]

    today = date.today()
    check_in = (today + timedelta(days=10)).isoformat()
    check_out = (today + timedelta(days=12)).isoformat()

    booking_payload = {
        "property_id": resort_id,
        "check_in_date": check_in,
        "check_out_date": check_out,
        "guest_count": 2,
        "room_items": [{"room_type_id": room_type_id, "rooms_count": 1}],
        "guide_bundle": {
            "guide_id": guide_id,
            "service_date": check_in,
            "duration_days": 1,
            "special_requirements": "Looking forward to exploring the marine reserve!",
        },
        "special_requests": "Ocean view high floor if possible.",
    }

    res = await client.post("/api/v1/bookings", json=booking_payload, headers=headers)
    assert res.status_code == 201
    booking = res.json()["data"]
    assert booking["reservation_code"].startswith("OTA-")
    assert booking["booking_type"] == "RESORT_WITH_GUIDE"
    assert booking["status"] == "CONFIRMED"
    assert booking["guide_item"] is not None
    assert booking["guide_item"]["guide_name"] == "Captain Kai Tanaka"
    assert len(booking["room_items"]) == 1

    # Verify user can retrieve their reservations
    my_res = await client.get("/api/v1/bookings/my-reservations", headers=headers)
    assert my_res.status_code == 200
    my_bookings = my_res.json()["data"]
    assert len(my_bookings) >= 1
    assert my_bookings[0]["reservation_code"] == booking["reservation_code"]


@pytest.mark.asyncio
async def test_allocation_overbooking_prevention(client: AsyncClient):
    token = await get_auth_token(client)
    headers = {"Authorization": f"Bearer {token}"}

    # Fetch Hotel & Room Type
    hotel_res = await client.get("/api/v1/hotels")
    hotel_id = hotel_res.json()["data"][0]["id"]

    detail_res = await client.get(f"/api/v1/hotels/{hotel_id}")
    room_type_id = detail_res.json()["data"]["room_types"][0]["id"]  # 10 rooms allocated

    today = date.today()
    check_in = (today + timedelta(days=20)).isoformat()
    check_out = (today + timedelta(days=21)).isoformat()

    # Attempt to book 15 rooms (more than 10 total allocated)
    overbook_payload = {
        "property_id": hotel_id,
        "check_in_date": check_in,
        "check_out_date": check_out,
        "guest_count": 30,
        "room_items": [{"room_type_id": room_type_id, "rooms_count": 15}],
    }

    res = await client.post("/api/v1/bookings", json=overbook_payload, headers=headers)
    assert res.status_code == 409
    assert "Overbooking prevented" in res.json()["detail"]
