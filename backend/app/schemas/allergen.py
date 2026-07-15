from typing import List

from pydantic import BaseModel


class AllergenBase(BaseModel):
    """Base allergen schema."""
    name: str
    trigger_keywords: List[str] = []


class AllergenCreate(AllergenBase):
    """Schema for creating allergen."""
    pass


class AllergenResponse(AllergenBase):
    """Schema for allergen response."""
    id: int
    
    class Config:
        from_attributes = True


class UserAllergenUpdate(BaseModel):
    """Schema for updating user's allergen selections."""
    allergen_ids: List[int]
