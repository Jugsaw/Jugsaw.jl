from pydantic import BaseModel
from typing import Any

class CallMsg(BaseModel):
    args:Any
    kwargs:Any
