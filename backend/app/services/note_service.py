from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.exceptions import NotFoundException
from app.schemas.note import (
    NoteCreate
)
from app.models.note import Note


class NoteService:

    def __init__(
        self,
        session: AsyncSession,
    ) -> None:
        self._session = session

    async def create(
        self,
        obj: NoteCreate
    ) -> Note:
        new_note = Note(**obj.model_dump())

        self._session.add(new_note)
        await self._session.commit()
        await self._session.refresh(new_note)

        return new_note

    async def get_by_id(
        self,
        note_id: int
    ) -> Note:
        return await self._get_by_id(note_id)

    async def get_all(self) -> list[Note]:
        stmt = (
            select(Note)
            .order_by(Note.id)
        )
        result = await self._session.execute(stmt)
        return list(result.scalars().all())

    async def delete(
        self,
        note_id: int
    ) -> None:
        note = self._get_by_id(note_id)

        await self._session.delete(note)
        await self._session.commit()

    async def _get_by_id(
        self,
        note_id: int
    ) -> Note:
        stmt = (
            select(Note)
            .where(Note.id == note_id)
        )
        result = await self._session.execute(stmt)
        note = result.scalar_one_or_none()

        if not note:
            raise NotFoundException

        return note
