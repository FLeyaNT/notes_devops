import asyncio
import logging
from venv import logger

import uvicorn

from fastapi import status

from sqlalchemy import text
from starlette.responses import JSONResponse

from app.core.config import settings
from app.create_app import create_app
from app.api.router import api_router
from app.database.config import async_engine


logging.basicConfig(
    level=(
        logging.DEBUG if settings.debug
        else settings.logging.log_level_value
    ),
    format=settings.logging.log_format
)

app = create_app()

app.include_router(api_router)


@app.get(
    '/api/health',
    status_code=status.HTTP_200_OK
)
async def health():
    db_ok = False
    try:
        async with asyncio.timeout(2):
            async with async_engine.connect() as conn:
                await conn.execute(text('SELECT 1'))
        db_ok = True
    except Exception as e:
        logger.warning('DB health check failed: %s', e)

    return JSONResponse(
        status_code=status.HTTP_200_OK if db_ok else status.HTTP_503_SERVICE_UNAVAILABLE,
        content={
            'status': 'ok' if db_ok else 'degraded',
            'db': db_ok
        }
    )


@app.get('/api/eat')
async def eat():
    data = b'x' * 200_000_000
    return {'allocated': len(data)}


if __name__ == '__main__':
    uvicorn.run(
        app='app.main:app',
        host=settings.run.host,
        port=settings.run.port,
        reload=settings.debug,
        reload_dirs=['app']
    )
