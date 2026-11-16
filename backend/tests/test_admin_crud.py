import pytest
from httpx import AsyncClient
from decimal import Decimal


@pytest.mark.asyncio
async def test_admin_crud_workflow(client: AsyncClient):
    # 1. Login as Admin
    login_resp = await client.post(
        "/api/v1/auth/login",
        json={"email": "admin@plane-travel.com", "password": "Password123!"},
    )
    assert login_resp.status_code == 200
    admin_token = login_resp.json()["data"]["access_token"]
    headers = {"Authorization": f"Bearer {admin_token}"}

    # 2. List Properties via Admin Endpoint
    list_resp = await client.get("/api/v1/admin/properties", headers=headers)
    assert list_resp.status_code == 200
    initial_props = list_resp.json()["data"]
    assert len(initial_props) >= 1
    assert "starting_price" in initial_props[0]
    assert "room_types" in initial_props[0]

    # 3. Create a New Property as Admin
    new_prop_data = {
        "name": "Admin Grand Heritage Palace",
        "property_type": "HOTEL",
        "tagline": "Palatial grandeur in Jaipur",
        "description": "Historic Rajputana palace converted into a world-class luxury hotel with royal dining.",
        "address": "Bhawani Singh Road",
        "city": "Jaipur",
        "state": "Rajasthan",
        "country": "India",
        "postal_code": "302005",
        "latitude": 26.8920,
        "longitude": 75.8078,
        "star_rating": 5.0,
        "cover_image_url": "https://images.unsplash.com/photo-1566073771259-6a8506099945?auto=format&fit=crop&w=1200&q=80",
        "gallery_images": [
            "https://images.unsplash.com/photo-1582719478250-c89cae4dc85b?auto=format&fit=crop&w=1200&q=80"
        ],
        "amenities": ["Royal Dining", "Heritage Spa", "Heated Pool", "Butler Service"],
        "check_in_time": "14:00:00",
        "check_out_time": "12:00:00",
        "cancellation_policy": "Full refund up to 24 hours before check-in.",
        "is_published": True,
    }
    create_resp = await client.post("/api/v1/admin/properties", json=new_prop_data, headers=headers)
    assert create_resp.status_code == 201
    prop_id = create_resp.json()["data"]["id"]
    assert create_resp.json()["data"]["name"] == "Admin Grand Heritage Palace"

    # 4. Fetch the Single Property Details
    get_resp = await client.get(f"/api/v1/admin/properties/{prop_id}", headers=headers)
    assert get_resp.status_code == 200
    assert get_resp.json()["data"]["name"] == "Admin Grand Heritage Palace"
    assert get_resp.json()["data"]["is_published"] is True

    # 5. Update Property Details (CRUD Update)
    patch_prop_data = {
        "tagline": "Updated: Royal Rajputana Hospitality & Heritage",
        "star_rating": 4.9,
        "property_type": "RESORT",
    }
    update_resp = await client.patch(
        f"/api/v1/admin/properties/{prop_id}", json=patch_prop_data, headers=headers
    )
    assert update_resp.status_code == 200
    assert update_resp.json()["data"]["property_type"] == "RESORT"

    # 6. Add Room Type to Property and Verify Inventory Seeding
    new_room_data = {
        "name": "Maharaja Royal Suite",
        "description": "Opulent suite with antique fresco ceilings and private courtyard.",
        "max_occupancy": 3,
        "bed_configuration": "1 Royal King Bed",
        "base_price_per_night": 750.00,
        "amenities": ["Private Courtyard", "Butler Service", "Jacuzzi"],
        "images": ["https://images.unsplash.com/photo-1590490360182-c33d57733427?auto=format&fit=crop&w=1200&q=80"],
        "is_active": True,
    }
    create_room_resp = await client.post(
        f"/api/v1/admin/properties/{prop_id}/rooms", json=new_room_data, headers=headers
    )
    assert create_room_resp.status_code == 201
    room_id = create_room_resp.json()["data"]["id"]
    assert create_room_resp.json()["data"]["base_price_per_night"] == 750.00

    # 7. Update Room Price (CRUD Price Edit)
    patch_room_data = {
        "base_price_per_night": 899.50,
        "max_occupancy": 4,
    }
    update_room_resp = await client.patch(
        f"/api/v1/admin/rooms/{room_id}", json=patch_room_data, headers=headers
    )
    assert update_room_resp.status_code == 200
    assert update_room_resp.json()["data"]["base_price_per_night"] == 899.50
    assert update_room_resp.json()["data"]["max_occupancy"] == 4

    # 8. Quick Toggle Publish Status
    toggle_resp = await client.patch(
        f"/api/v1/admin/properties/{prop_id}/publish?is_published=false", headers=headers
    )
    assert toggle_resp.status_code == 200
    assert toggle_resp.json()["data"]["is_published"] is False

    # 9. Clean Up: Hard Delete Property and Cascade Room Types
    delete_resp = await client.delete(
        f"/api/v1/admin/properties/{prop_id}?hard_delete=true", headers=headers
    )
    assert delete_resp.status_code == 200


@pytest.mark.asyncio
async def test_admin_unauthorized_for_regular_users(client: AsyncClient):
    # Register/login as regular traveler
    login_resp = await client.post(
        "/api/v1/auth/login",
        json={"email": "john.doe@example.com", "password": "Password123!"},
    )
    assert login_resp.status_code == 200
    user_token = login_resp.json()["data"]["access_token"]

    # Regular user attempting admin endpoint should receive 403 Forbidden
    forbidden_resp = await client.get(
        "/api/v1/admin/properties",
        headers={"Authorization": f"Bearer {user_token}"},
    )
    assert forbidden_resp.status_code == 403
