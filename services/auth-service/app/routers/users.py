"""
User-facing endpoints.
The Auth Service also demonstrates calling another service (Blog Service)
on behalf of the logged-in user.
"""

import os
import httpx
from fastapi import APIRouter, Depends, HTTPException
from app.auth import get_current_user, TokenData

router = APIRouter()

BLOG_SERVICE_URL = os.getenv("BLOG_SERVICE_URL", "http://blog-service:8002")
KEYCLOAK_URL = os.getenv("KEYCLOAK_URL", "http://keycloak:8080")
KEYCLOAK_REALM = os.getenv("KEYCLOAK_REALM", "blog")
KEYCLOAK_CLIENT_ID = os.getenv("KEYCLOAK_CLIENT_ID", "auth-service")
KEYCLOAK_CLIENT_SECRET = os.getenv("KEYCLOAK_CLIENT_SECRET")


@router.get("/me")
async def get_my_profile(user: TokenData = Depends(get_current_user)):
    """Return the authenticated user's profile from their token claims."""
    return {
        "id": user.sub,
        "email": user.email,
        "username": user.preferred_username,
        "first_name": user.given_name,
        "last_name": user.family_name,
        "roles": user.realm_roles,
    }


async def get_service_token() -> str:
    """
    Obtain a service-to-service access token using Client Credentials grant.

    This is machine-to-machine auth. The Auth Service authenticates itself
    to Keycloak with its client_id + client_secret and gets back a token
    that represents the service (not any particular user).

    The Blog Service trusts this token because it is signed by Keycloak.
    """
    token_url = (
        f"{KEYCLOAK_URL}/realms/{KEYCLOAK_REALM}/protocol/openid-connect/token"
    )
    async with httpx.AsyncClient() as client:
        response = await client.post(
            token_url,
            data={
                "grant_type": "client_credentials",
                "client_id": KEYCLOAK_CLIENT_ID,
                "client_secret": KEYCLOAK_CLIENT_SECRET,
            },
        )
        response.raise_for_status()
        return response.json()["access_token"]


@router.get("/me/posts")
async def get_my_posts(user: TokenData = Depends(get_current_user)):
    """
    Fetch the current user's blog posts from the Blog Service.

    Pattern:
      1. User authenticates with their user token (validated by get_current_user)
      2. Auth Service fetches a service token (Client Credentials)
      3. Auth Service calls Blog Service with the service token + user ID header
      4. Blog Service validates the service token and trusts the X-User-Id header
    """
    service_token = await get_service_token()

    async with httpx.AsyncClient() as client:
        response = await client.get(
            f"{BLOG_SERVICE_URL}/internal/posts",
            headers={
                "Authorization": f"Bearer {service_token}",
                "X-User-Id": user.sub,          # pass the original user's ID
                "X-User-Email": user.email or "",
            },
        )
        if response.status_code == 404:
            return []
        response.raise_for_status()
        return response.json()