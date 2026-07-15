from contextlib import asynccontextmanager
from typing import AsyncGenerator

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from app.core.config import settings
from app.core.database import init_db
from app.api.routes import auth, allergens, meals, logs
from app.models import Allergen
from app.core.database import async_session_maker


@asynccontextmanager
async def lifespan(app: FastAPI) -> AsyncGenerator:
    """Application lifespan events."""
    # Startup
    await init_db()
    await seed_allergens()
    yield
    # Shutdown
    pass


async def seed_allergens():
    """Seed default allergens if none exist."""
    async with async_session_maker() as session:
        from sqlalchemy import select
        result = await session.execute(select(Allergen).limit(1))
        if result.scalar_one_or_none():
            return  # Already seeded
        
        default_allergens = [
            Allergen(name="Gluten", trigger_keywords=["gluten", "wheat", "barley", "rye", "bread", "pasta"]),
            Allergen(name="Lactose", trigger_keywords=["lactose", "milk", "dairy", "cheese", "cream", "butter"]),
            Allergen(name="Eggs", trigger_keywords=["egg", "eggs", "mayonnaise"]),
            Allergen(name="Peanuts", trigger_keywords=["peanut", "peanuts", "groundnut"]),
            Allergen(name="Tree Nuts", trigger_keywords=["almond", "walnut", "cashew", "pistachio", "hazelnut"]),
            Allergen(name="Soy", trigger_keywords=["soy", "soybean", "tofu", "edamame"]),
            Allergen(name="Fish", trigger_keywords=["fish", "salmon", "tuna", "cod", "anchovy"]),
            Allergen(name="Shellfish", trigger_keywords=["shrimp", "crab", "lobster", "shellfish", "prawn"]),
            Allergen(name="Sesame", trigger_keywords=["sesame", "tahini"]),
            Allergen(name="Sulfites", trigger_keywords=["sulfite", "sulfites", "wine", "dried fruit"]),
            Allergen(name="FODMAPs", trigger_keywords=["onion", "garlic", "apple", "pear", "honey", "wheat"]),
            Allergen(name="Caffeine", trigger_keywords=["coffee", "caffeine", "tea", "chocolate", "cola"]),
            Allergen(name="Alcohol", trigger_keywords=["alcohol", "beer", "wine", "spirits"]),
            Allergen(name="Spicy Foods", trigger_keywords=["chili", "pepper", "hot sauce", "spicy"]),
        ]
        
        for allergen in default_allergens:
            session.add(allergen)
        
        await session.commit()


# Create FastAPI application
app = FastAPI(
    title=settings.app_name,
    description="Gut Health Tracking API with AI-powered meal analysis",
    version="1.0.0",
    lifespan=lifespan
)

# Configure CORS
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # Configure for production
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Include routers
app.include_router(auth.router, prefix=settings.api_v1_prefix)
app.include_router(allergens.router, prefix=settings.api_v1_prefix)
app.include_router(meals.router, prefix=settings.api_v1_prefix)
app.include_router(logs.router, prefix=settings.api_v1_prefix)


@app.get("/")
async def root():
    """Root endpoint."""
    return {
        "name": settings.app_name,
        "version": "1.0.0",
        "docs": "/docs"
    }


@app.get("/health")
async def health():
    """Health check endpoint."""
    return {"status": "healthy"}
