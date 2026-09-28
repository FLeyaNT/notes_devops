import logging
from pathlib import Path
from typing import Literal

from pydantic import BaseModel

from pydantic_settings import (
    BaseSettings,
    SettingsConfigDict
)

from .constants import LOG_DEFAULT_FORMAT

BASE_DIR = Path(__file__).resolve().parent.parent.parent


class LoggingConfig(BaseModel):
    log_level: Literal[
        'debug',
        'info',
        'warning',
        'error',
        'critical',
    ] = 'info'
    log_format: str = LOG_DEFAULT_FORMAT

    @property
    def log_level_value(self) -> int:
        return logging.getLevelNamesMapping()[
            self.log_level.upper()
        ]


class RunConfig(BaseModel):
    host: str = '0.0.0.0'
    port: int = 8000


class FastApiConfig(BaseModel):
    title: str = 'Notes API'
    origins: list[str] = [
        "http://localhost:5173",
    ]


class PostgresConfig(BaseModel):
    host: str = 'notes-db'
    port: int = 5432
    db_name: str = 'notes_db'
    user: str
    password: str

    @property
    def async_database_url(self) -> str:
        return (
            f'postgresql+asyncpg://'
            f'{self.user}:{self.password}@{self.host}:'
            f'{self.port}/{self.db_name}'
        )

    @property
    def database_url(self) -> str:
        return (
            f'postgresql://'
            f'{self.user}:{self.password}@{self.host}:'
            f'{self.port}/{self.db_name}'
        )


class Settings(BaseSettings):
    model_config = SettingsConfigDict(
        case_sensitive=False,
        env_nested_delimiter='__'
    )

    debug: bool = True

    run: RunConfig = RunConfig()
    fastapi: FastApiConfig = FastApiConfig()
    logging: LoggingConfig = LoggingConfig()
    postgres: PostgresConfig


settings = Settings()
