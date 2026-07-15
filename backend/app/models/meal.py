from datetime import datetime
from typing import TYPE_CHECKING, Any, Dict, List, Optional

from sqlalchemy import String, DateTime, ForeignKey, Integer
from sqlalchemy.dialects.postgresql import JSONB
from sqlalchemy.orm import Mapped, mapped_column, relationship
from sqlalchemy.sql import func

from app.core.database import Base

if TYPE_CHECKING:
    from app.models.user import User


class Meal(Base):
    """Meal model storing AI analysis results (no image storage)."""
    
    __tablename__ = "meals"
    
    id: Mapped[int] = mapped_column(primary_key=True, index=True)
    user_id: Mapped[int] = mapped_column(
        Integer,
        ForeignKey("users.id", ondelete="CASCADE"),
        nullable=False,
        index=True
    )
    
    # AI Analysis results (no image stored)
    detected_ingredients: Mapped[List[Dict[str, Any]]] = mapped_column(
        JSONB,
        nullable=False,
        default=list
    )
    detected_allergens: Mapped[List[Dict[str, Any]]] = mapped_column(
        JSONB,
        nullable=False,
        default=list
    )
    risk_level: Mapped[str] = mapped_column(
        String(20),
        nullable=False,
        default="none"  # none, low, medium, high
    )
    
    # Optional meal description
    description: Mapped[Optional[str]] = mapped_column(String(500), nullable=True)
    
    # Timestamps
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        server_default=func.now(),
        nullable=False
    )
    
    # Local sync tracking
    local_id: Mapped[Optional[str]] = mapped_column(String(50), nullable=True, index=True)
    
    # Relationships
    user: Mapped["User"] = relationship("User", back_populates="meals")
    
    def __repr__(self) -> str:
        return f"<Meal(id={self.id}, user_id={self.user_id}, risk_level={self.risk_level})>"
