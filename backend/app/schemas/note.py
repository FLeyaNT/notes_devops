from pydantic import (
    BaseModel,
    ConfigDict,
    Field
)


class NoteCreate(BaseModel):
    title: str = Field(
        ...,
        min_length=1,
        max_length=50
    )
    body: str


class NoteResponse(BaseModel):
    id: int
    title: str
    body: str

    model_config = ConfigDict(from_attributes=True)
