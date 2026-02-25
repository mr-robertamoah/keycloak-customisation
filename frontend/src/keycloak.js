/**
 * keycloak.js
 *
 * Keycloak JS adapter setup.
 *
 * How PKCE flow works:
 *   1. init() redirects user to Keycloak login if not authenticated.
 *   2. After login, Keycloak redirects back with ?code=...
 *   3. The adapter exchanges the code for tokens automatically.
 *   4. Tokens are stored in memory (not localStorage — more secure).
 */

import Keycloak from 'keycloak-js'

const keycloak = new Keycloak({
  url: 'http://localhost:8080',
  realm: 'blog',
  clientId: 'blog-frontend',
})

let _initPromise = null

export function initKeycloak() {
  if (_initPromise) return _initPromise

  _initPromise = keycloak.init({
    // onLoad: 'check-sso' → silently checks if user is already logged in
    //                        Does NOT redirect if not authenticated
    // onLoad: 'login-required' → immediately redirects to login if not authenticated
    onLoad: 'check-sso',
    silentCheckSsoRedirectUri: window.location.origin + '/silent-check-sso.html',
    pkceMethod: 'S256',    // Enable PKCE — required for public clients (SPAs)
    checkLoginIframe: false,
  })

  // Keycloak auto-refreshes the token 70 seconds before it expires
  keycloak.onTokenExpired = () => {
    keycloak.updateToken(70).catch(() => {
      console.warn('Token refresh failed — logging out')
      keycloak.logout()
    })
  }

  return _initPromise
}

export function login() {
  return keycloak.login()
}

export function logout() {
  return keycloak.logout({ redirectUri: window.location.origin })
}

export function getToken() {
  return keycloak.token
}

export function isAuthenticated() {
  return !!keycloak.token
}

export function getUserInfo() {
  if (!keycloak.tokenParsed) return null
  return {
    id: keycloak.tokenParsed.sub,
    email: keycloak.tokenParsed.email,
    username: keycloak.tokenParsed.preferred_username,
    firstName: keycloak.tokenParsed.given_name,
    lastName: keycloak.tokenParsed.family_name,
    roles: keycloak.tokenParsed.realm_access?.roles ?? [],
  }
}

export default keycloak