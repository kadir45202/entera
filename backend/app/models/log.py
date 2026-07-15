from datetime import datetime
from enum import Enum
from typing import TYPE_CHECKING, Any, Dict, List, Optional

from sqlalchemy import String, DateTime, ForeignKey, Integer
from sqlalchemy.dialects.postgresql import JSONB
from sqlalchemy.orm import Mapped, mapped_column, relationship
from sqlalchemy.sql import func

from app.core.database import Base

if TYPE_CHECKING:
    from app.models.user import User


class LogType(str, Enum):
    """Types of health logs."""
    STOOL = "stool"
    SYMPTOM = "symptom"


class Log(Base):
    """Health log model for stool (Bristol scale) and symptoms."""
    
    __tablename__ = "logs"
    
    id: Mapped[int] = mapped_column(primary_key=True, index=True)
    user_id: Mapped[int] = mapped_column(
        Integer,
        ForeignKey("users.id", ondelete="CASCADE"),
        nullable=False,
        index=True
    )
    
    # Log type and value
    type: Mapped[str] = mapped_column(String(20), nullable=False)  # stool, symptom
    value: Mapped[int] = mapped_column(Integer, nullable=False)  # Bristol 1-7 or severity 1-10
    
    # Additional tags (blood, mucus for stool; bloating, pain for symptoms)
    tags: Mapped[Optional[List[str]]] = mapped_column(JSONB, nullable=True, default=list)
    
    # Optional notes
    notes: Mapped[Optional[str]] = mapped_column(String(500), nullable=True)
    
    # Timestamps
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        server_default=func.now(),
        nullable=False
    )
    
    # Local sync tracking
    local_id: Mapped[Optional[str]] = mapped_column(String(50), nullable=True, index=True)
    
    # Relationships
    user: Mapped["User"] = relationship("User", back_populates="logs")
    
    def __repr__(self) -> str:
        return f"<Log(id={self.id}, type={self.type}, value={self.value})>"
