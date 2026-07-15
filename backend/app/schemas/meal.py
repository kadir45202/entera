from datetime import datetime
from typing import Any, Dict, List, Optional

from pydantic import BaseModel, Field


class MealIngredient(BaseModel):
    """Detected ingredient from AI analysis."""
    name: str
    confidence: float = Field(ge=0, le=1)


class MealAllergen(BaseModel):
    """Detected allergen from AI analysis."""
    name: str
    trigger_ingredient: str
    confidence: float = Field(ge=0, le=1)


class MealAnalyzeRequest(BaseModel):
    """Request schema for meal image analysis (base64 encoded)."""
    image_base64: str
    description: Optional[str] = None


class MealAnalyzeResponse(BaseModel):
    """Response from AI meal analysis."""
    detected_ingredients: List[MealIngredient]
    detected_allergens: List[MealAllergen]
    risk_level: str  # none, low, medium, high
    user_allergen_warnings: List[str] = []  # Allergens matching user's profile


class MealCreate(BaseModel):
    """Schema for creating a meal record."""
    detected_ingredients: List[Dict[str, Any]]
    detected_allergens: List[Dict[str, Any]]
    risk_level: str = "none"
    description: Optional[str] = None
    local_id: Optional[str] = None  # For sync tracking


class MealResponse(BaseModel):
    """Schema for meal response."""
    id: int
    detected_ingredients: List[Dict[str, Any]]
    detected_allergens: List[Dict[str, Any]]
    risk_level: str
    description: Optional[str]
    created_at: datetime
    local_id: Optional[str]
    
    class Config:
        from_attributes = True


class MealSyncRequest(BaseModel):
    """Request for syncing local meals to backend."""
    meals: List[MealCreate]
