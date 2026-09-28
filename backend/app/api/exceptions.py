from fastapi import HTTPException, status


class APIException(HTTPException):
    pass


class APINotFoundException(APIException):

    def __init__(
        self,
        detail: str
    ) -> None:
        super().__init__(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=detail
        )
