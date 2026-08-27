from fastapi import APIRouter
from app.api.v1.endpoints import (
    auth,
    hotels,
    resorts,
    guides,
    bookings,
    vendor,
    admin,
    reviews,
)

api_router = APIRouter()

api_router.include_router(auth.router, prefix="/auth", tags=["Authentication & Profiles"])
api_router.include_router(hotels.router, prefix="/hotels", tags=["Hotels Pipeline (Transactional)"])
api_router.include_router(resorts.router, prefix="/resorts", tags=["Resorts Pipeline (Immersive + Guides)"])
api_router.include_router(guides.router, prefix="/guides", tags=["Local Guides"])
api_router.include_router(bookings.router, prefix="/bookings", tags=["Bookings & Allocation Engine"])
api_router.include_router(vendor.router, prefix="/vendor", tags=["Vendor Portal"])
api_router.include_router(admin.router, prefix="/admin", tags=["Internal Admin"])

api_router.include_router(reviews.router, prefix="/reviews", tags=["Reviews"])