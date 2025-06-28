from fastapi import APIRouter, Depends
from .auth import get_current_user

router = APIRouter()

@router.get("/protected")
async def protected_route(user: str = Depends(get_current_user)):
    return {"message": f"Hello {user}"}
