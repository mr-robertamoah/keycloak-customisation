"""
Blog Service auth — validates tokens coming from other services.

The Blog Service has two kinds of callers:
  1. The Vue frontend (user access tokens) — for public post browsing
  2. The Auth Service (service account tokens) — for user-specific operations

We use the same JWKS verification but additionally inspect whether the
caller is a service account vs a user.
"""

import os
import httpx
from functools import lru_cache
from fastapi import Depends, HTTPException, Header, status
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
from jose import JWTError, jwt

KEYCLOAK_URL = os.getenv("KEYCLOAK_URL", "http://keycloak:8080")
KEYCLOAK_REALM = os.getenv("KEYCLOAK_REALM", "blog")
BLOG_SERVICE_CLIENT_ID = os.getenv("KEYCLOAK_CLIENT_ID", "blog-service")

bearer_scheme = HTTPBearer(auto_error=False)


@lru_cache(maxsize=1)
def _get_jwks_uri() -> str:
    discovery = httpx.get(
        f"{KEYCLOAK_URL}/realms/{KEYCLOAK_REALM}/.well-known/openid-configuration"
    )
    discovery.raise_for_status()
    return discovery.json()["jwks_uri"]


def _get_public_keys() -> list[dict]:
    return httpx.get(_get_jwks_uri()).json()["keys"]


def _decode(token: str) -> dict:
    try:
        return jwt.decode(
            token,
            _get_public_keys(),
            algorithms=["RS256"],
            options={
                "verify_aud": False,
                "verify_iss": False  # Allow tokens from localhost or keycloak hostname
            }
        )
    except JWTError as exc:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid token",
        ) from exc


async def get_user_token(
    credentials: HTTPAuthorizationCredentials = Depends(bearer_scheme),
) -> dict:
    """Validate a user-level access token (for public endpoints)."""
    if not credentials:
        raise HTTPException(status_code=401, detail="Not authenticated")
    return _decode(credentials.credentials)


async def require_service_token(
    credentials: HTTPAuthorizationCredentials = Depends(bearer_scheme),
) -> dict:
    """
    Validates a service account token.

    Service account tokens have `azp` (authorised party) set to the
    calling service's client_id and typically have no `email` claim.
    We check that the token comes from a known, trusted service.
    """
    if not credentials:
        raise HTTPException(status_code=401, detail="Not authenticated")

    payload = _decode(credentials.credentials)

    # Service account tokens have `clientId` or `azp` but no regular `sub` username
    # The `service_account_client_id` claim is set by Keycloak for Client Credentials tokens
    authorised_party = payload.get("azp", "")
    trusted_services = {"auth-service", "blog-service"}   # adjust as needed

    if authorised_party not in trusted_services:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail=f"Service '{authorised_party}' is not trusted",
        )

    return payload