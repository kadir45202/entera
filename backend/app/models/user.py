from datetime import datetime
from typing import TYPE_CHECKING, List

from sqlalchemy import String, DateTime
from sqlalchemy.orm import Mapped, mapped_column, relationship
from sqlalchemy.sql import func

from app.core.database import Base

if TYPE_CHECKING:
    from app.models.allergen import Allergen
    from app.models.meal import Meal
    from app.models.log import Log


class User(Base):
    """User model for authentication and data ownership."""
    
    __tablename__ = "users"
    
    id: Mapped[int] = mapped_column(primary_key=True, index=True)
    email: Mapped[str] = mapped_column(String(255), unique=True, index=True, nullable=False)
    password_hash: Mapped[str] = mapped_column(String(255), nullable=False)
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        server_default=func.now(),
        nullable=False
    )
    
    # Relationships
    allergens: Mapped[List["Allergen"]] = relationship(
        "Allergen",
        secondary="user_allergens",
        back_populates="users",
        lazy="selectin"
    )
    meals: Mapped[List["Meal"]] = relationship(
        "Meal",
        back_populates="user",
        lazy="selectin"
    )
    logs: Mapped[List["Log"]] = relationship(
        "Log",
        back_populates="user",
        lazy="selectin"
    )
    
    def __repr__(self) -> str:
        return f"<User(id={self.id}, email={self.email})>"
