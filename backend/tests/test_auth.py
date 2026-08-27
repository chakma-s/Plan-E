import pytest
from httpx import AsyncClient


@pytest.mark.asyncio
async def test_register_and_login(client: AsyncClient):
    # 1. Register
    reg_payload = {
        "email": "new.traveler@example.com",
        "password": "Password123!",
        "full_name": "Jordan Smith",
        "phone_number": "+1-555-9988",
        "role": "CUSTOMER",
    }
    res = await client.post("/api/v1/auth/register", json=reg_payload)
    assert res.status_code == 201
    data = res.json()
    assert data["success"] is True
    assert data["data"]["email"] == "new.traveler@example.com"

    # 2. Login
    login_payload = {
        "email": "new.traveler@example.com",
        "password": "Password123!",
    }
    login_res = await client.post("/api/v1/auth/login", json=login_payload)
    assert login_res.status_code == 200
    login_data = login_res.json()["data"]
    token = login_data["access_token"]
    assert token is not None

    # 3. Protected /me
    headers = {"Authorization": f"Bearer {token}"}
    me_res = await client.get("/api/v1/auth/me", headers=headers)
    assert me_res.status_code == 200
    me_data = me_res.json()["data"]
    assert me_data["full_name"] == "Jordan Smith"
