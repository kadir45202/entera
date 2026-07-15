from datetime import datetime, timedelta
from typing import List, Optional

from fastapi import APIRouter, HTTPException, status, Query
from sqlalchemy import select, desc, and_
from sqlalchemy.ext.asyncio import AsyncSession

from app.api.deps import DBSession, CurrentUser
from app.models.log import Log
from app.models.meal import Meal
from app.schemas.log import (
    LogResponse, StoolLogCreate, SymptomLogCreate,
    LogSyncRequest, LogCreate, CorrelationResult, CorrelationMeal
)


router = APIRouter(prefix="/logs", tags=["Health Logs"])


@router.post("/stool", response_model=LogResponse, status_code=status.HTTP_201_CREATED)
async def log_stool(
    log_data: StoolLogCreate,
    current_user: CurrentUser,
    db: DBSession
):
    """Log a Bristol scale stool entry (1-7)."""
    log = Log(
        user_id=current_user.id,
        type="stool",
        value=log_data.bristol_type,
        tags=log_data.tags,
        notes=log_data.notes,
        local_id=log_data.local_id
    )
    db.add(log)
    await db.flush()
    await db.refresh(log)
    
    return log


@router.post("/symptom", response_model=LogResponse, status_code=status.HTTP_201_CREATED)
async def log_symptom(
    log_data: SymptomLogCreate,
    current_user: CurrentUser,
    db: DBSession
):
    """Log a symptom with severity (1-10)."""
    log = Log(
        user_id=current_user.id,
        type="symptom",
        value=log_data.severity,
        tags=[log_data.symptom_type],
        notes=log_data.notes,
        local_id=log_data.local_id
    )
    db.add(log)
    await db.flush()
    await db.refresh(log)
    
    return log


@router.post("/sync", response_model=List[LogResponse])
async def sync_logs(
    request: LogSyncRequest,
    current_user: CurrentUser,
    db: DBSession
):
    """Sync locally stored logs to backend after authentication."""
    synced_logs = []
    
    for log_data in request.logs:
        # Check for duplicate by local_id
        if log_data.local_id:
            existing = await db.execute(
                select(Log).where(
                    Log.user_id == current_user.id,
                    Log.local_id == log_data.local_id
                )
            )
            if existing.scalar_one_or_none():
                continue  # Skip duplicate
        
        log = Log(
            user_id=current_user.id,
            type=log_data.type.value,
            value=log_data.value,
            tags=log_data.tags,
            notes=log_data.notes,
            local_id=log_data.local_id
        )
        db.add(log)
        synced_logs.append(log)
    
    await db.flush()
    for log in synced_logs:
        await db.refresh(log)
    
    return synced_logs


@router.get("", response_model=List[LogResponse])
async def list_logs(
    current_user: CurrentUser,
    db: DBSession,
    log_type: Optional[str] = Query(default=None, description="Filter by type: stool or symptom"),
    limit: int = Query(default=50, le=100),
    offset: int = Query(default=0, ge=0)
):
    """List user's health logs with optional type filter."""
    query = select(Log).where(Log.user_id == current_user.id)
    
    if log_type:
        query = query.where(Log.type == log_type)
    
    query = query.order_by(desc(Log.created_at)).limit(limit).offset(offset)
    
    result = await db.execute(query)
    return result.scalars().all()


@router.get("/correlations", response_model=List[CorrelationResult])
async def get_correlations(
    current_user: CurrentUser,
    db: DBSession,
    hours_window: int = Query(default=4, ge=1, le=24, description="Hours to look back for meals")
):
    """
    Analyze correlations between symptoms and meals.
    
    Finds meals eaten within the specified hours before each symptom.
    """
    # Get recent symptom logs
    symptoms_result = await db.execute(
        select(Log)
        .where(Log.user_id == current_user.id, Log.type == "symptom")
        .order_by(desc(Log.created_at))
        .limit(20)
    )
    symptom_logs = symptoms_result.scalars().all()
    
    correlations = []
    
    for symptom in symptom_logs:
        # Find meals within window before this symptom
        window_start = symptom.created_at - timedelta(hours=hours_window)
        
        meals_result = await db.execute(
            select(Meal)
            .where(
                Meal.user_id == current_user.id,
                Meal.created_at >= window_start,
                Meal.created_at <= symptom.created_at
            )
            .order_by(desc(Meal.created_at))
        )
        related_meals = meals_result.scalars().all()
        
        if related_meals:
            correlation = CorrelationResult(
                symptom_log_id=symptom.id,
                symptom_type=symptom.tags[0] if symptom.tags else "unknown",
                symptom_time=symptom.created_at,
                related_meals=[
                    CorrelationMeal(
                        meal_id=meal.id,
                        meal_time=meal.created_at,
                        time_delta_hours=round(
                            (symptom.created_at - meal.created_at).total_seconds() / 3600, 1
                        ),
                        detected_allergens=[a.get("name", "") for a in meal.detected_allergens],
                        risk_level=meal.risk_level
                    )
                    for meal in related_meals
                ]
            )
            correlations.append(correlation)
    
    return correlations
