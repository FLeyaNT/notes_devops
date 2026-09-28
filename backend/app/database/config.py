from sqlalchemy.ext.asyncio import (
    create_async_engine,
    AsyncSession,
    async_sessionmaker
)

from app.core.config import settings


async_engine = create_async_engine(
    url=settings.postgres.async_database_url,
    pool_size=20,
    max_overflow=10,
    pool_pre_ping=True
)


AsyncSessionLocal = async_sessionmaker(
    bind=async_engine,
    class_=AsyncSession,
    expire_on_commit=False,
    autocommit=False,
    autoflush=False
)
