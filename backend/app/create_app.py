import asyncio
import logging
from contextlib import asynccontextmanager
from typing import AsyncGenerator

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from sqlalchemy import text

from app.core.config import settings
from app.database.config import async_engine


logger = logging.getLogger(__name__)


@asynccontextmanager
async def lifespan(app: FastAPI) -> AsyncGenerator[None, None]:
    try:
        async with asyncio.timeout(2):
            async with async_engine.connect() as conn:
                await conn.execute(text('SELECT 1'))
    except Exception as e:
        logger.warning('DB health check failed: %s', e)

    yield

    logger.info('SIGTERM received, shutting down gracefully...')
    await async_engine.dispose()
    logger.info('DB connections closed, server stopped')


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
