import pytest
from datetime import date, timedelta
from httpx import AsyncClient


async def get_admin_token(client: AsyncClient) -> str:
    login_payload = {
        "email": "admin@plane-travel.com",
        "password": "Password123!",
    }
    res = await client.post("/api/v1/auth/login", json=login_payload)
    return res.json()["data"]["access_token"]


async def get_vendor_token(client: AsyncClient) -> str:
    login_payload = {
        "email": "host@grandmetropolis.com",
        "password": "Password123!",
    }
    res = await client.post("/api/v1/auth/login", json=login_payload)
    return res.json()["data"]["access_token"]


@pytest.mark.asyncio
async def test_vendor_properties_and_allocations(client: AsyncClient):
    token = await get_vendor_token(client)
    headers = {"Authorization": f"Bearer {token}"}

    # 1. Get vendor properties
    res = await client.get("/api/v1/vendor/properties", headers=headers)
    assert res.status_code == 200
    props = res.json()["data"]
    assert len(props) >= 1
    assert props[0]["name"] == "The Grand Metropolis Hotel"

    # 2. Update room allocations batch
    hotel_res = await client.get("/api/v1/hotels")
    hotel_id = hotel_res.json()["data"][0]["id"]
    detail_res = await client.get(f"/api/v1/hotels/{hotel_id}")
    room_type_id = detail_res.json()["data"]["room_types"][0]["id"]

    today = date.today()
    batch_payload = {
        "room_type_id": room_type_id,
        "start_date": (today + timedelta(days=40)).isoformat(),
        "end_date": (today + timedelta(days=45)).isoformat(),
        "total_allocated": 12,
        "rate_multiplier": 1.15,
        "is_closed": False,
    }
    batch_res = await client.post("/api/v1/vendor/allocations/batch", json=batch_payload, headers=headers)
    assert batch_res.status_code == 200
    allocations = batch_res.json()["data"]
    assert len(allocations) == 6
    assert allocations[0]["total_allocated"] == 12


@pytest.mark.asyncio
async def test_admin_overview_and_telemetry(client: AsyncClient):
    token = await get_admin_token(client)
    headers = {"Authorization": f"Bearer {token}"}

    res = await client.get("/api/v1/admin/overview", headers=headers)
    assert res.status_code == 200
    overview = res.json()["data"]
    assert overview["total_users"] >= 4
    assert overview["total_hotels"] >= 1
    assert overview["total_resorts"] >= 1
    assert overview["total_guides"] >= 2
