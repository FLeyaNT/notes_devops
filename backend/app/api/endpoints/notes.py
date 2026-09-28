from fastapi import (
    APIRouter,
    status,
)

from app.schemas.note import (
    NoteCreate,
    NoteResponse,
)
from ..dependencies import (
    NoteServiceDep
)
from ...core.exceptions import NotFoundException
from ..exceptions import APINotFoundException

router = APIRouter(
    prefix='/notes',
    tags=['Notes']
)


@router.post(
    '/',
    response_model=NoteResponse,
    status_code=status.HTTP_201_CREATED,
)
async def create_note(
    note: NoteCreate,
    note_service: NoteServiceDep
):
    return await note_service.create(note)


@router.get(
    '/',
    response_model=list[NoteResponse],
    status_code=status.HTTP_200_OK
)
async def get_all_notes(
    note_service: NoteServiceDep
):
    return await note_service.get_all()


@router.delete(
    '/{note_id}',
    status_code=status.HTTP_204_NO_CONTENT
)
async def delete_note(
    note_id: int,
    note_service: NoteServiceDep
):
    try:
        await note_service.delete(note_id)
    except NotFoundException:
        raise APINotFoundException(
            detail='Заметка не найдена'
        )


@router.get(
    '/{note_id}',
    response_model=NoteResponse,
    status_code=status.HTTP_200_OK
)
async def get_note(
    note_id: int,
    note_service: NoteServiceDep
):
    try:
        return await note_service.get_by_id(note_id)
    except NotFoundException:
        raise APINotFoundException(
            detail='Заметка не найдена'
        )
