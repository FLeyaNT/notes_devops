import logging

import uvicorn

from fastapi import status

from app.core.config import settings
from app.create_app import create_app
from app.api.router import api_router


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
    '/health',
    status_code=status.HTTP_200_OK
)
async def health():
    try:
        return {
            'health': 'OK'
        }
    except Exception:
        return {
            'health': 'unhealthy'
        }


if __name__ == '__main__':
    uvicorn.run(
        app='app.main:app',
        host=settings.run.host,
        port=settings.run.port,
        reload=settings.debug,
        reload_dirs=['app']
    )
