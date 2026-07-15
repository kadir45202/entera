from typing import List

from fastapi import APIRouter, HTTPException, status
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.api.deps import DBSession, CurrentUser
from app.models.allergen import Allergen
from app.models.user import User
from app.schemas.allergen import AllergenResponse, UserAllergenUpdate


router = APIRouter(prefix="/allergens", tags=["Allergens"])


@router.get("", response_model=List[AllergenResponse])
async def list_allergens(db: DBSession):
    """List all available allergens (no auth required)."""
    result = await db.execute(select(Allergen).order_by(Allergen.name))
    allergens = result.scalars().all()
    return allergens


@router.get("/me", response_model=List[AllergenResponse])
async def get_user_allergens(current_user: CurrentUser):
    """Get current user's allergen selections."""
    return current_user.allergens


@router.post("/me", response_model=List[AllergenResponse])
async def set_user_allergens(
    allergen_data: UserAllergenUpdate,
    current_user: CurrentUser,
    db: DBSession
):
    """Set current user's allergen selections (replaces existing)."""
    # Fetch selected allergens
    result = await db.execute(
        select(Allergen).where(Allergen.id.in_(allergen_data.allergen_ids))
    )
    selected_allergens = result.scalars().all()
    
    # Validate all IDs exist
    if len(selected_allergens) != len(allergen_data.allergen_ids):
        found_ids = {a.id for a in selected_allergens}
        missing_ids = set(allergen_data.allergen_ids) - found_ids
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Invalid allergen IDs: {missing_ids}"
        )
    
    # Update user's allergens
    current_user.allergens = list(selected_allergens)
    await db.flush()
    await db.refresh(current_user)
    
    return current_user.allergens
