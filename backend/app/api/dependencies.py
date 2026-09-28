from fastapi import Depends

from sqlalchemy.ext.asyncio import (
    AsyncSession,
)

from typing import (
    Annotated,
    AsyncGenerator,
)

from app.database.config import AsyncSessionLocal
from app.services.note_service import NoteService


async def get_session() -> AsyncGenerator[AsyncSession, None]:
    async with AsyncSessionLocal() as session:
        yield session

SessionDep = Annotated[
    AsyncSession,
    Depends(get_session)
]


def get_note_service(
    session: SessionDep
) -> NoteService:
    return NoteService(
        session=session
    )

NoteServiceDep = Annotated[
    NoteService,
    Depends(get_note_service)
]
