import pytest
from datetime import date, timedelta
from httpx import AsyncClient


@pytest.mark.asyncio
async def test_search_resorts_with_guide_preview(client: AsyncClient):
    # 1. Search Resorts
    res = await client.get("/api/v1/resorts")
    assert res.status_code == 200
    data = res.json()["data"]
    assert len(data) >= 1
    resort = data[0]
    assert resort["property_type"] == "RESORT"
    assert resort["name"] == "Azure Bay Oceanfront Resort & Sanctuary"
    assert float(resort["starting_price_per_night"]) == 520.0
    # Verify Local Guide Bundling feature preview on resort card
    assert resort["available_guides_count"] >= 1
    assert len(resort["featured_guides"]) >= 1
    assert resort["featured_guides"][0]["full_name"] == "Captain Kai Tanaka"


@pytest.mark.asyncio
async def test_get_resort_detail_with_guides(client: AsyncClient):
    search_res = await client.get("/api/v1/resorts")
    resort_id = search_res.json()["data"][0]["id"]

    today = date.today()
    check_in = today.isoformat()
    check_out = (today + timedelta(days=3)).isoformat()

    detail_res = await client.get(
        f"/api/v1/resorts/{resort_id}?check_in={check_in}&check_out={check_out}"
    )
    assert detail_res.status_code == 200
    resort = detail_res.json()["data"]
    assert resort["name"] == "Azure Bay Oceanfront Resort & Sanctuary"
    assert len(resort["room_types"]) == 2
    # Verify associated certified guides
    assert len(resort["associated_guides"]) >= 1
    guide_names = [g["full_name"] for g in resort["associated_guides"]]
    assert "Captain Kai Tanaka" in guide_names
