from pydantic import BaseModel, Field
from typing import Any

class CallMsg(BaseModel):
    sig: str = Field(..., alias="type")
    fields : list
    values : Any
