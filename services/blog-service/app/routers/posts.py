"""
Blog post endpoints.

Public router   — /api/posts/*     — accessible by the frontend with a user token
Internal router — /internal/posts  — callable only with a service token
"""

from fastapi import APIRouter, Depends, Header, HTTPException
from pydantic import BaseModel
from typing import Optional
from datetime import datetime
from app.auth import get_user_token, require_service_token

router = APIRouter()
internal_router = APIRouter()

# In-memory store for this guide. Replace with SQLAlchemy + PostgreSQL in production.
_posts: list[dict] = [
    {
        "id": "1",
        "title": "Getting Started with Keycloak",
        "content": "Keycloak makes authentication easy...",
        "author_id": "demo-user",
        "author_name": "Demo User",
        "created_at": datetime.utcnow().isoformat(),
        "published": True,
    }
]


class PostCreate(BaseModel):
    title: str
    content: str
    published: bool = False


class PostResponse(BaseModel):
    id: str
    title: str
    content: str
    author_id: str
    author_name: str
    created_at: str
    published: bool


# ─── Public endpoints (user token required) ───────────────────────────────────

@router.get("", response_model=list[PostResponse])
async def list_posts(_: dict = Depends(get_user_token)):
    """Return all published posts."""
    return [p for p in _posts if p["published"]]


@router.post("", response_model=PostResponse, status_code=201)
async def create_post(
    body: PostCreate,
    user: dict = Depends(get_user_token),
):
    """Create a new blog post. Author taken from the JWT claims."""
    new_post = {
        "id": str(len(_posts) + 1),
        "title": body.title,
        "content": body.content,
        "author_id": user["sub"],
        "author_name": user.get("preferred_username", "Anonymous"),
        "created_at": datetime.utcnow().isoformat(),
        "published": body.published,
    }
    _posts.append(new_post)
    return new_post


# ─── Internal endpoints (service token required) ───────────────────────────────

@internal_router.get("")
async def get_user_posts(
    _: dict = Depends(require_service_token),
    x_user_id: str = Header(..., alias="X-User-Id"),
):
    """
    Called by the Auth Service to fetch a specific user's posts.
    Protected by service-to-service token (not a user token).
    The X-User-Id header tells us whose posts to return.
    """
    return [p for p in _posts if p["author_id"] == x_user_id]