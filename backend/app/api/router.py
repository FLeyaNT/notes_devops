from fastapi import APIRouter

from app.api.endpoints import notes


api_router = APIRouter(
    prefix='/api'
)

api_router.include_router(notes.router)
