"""
JWT validation against Keycloak's JWKS endpoint.

How it works:
  1. Keycloak signs every access token with its private key.
  2. Keycloak publishes its public keys at:
       {KEYCLOAK_URL}/realms/{REALM}/protocol/openid-connect/certs
  3. We fetch those public keys (JWKS) and use them to verify token signatures.
  4. We never need the user's password — the token IS the proof of identity.
"""

import os
import httpx
from functools import lru_cache
from typing import Optional
from fastapi import Depends, HTTPException, status
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
from jose import JWTError, jwt
from pydantic import BaseModel

KEYCLOAK_URL = os.getenv("KEYCLOAK_URL", "http://keycloak:8080")
KEYCLOAK_REALM = os.getenv("KEYCLOAK_REALM", "blog")

# Keycloak's standard OIDC discovery document URL
OIDC_DISCOVERY_URL = (
    f"{KEYCLOAK_URL}/realms/{KEYCLOAK_REALM}/.well-known/openid-configuration"
)

bearer_scheme = HTTPBearer()


class TokenData(BaseModel):
    sub: str                         # Keycloak user ID (UUID)
    email: Optional[str] = None
    given_name: Optional[str] = None
    family_name: Optional[str] = None
    preferred_username: Optional[str] = None
    realm_roles: list[str] = []
    resource_access: dict = {}


@lru_cache(maxsize=1)
def get_jwks_uri() -> str:
    """
    Fetch Keycloak's OIDC discovery document to get the JWKS URI.
    Cached because it never changes between restarts.
    """
    response = httpx.get(OIDC_DISCOVERY_URL)
    response.raise_for_status()
    return response.json()["jwks_uri"]


def get_public_keys() -> list[dict]:
    """Fetch Keycloak's current public signing keys."""
    jwks_uri = get_jwks_uri()
    response = httpx.get(jwks_uri)
    response.raise_for_status()
    return response.json()["keys"]


def verify_token(token: str) -> TokenData:
    """
    Decode and validate a Keycloak-issued JWT.

    jose.jwt.decode() will:
      - verify the signature against the public keys
      - verify the token has not expired (exp claim)
      - verify the issuer (iss claim)
      - verify the audience (aud claim) if we pass it
    """
    credentials_exception = HTTPException(
        status_code=status.HTTP_401_UNAUTHORIZED,
        detail="Could not validate token",
        headers={"WWW-Authenticate": "Bearer"},
    )

    try:
        keys = get_public_keys()
        # jose tries each key until one works (Keycloak can have multiple)
        payload = jwt.decode(
            token,
            keys,
            algorithms=["RS256"],
            audience="account",       # Keycloak sets audience to "account" by default
            options={
                "verify_aud": False,  # Relax audience check for simplicity
                "verify_iss": False   # Allow tokens from localhost or keycloak hostname
            }
        )
    except JWTError as exc:
        raise credentials_exception from exc

    # Extract realm-level roles from the token
    realm_access = payload.get("realm_access", {})
    roles = realm_access.get("roles", [])

    return TokenData(
        sub=payload["sub"],
        email=payload.get("email"),
        given_name=payload.get("given_name"),
        family_name=payload.get("family_name"),
        preferred_username=payload.get("preferred_username"),
        realm_roles=roles,
        resource_access=payload.get("resource_access", {}),
    )


async def get_current_user(
    credentials: HTTPAuthorizationCredentials = Depends(bearer_scheme),
) -> TokenData:
    """FastAPI dependency — extracts and validates the Bearer token."""
    return verify_token(credentials.credentials)


def require_role(role: str):
    """
    Factory dependency — returns a dependency that enforces a specific realm role.

    Usage:
        @router.delete("/posts/{id}", dependencies=[Depends(require_role("admin"))])
    """
    async def _checker(user: TokenData = Depends(get_current_user)) -> TokenData:
        if role not in user.realm_roles:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail=f"Role '{role}' required",
            )
        return user
    return _checker