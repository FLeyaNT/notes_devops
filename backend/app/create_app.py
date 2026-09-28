from contextlib import asynccontextmanager
from typing import AsyncGenerator

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from app.core.config import settings
from app.database.config import async_engine


@asynccontextmanager
async def lifespan(app: FastAPI) -> AsyncGenerator[None, None]:
    yield

    await async_engine.dispose()


def add_cors_middleware(app: FastAPI) -> None:
    app.add_middleware(
        CORSMiddleware,
        allow_origins=settings.fastapi.origins,
        allow_credentials=True,
        allow_methods=['*'],
        allow_headers=['*'],
    )


def create_app() -> FastAPI:
    app = FastAPI(
        title=settings.fastapi.title,
        lifespan=lifespan,
        debug=settings.debug
    )

    add_cors_middleware(app)

    return app
