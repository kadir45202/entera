from typing import List, Optional

from fastapi import APIRouter, HTTPException, status, Query
from sqlalchemy import select, desc
from sqlalchemy.ext.asyncio import AsyncSession

from app.api.deps import DBSession, CurrentUser, OptionalUser
from app.models.meal import Meal
from app.schemas.meal import (
    MealAnalyzeRequest, MealAnalyzeResponse,
    MealCreate, MealResponse, MealSyncRequest
)
from app.services.gemini_service import analyze_meal_image
from app.services.meal_service import check_user_allergens


router = APIRouter(prefix="/meals", tags=["Meals"])


@router.post("/analyze", response_model=MealAnalyzeResponse)
async def analyze_meal(
    request: MealAnalyzeRequest,
    db: DBSession,
    current_user: OptionalUser = None
):
    """
    Analyze meal image with AI.
    
    - Works without auth (guest mode) - just returns analysis
    - With auth - also checks against user's allergen profile
    """
    # Call Gemini to analyze image
    analysis = await analyze_meal_image(request.image_base64)
    
    # If user is authenticated, check against their allergen profile
    user_warnings = []
    if current_user:
        user_warnings = await check_user_allergens(
            detected_allergens=analysis.detected_allergens,
            user_allergens=current_user.allergens
        )
    
    return MealAnalyzeResponse(
        detected_ingredients=analysis.detected_ingredients,
        detected_allergens=analysis.detected_allergens,
        risk_level=analysis.risk_level,
        user_allergen_warnings=user_warnings
    )


@router.post("/sync", response_model=List[MealResponse])
async def sync_meals(
    request: MealSyncRequest,
    current_user: CurrentUser,
    db: DBSession
):
    """Sync locally stored meals to backend after authentication."""
    synced_meals = []
    
    for meal_data in request.meals:
        # Check for duplicate by local_id
        if meal_data.local_id:
            existing = await db.execute(
                select(Meal).where(
                    Meal.user_id == current_user.id,
                    Meal.local_id == meal_data.local_id
                )
            )
            if existing.scalar_one_or_none():
                continue  # Skip duplicate
        
        meal = Meal(
            user_id=current_user.id,
            detected_ingredients=meal_data.detected_ingredients,
            detected_allergens=meal_data.detected_allergens,
            risk_level=meal_data.risk_level,
            description=meal_data.description,
            local_id=meal_data.local_id
        )
        db.add(meal)
        synced_meals.append(meal)
    
    await db.flush()
    for meal in synced_meals:
        await db.refresh(meal)
    
    return synced_meals


@router.get("", response_model=List[MealResponse])
async def list_meals(
    current_user: CurrentUser,
    db: DBSession,
    limit: int = Query(default=50, le=100),
    offset: int = Query(default=0, ge=0)
):
    """List user's meal history."""
    result = await db.execute(
        select(Meal)
        .where(Meal.user_id == current_user.id)
        .order_by(desc(Meal.created_at))
        .limit(limit)
        .offset(offset)
    )
    return result.scalars().all()


@router.get("/{meal_id}", response_model=MealResponse)
async def get_meal(
    meal_id: int,
    current_user: CurrentUser,
    db: DBSession
):
    """Get a specific meal by ID."""
    result = await db.execute(
        select(Meal).where(
            Meal.id == meal_id,
            Meal.user_id == current_user.id
        )
    )
    meal = result.scalar_one_or_none()
    
    if not meal:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Meal not found"
        )
    
    return meal
