from sqlalchemy.orm import (
    Mapped,
    mapped_column
)
from sqlalchemy import (
    String,
    Text
)

from app.models.base import Base


class Note(Base):
    __tablename__ = 'notes'

    title: Mapped[str] = mapped_column(
        String(50),
        nullable=False,
    )
    body: Mapped[str] = mapped_column(
        Text,
        nullable=False,
    )
