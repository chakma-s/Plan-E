import pytest
from datetime import date, timedelta
from httpx import AsyncClient


@pytest.mark.asyncio
async def test_search_hotels(client: AsyncClient):
    # 1. Search without filters
    res = await client.get("/api/v1/hotels")
    assert res.status_code == 200
    data = res.json()["data"]
    assert len(data) >= 1
    assert data[0]["property_type"] == "HOTEL"
    assert data[0]["name"] == "The Grand Metropolis Hotel"
    assert float(data[0]["min_price_per_night"]) == 220.0

    # 2. Search by City
    res_city = await client.get("/api/v1/hotels?city=San Francisco")
    assert res_city.status_code == 200
    city_data = res_city.json()["data"]
    assert len(city_data) == 1

    # 3. Search by Mapbox Bounding Box (San Francisco Coordinates)
    res_geo = await client.get(
        "/api/v1/hotels?min_lat=37.0&max_lat=38.5&min_lon=-123.0&max_lon=-121.0"
    )
    assert res_geo.status_code == 200
    geo_data = res_geo.json()["data"]
    assert len(geo_data) == 1


@pytest.mark.asyncio
async def test_get_hotel_detail(client: AsyncClient):
    # Retrieve hotel ID from search
    search_res = await client.get("/api/v1/hotels")
    hotel_id = search_res.json()["data"][0]["id"]

    today = date.today()
    check_in = today.isoformat()
    check_out = (today + timedelta(days=2)).isoformat()

    detail_res = await client.get(
        f"/api/v1/hotels/{hotel_id}?check_in={check_in}&check_out={check_out}"
    )
    assert detail_res.status_code == 200
    hotel = detail_res.json()["data"]
    assert hotel["name"] == "The Grand Metropolis Hotel"
    assert len(hotel["room_types"]) == 2
    assert hotel["room_types"][0]["available_rooms"] == 10
