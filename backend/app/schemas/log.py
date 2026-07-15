from datetime import datetime
from typing import List, Optional
from enum import Enum

from pydantic import BaseModel, Field


class LogType(str, Enum):
    """Types of health logs."""
    STOOL = "stool"
    SYMPTOM = "symptom"


class LogBase(BaseModel):
    """Base log schema."""
    type: LogType
    value: int = Field(..., ge=1, le=10)  # Bristol 1-7 or severity 1-10
    tags: Optional[List[str]] = []
    notes: Optional[str] = None


class LogCreate(LogBase):
    """Schema for creating a log."""
    local_id: Optional[str] = None  # For sync tracking


class LogResponse(LogBase):
    """Schema for log response."""
    id: int
    created_at: datetime
    local_id: Optional[str]
    
    class Config:
        from_attributes = True


class StoolLogCreate(BaseModel):
    """Convenience schema for stool logging."""
    bristol_type: int = Field(..., ge=1, le=7, description="Bristol Stool Scale 1-7")
    tags: Optional[List[str]] = []  # blood, mucus, etc.
    notes: Optional[str] = None
    local_id: Optional[str] = None


class SymptomLogCreate(BaseModel):
    """Convenience schema for symptom logging."""
    symptom_type: str = Field(..., description="bloating, pain, nausea, etc.")
    severity: int = Field(..., ge=1, le=10, description="Severity 1-10")
    notes: Optional[str] = None
    local_id: Optional[str] = None


class LogSyncRequest(BaseModel):
    """Request for syncing local logs to backend."""
    logs: List[LogCreate]


class CorrelationResult(BaseModel):
    """Result from meal-symptom correlation analysis."""
    symptom_log_id: int
    symptom_type: str
    symptom_time: datetime
    related_meals: List["CorrelationMeal"]


class CorrelationMeal(BaseModel):
    """Meal correlated with a symptom."""
    meal_id: int
    meal_time: datetime
    time_delta_hours: float
    detected_allergens: List[str]
    risk_level: str


CorrelationResult.model_rebuild()
