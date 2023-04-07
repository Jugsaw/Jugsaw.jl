from pydantic import BaseModel, Field
from typing import Any

class ArgsMsg(BaseModel):
    data: Any

class CallMsg(BaseModel):
    sig: str = Field(..., alias="__type__")
    fname: str
    args:ArgsMsg
    kwargs:Any
