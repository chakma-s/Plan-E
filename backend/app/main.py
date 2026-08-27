import os
from pathlib import Path
from contextlib import asynccontextmanager
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import FileResponse
from fastapi.staticfiles import StaticFiles
from sqlalchemy import select, func

from app.core.config import settings
from app.core.database import engine, AsyncSessionLocal
from app.models.base import Base
from app.models.property import Property
from app.seed_data import init_db
from app.seed_500_users import seed_500_user_ecosystem
from app.api.v1.api import api_router

# Path to Web Portal static UI assets
BASE_DIR = Path(__file__).resolve().parent.parent.parent
PORTAL_DIR = BASE_DIR / "web_portal"


@asynccontextmanager
async def lifespan(app: FastAPI):
    """
    Application startup lifecycle:
    Automatically ensures database tables are created and sample data is seeded.
    """
    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.create_all)

    async with AsyncSessionLocal() as session:
        # Check if database is already populated
        res = await session.execute(select(func.count(Property.id)))
        count = res.scalar() or 0
        if count == 0:
            print("📦 Initializing database with seed data & 500-user ecosystem...")
            await init_db(session)
            await seed_500_user_ecosystem(session)
            print("✅ Database successfully seeded and ready!")

    yield


app = FastAPI(
    title=settings.PROJECT_NAME,
    version=settings.VERSION,
    openapi_url=f"{settings.API_V1_STR}/openapi.json",
    docs_url=f"{settings.API_V1_STR}/docs",
    redoc_url=f"{settings.API_V1_STR}/redoc",
    lifespan=lifespan,
    description="""
    ## High-Performance OTA Travel Ecosystem Backend
    
    ### Architecture Highlights:
    * **Dual-Path User Journey:** Strict UI/UX and query pipeline separation between **Hotels** (Fast, transactional short stays) and **Resorts** (Immersive vacation planning).
    * **Local Guide Bundling:** First-class feature for Resort bookings to bundle certified local tour guides with identity, rates, languages, and calendar exclusivity.
    * **Vendor Allocation Model:** Fixed room allocations with atomic row-level concurrency locking (`SELECT FOR UPDATE`) to prevent overbooking with zero external dependency latency.
    * **Mapbox Spatial Indexing:** Optimized bounding-box queries for interactive vector map rendering.
    """,
)

# CORS Configuration (Allows any origin for local dev/preview)
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Include API Router
app.include_router(api_router, prefix=settings.API_V1_STR)

# Mount Static UI Assets
if PORTAL_DIR.exists():
    app.mount("/static", StaticFiles(directory=str(PORTAL_DIR)), name="static")


# -----------------------------------------------------------------------------
# Direct Browser UI Routes (Zero-Config Immediate Preview)
# -----------------------------------------------------------------------------
@app.get("/", tags=["Web Interfaces"])
async def root_launchpad():
    """Master Ecosystem Hub & Launchpad."""
    index_path = PORTAL_DIR / "index.html"
    if index_path.exists():
        return FileResponse(str(index_path))
    return {"service": settings.PROJECT_NAME, "version": settings.VERSION, "docs": f"{settings.API_V1_STR}/docs"}


@app.get("/consumer", tags=["Web Interfaces"])
async def traveler_app():
    """Traveler Experience Web App Simulator (Hotels, Resorts & Guide Bundles)."""
    p = PORTAL_DIR / "consumer" / "index.html"
    return FileResponse(str(p))


@app.get("/vendor", tags=["Web Interfaces"])
async def vendor_portal():
    """Vendor Management Portal (Allocation Matrix & Guide Roster)."""
    p = PORTAL_DIR / "vendor" / "index.html"
    return FileResponse(str(p))


@app.get("/admin", tags=["Web Interfaces"])
async def admin_dashboard():
    """Internal Admin Operations Dashboard (Telemetry & Guide Vetting)."""
    p = PORTAL_DIR / "admin" / "index.html"
    return FileResponse(str(p))


@app.get("/health", tags=["Health & Status"])
async def health_check():
    return {"status": "healthy", "environment": settings.ENVIRONMENT}
