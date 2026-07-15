from typing import TYPE_CHECKING, List

from sqlalchemy import String, ForeignKey, Table, Column, Integer, ARRAY
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.core.database import Base

if TYPE_CHECKING:
    from app.models.user import User


# Many-to-many association table
user_allergens = Table(
    "user_allergens",
    Base.metadata,
    Column("user_id", Integer, ForeignKey("users.id", ondelete="CASCADE"), primary_key=True),
    Column("allergen_id", Integer, ForeignKey("allergens.id", ondelete="CASCADE"), primary_key=True),
)


class Allergen(Base):
    """Allergen model with trigger keywords for AI detection."""
    
    __tablename__ = "allergens"
    
    id: Mapped[int] = mapped_column(primary_key=True, index=True)
    name: Mapped[str] = mapped_column(String(100), unique=True, nullable=False)
    trigger_keywords: Mapped[List[str]] = mapped_column(
        ARRAY(String),
        nullable=False,
        default=list
    )
    
    # Relationships
    users: Mapped[List["User"]] = relationship(
        "User",
        secondary=user_allergens,
        back_populates="allergens",
        lazy="selectin"
    )
    
    def __repr__(self) -> str:
        return f"<Allergen(id={self.id}, name={self.name})>"
