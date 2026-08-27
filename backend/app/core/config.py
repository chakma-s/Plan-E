from typing import List, Union
from pydantic import AnyHttpUrl, field_validator
from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    PROJECT_NAME: str = "Plan-E Travel Reservation Engine"
    API_V1_STR: str = "/api/v1"
    VERSION: str = "1.0.0"
    ENVIRONMENT: str = "development"

    # Security & Authentication
    SECRET_KEY: str = "super-secret-jwt-key-for-plane-ota-development-change-in-prod"
    ALGORITHM: str = "HS256"
    ACCESS_TOKEN_EXPIRE_MINUTES: int = 60 * 24 * 7  # 7 days

    # Database (Default to local SQLite for instant zero-dependency execution; override via .env for Postgres)
    DATABASE_URL: str = "sqlite+aiosqlite:///./plane.db"
    ASYNC_POOL_SIZE: int = 20
    ASYNC_MAX_OVERFLOW: int = 10

    # Pricing & Business Engine
    PLATFORM_FEE_PERCENTAGE: float = 5.0  # 5% platform service fee
    DEFAULT_TAX_PERCENTAGE: float = 8.5   # 8.5% lodging tax

    # Mapbox Config
    MAPBOX_ACCESS_TOKEN: str = "pk.eyJ1IjoicGxhbmUtdHJhdmVsIiwiYSI6ImNsdGVzdHRva2VuIn0.demo"

    # CORS
    BACKEND_CORS_ORIGINS: List[str] = [
        "http://localhost",
        "http://localhost:3000",
        "http://localhost:8000",
        "http://localhost:8080",
        "http://127.0.0.1",
        "http://127.0.0.1:3000",
        "http://127.0.0.1:8000",
        "http://127.0.0.1:8080",
        "*",
    ]

    model_config = SettingsConfigDict(
        env_file=".env",
        env_file_encoding="utf-8",
        case_sensitive=True,
        extra="allow",
    )


settings = Settings()
