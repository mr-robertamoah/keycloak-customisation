# Keycloak Customization Guide
## A Hands-On Tutorial with Docker Compose and Kubernetes

> **Learning Path**: This guide teaches you Keycloak customization by doing. You'll deploy with Docker Compose first, understand the concepts, test everything manually, then deploy to Kubernetes.

---

## Table of Contents

### Part 1: Getting Started
1. [Introduction & Prerequisites](#1-introduction--prerequisites)
2. [Understanding the Architecture](#2-understanding-the-architecture)
3. [Project Structure Overview](#3-project-structure-overview)

### Part 2: Docker Compose Deployment
4. [Deploy with Docker Compose](#4-deploy-with-docker-compose)
5. [Understanding Keycloak Concepts](#5-understanding-keycloak-concepts)
6. [Manual Testing - Docker Compose](#6-manual-testing---docker-compose)
7. [Understanding the Custom Theme](#7-understanding-the-custom-theme)
8. [Customizing Your Theme](#8-customizing-your-theme)

### Part 3: Backend Services
9. [Understanding the Auth Service](#9-understanding-the-auth-service)
10. [Understanding the Blog Service](#10-understanding-the-blog-service)
11. [Service-to-Service Authentication](#11-service-to-service-authentication)
12. [Testing Backend APIs](#12-testing-backend-apis)

### Part 4: Frontend Application
13. [Understanding the Vue Frontend](#13-understanding-the-vue-frontend)
14. [Keycloak JS Adapter Deep Dive](#14-keycloak-js-adapter-deep-dive)
15. [Testing the Complete Flow](#15-testing-the-complete-flow)

### Part 5: Kubernetes Deployment
16. [Understanding Kubernetes Concepts](#16-understanding-kubernetes-concepts)
17. [Deploy to kind (Kubernetes)](#17-deploy-to-kind-kubernetes)
18. [Manual Testing - Kubernetes](#18-manual-testing---kubernetes)
19. [Comparing Docker Compose vs Kubernetes](#19-comparing-docker-compose-vs-kubernetes)

### Part 6: Advanced Topics
20. [FreeMarker Template Reference](#20-freemarker-template-reference)
21. [Email Templates](#21-email-templates)
22. [Troubleshooting Guide](#22-troubleshooting-guide)
23. [Production Considerations](#23-production-considerations)

---

## 1. Introduction & Prerequisites

### What You'll Learn

By the end of this guide, you will:
- ✅ Understand how Keycloak works and why it's useful
- ✅ Deploy a complete authentication system with Docker Compose
- ✅ Create custom login and registration themes
- ✅ Build microservices that validate JWT tokens
- ✅ Implement service-to-service authentication
- ✅ Deploy the same system to Kubernetes
- ✅ Test everything manually to verify it works

### Prerequisites

**Required:**
- Docker Desktop (≥ 24) - [Install](https://docs.docker.com/get-docker/)
- Basic understanding of:
  - HTTP/REST APIs
  - JSON
  - Command line basics

**Optional (for Kubernetes section):**
- kind (≥ 0.22) - [Install](https://kind.sigs.k8s.io/docs/user/quick-start/)
- kubectl (≥ 1.29) - [Install](https://kubernetes.io/docs/tasks/tools/)

**Verify your setup:**
```bash
docker --version
# Should show: Docker version 24.x or higher

docker compose version
# Should show: Docker Compose version 2.x or higher
```

### Time Commitment

- **Docker Compose section**: 1-2 hours
- **Kubernetes section**: 1 hour
- **Total**: 2-3 hours for complete understanding

---

## 2. Understanding the Architecture

### The Big Picture

Before we start deploying, let's understand what we're building:

```
┌─────────────────────────────────────────────────────────────┐
│                         Browser                              │
│                    Vue SPA (port 5173)                       │
└───────────────────────┬─────────────────────────────────────┘
                        │
                        │ 1. User clicks "Login"
                        ▼
              ┌──────────────────────┐
              │     Keycloak         │
              │   (port 8080)        │
              │                      │
              │  • Custom Theme      │
              │  • User Management   │
              │  • Token Generation  │
              └──────────┬───────────┘
                        │
                        │ 2. Returns JWT token
                        ▼
              ┌──────────────────────┐
              │   Auth Service       │
              │   (port 8001)        │
              │                      │
              │  • Validates tokens  │
              │  • User profiles     │
              └──────────┬───────────┘
                        │
                        │ 3. Calls with service token
                        ▼
              ┌──────────────────────┐
              │   Blog Service       │
              │   (port 8002)        │
              │                      │
              │  • Manages posts     │
              │  • Trusts auth svc   │
              └──────────┬───────────┘
                        │
                        ▼
              ┌──────────────────────┐
              │    PostgreSQL        │
              │   (port 5432)        │
              └──────────────────────┘
```

### Why This Architecture?

**1. Separation of Concerns**
- **Keycloak**: Handles ALL authentication logic
- **Auth Service**: Business logic for user operations
- **Blog Service**: Domain-specific functionality
- **Frontend**: User interface only

**2. Security Benefits**
- Passwords never touch your application code
- Centralized user management
- Standard OAuth 2.0 / OpenID Connect protocols
- JWT tokens for stateless authentication

**3. Scalability**
- Each service can scale independently
- Keycloak can handle millions of users
- Microservices can be deployed separately

### Key Concepts

**JWT (JSON Web Token)**
- A signed token that proves who you are
- Contains user information (claims)
- Can't be forged because it's cryptographically signed
- Has an expiration time

**OAuth 2.0 / OpenID Connect**
- Industry-standard protocols for authentication
- OAuth 2.0: Authorization ("what can you do?")
- OpenID Connect: Authentication ("who are you?")

**Realm**
- An isolated tenant in Keycloak
- Think of it as your application's "universe"
- Contains users, clients, roles, and settings

**Client**
- An application that uses Keycloak
- Can be a frontend app, backend service, or mobile app
- Has credentials (for confidential clients)

---

## 3. Project Structure Overview

Let's look at what files we have and why:

```
keycloak-customisation/
├── docker-compose.yml          # Defines all services for local dev
├── kind-config.yaml            # Kubernetes cluster configuration
├── deploy-kind.sh              # Automated Kubernetes deployment
├── test-docker-compose.sh      # Automated tests for Docker
├── test-kind.sh                # Automated tests for Kubernetes
│
├── keycloak/
│   ├── Dockerfile              # Custom Keycloak image with theme
│   ├── blog-realm.json         # Pre-configured realm (auto-import)
│   └── themes/blog-theme/      # Your custom theme
│       ├── login/              # Login & registration pages
│       │   ├── theme.properties      # Theme configuration
│       │   ├── resources/
│       │   │   └── css/styles.css    # Your custom CSS
│       │   └── templates/
│       │       ├── login.ftl         # Login page template
│       │       ├── register.ftl      # Registration page
│       │       └── ...               # Other pages
│       └── email/              # Email templates
│           ├── html/           # HTML emails
│           └── text/           # Plain text fallbacks
│
├── services/
│   ├── auth-service/           # User authentication API
│   │   ├── Dockerfile
│   │   ├── requirements.txt
│   │   └── app/
│   │       ├── main.py         # FastAPI app entry point
│   │       ├── auth.py         # JWT validation logic
│   │       └── routers/
│   │           └── users.py    # User endpoints
│   │
│   └── blog-service/           # Blog posts API
│       ├── Dockerfile
│       ├── requirements.txt
│       └── app/
│           ├── main.py
│           ├── auth.py
│           └── routers/
│               └── posts.py
│
├── frontend/                   # Vue 3 SPA
│   ├── Dockerfile              # Multi-stage build with nginx
│   ├── nginx.conf              # SPA routing configuration
│   ├── package.json
│   ├── vite.config.js
│   └── src/
│       ├── main.js             # App initialization
│       ├── App.vue             # Main layout
│       ├── keycloak.js         # Keycloak integration
│       └── views/
│           ├── Home.vue        # Landing page
│           └── Blog.vue        # Blog posts page
│
└── k8s/                        # Kubernetes manifests
    ├── postgres.yaml
    ├── keycloak.yaml
    ├── auth-service.yaml
    ├── blog-service.yaml
    └── frontend.yaml
```

### Why These Files?

**docker-compose.yml**
- Defines all 5 services (postgres, keycloak, auth, blog, frontend)
- Sets up networking so services can talk to each other
- Mounts volumes for data persistence and theme hot-reload

**keycloak/blog-realm.json**
- Pre-configured realm with all clients
- Saves you from manual Keycloak configuration
- Automatically imported on startup

**services/*/app/auth.py**
- JWT validation logic
- Fetches Keycloak's public keys
- Verifies token signatures
- Extracts user information

**frontend/src/keycloak.js**
- Keycloak JS adapter configuration
- Handles login redirects
- Manages token refresh
- Provides authentication state

---

## 4. Deploy with Docker Compose

Now let's get everything running!

### Step 1: Start the Services

```bash
# Navigate to project directory
cd keycloak-customisation

# Start all services (this will build images on first run)
docker compose up -d

# This will:
# 1. Pull PostgreSQL image
# 2. Build auth-service image
# 3. Build blog-service image
# 4. Build frontend image
# 5. Pull Keycloak image
# 6. Start all containers
# 7. Wait for health checks
```

**What's happening:**
- `docker compose up`: Starts services defined in docker-compose.yml
- `-d`: Detached mode (runs in background)
- First run takes 2-3 minutes to build images
- Subsequent runs take 30-60 seconds

### Step 2: Wait for Services to Start

```bash
# Watch the logs
docker compose logs -f

# Look for these messages:
# postgres: "database system is ready to accept connections"
# keycloak: "Keycloak 24.0 ... started"
# auth-service: "Uvicorn running on http://0.0.0.0:8001"
# blog-service: "Uvicorn running on http://0.0.0.0:8002"
# frontend: (nginx starts silently)

# Press Ctrl+C to stop watching logs
```

### Step 3: Verify All Services Are Running

```bash
# Check container status
docker compose ps

# You should see 5 containers:
# - keycloak-customisation-postgres-1    (healthy)
# - keycloak-customisation-keycloak-1    (healthy)
# - keycloak-customisation-auth-service-1
# - keycloak-customisation-blog-service-1
# - keycloak-customisation-frontend-1
```

### Step 4: Run Automated Tests

```bash
# Run the test script
./test-docker-compose.sh

# This tests:
# ✓ All containers running
# ✓ PostgreSQL connectivity
# ✓ Keycloak health
# ✓ Realm imported
# ✓ Auth service health
# ✓ Blog service health
# ✓ Frontend serving
# ✓ Admin login
# ✓ Client configuration
```

### Understanding What Just Happened

**1. PostgreSQL Started**
- Created database: `keycloak`
- Created additional databases: `auth_db`, `blog_db`
- Keycloak stores its data here

**2. Keycloak Started**
- Connected to PostgreSQL
- Imported `blog-realm.json` automatically
- Created 3 clients:
  - `blog-frontend` (public client for Vue app)
  - `auth-service` (confidential client with secret)
  - `blog-service` (confidential client with secret)
- Loaded custom theme from `keycloak/themes/blog-theme/`

**3. Backend Services Started**
- Both services connected to Keycloak
- Fetched public keys for JWT validation
- Ready to accept requests

**4. Frontend Built and Deployed**
- Vue app compiled with Vite
- Static files served by nginx
- Configured for SPA routing

### Troubleshooting

**If Keycloak doesn't start:**
```bash
# Check logs
docker compose logs keycloak

# Common issue: Port 8080 already in use
# Solution: Stop other services or change port in docker-compose.yml
```

**If services can't connect:**
```bash
# Restart services
docker compose restart

# Or rebuild
docker compose up -d --build
```

**If you need a fresh start:**
```bash
# Stop and remove everything
docker compose down -v

# Start again
docker compose up -d
```

---

## 5. Understanding Keycloak Concepts

Now that everything is running, let's understand the key Keycloak concepts by exploring the admin console.

### Access the Keycloak Admin Console

1. Open your browser and go to: http://localhost:8080
2. Click "Administration Console"
3. Login with:
   - Username: `admin`
   - Password: `admin`

### Concept 1: Realms

**What is a Realm?**
- An isolated tenant in Keycloak
- Contains users, clients, roles, and settings
- You NEVER use the `master` realm for your applications
- The `master` realm is only for managing Keycloak itself

**Try This:**
1. Look at the top-left dropdown (currently shows "master")
2. Click it and select "blog"
3. You're now in your application's realm

**Why it matters:**
- Different applications can have separate realms
- Users in one realm can't access another realm
- Each realm has its own theme, settings, and security policies

### Concept 2: Clients

**What is a Client?**
- A registered application that uses Keycloak
- Can be a frontend app, backend service, or mobile app
- Has a unique client ID
- May have a client secret (for confidential clients)

**Try This:**
1. In the "blog" realm, click "Clients" in the left menu
2. You should see 3 clients:
   - `blog-frontend`
   - `auth-service`
   - `blog-service`

3. Click on `blog-frontend`
4. Notice:
   - **Client authentication**: OFF (this is a public client)
   - **Valid redirect URIs**: `http://localhost:5173/*`
   - **Web origins**: `http://localhost:5173`

5. Click on `auth-service`
6. Notice:
   - **Client authentication**: ON (this is a confidential client)
   - **Service accounts roles**: Enabled
   - Go to "Credentials" tab to see the client secret

**Why it matters:**
- **Public clients** (like SPAs): Can't keep secrets, use PKCE
- **Confidential clients** (like backend services): Have secrets, can use client credentials
- **Redirect URIs**: Security feature - Keycloak only redirects to allowed URLs

### Concept 3: Users

**Try This:**
1. Click "Users" in the left menu
2. Click "Add user"
3. Fill in:
   - Username: `demouser`
   - Email: `demo@example.com`
   - First name: `Demo`
   - Last name: `User`
   - Email verified: ON
4. Click "Create"
5. Go to "Credentials" tab
6. Click "Set password"
7. Enter password: `Demo123!`
8. Turn OFF "Temporary"
9. Click "Save"

**Why it matters:**
- Users are stored in Keycloak, not your application
- You can import users from LDAP, Active Directory, or other sources
- Users can have attributes, roles, and groups

### Concept 4: Tokens

**What is a JWT Token?**
A JWT (JSON Web Token) has 3 parts separated by dots:
```
header.payload.signature
```

**Try This - Get a Token:**
```bash
# Get a token for your demo user
curl -X POST http://localhost:8080/realms/blog/protocol/openid-connect/token \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "username=demouser" \
  -d "password=Demo123!" \
  -d "grant_type=password" \
  -d "client_id=blog-frontend" | jq .
```

You'll get a response like:
```json
{
  "access_token": "eyJhbGciOiJSUzI1NiIsInR5cCI6IkpXVCJ9...",
  "expires_in": 300,
  "refresh_expires_in": 1800,
  "refresh_token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "token_type": "Bearer"
}
```

**Decode the Token:**
```bash
# Save the access token
TOKEN="<paste your access_token here>"

# Decode the payload (middle part)
echo $TOKEN | cut -d'.' -f2 | base64 -d 2>/dev/null | jq .
```

You'll see:
```json
{
  "exp": 1772035442,           // Expiration time
  "iat": 1772035142,           // Issued at time
  "sub": "e6ecbc3b-...",       // User ID
  "preferred_username": "demouser",
  "email": "demo@example.com",
  "given_name": "Demo",
  "family_name": "User",
  "realm_access": {
    "roles": ["user", ...]     // User's roles
  }
}
```

**Why it matters:**
- The token contains user information (no database lookup needed)
- It's signed by Keycloak (can't be forged)
- It expires (security feature)
- Your backend validates the signature using Keycloak's public keys

### Concept 5: Authentication Flows

**Authorization Code Flow with PKCE** (used by frontend):
```
1. User clicks "Login" in Vue app
2. Vue redirects to Keycloak login page
3. User enters credentials
4. Keycloak redirects back with a code
5. Vue exchanges code for tokens
6. Vue stores tokens in memory
```

**Client Credentials Flow** (used by services):
```
1. Auth service needs to call Blog service
2. Auth service sends client_id + client_secret to Keycloak
3. Keycloak returns a service token
4. Auth service calls Blog service with service token
5. Blog service validates the token
```

**Try This - Service Token:**
```bash
# Get a service token
curl -X POST http://localhost:8080/realms/blog/protocol/openid-connect/token \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "grant_type=client_credentials" \
  -d "client_id=auth-service" \
  -d "client_secret=auth-service-secret" | jq .
```

Notice the token is different - it represents the service, not a user.

---

## 6. Manual Testing - Docker Compose

Let's test everything manually to understand how it all works together.

### Test 1: Access the Frontend

1. Open http://localhost:5173 in your browser
2. You should see the home page with "Welcome to The Blog"
3. Click "Get Started"

**What happens:**
- Vue app detects you're not logged in
- Redirects you to Keycloak login page
- Notice the URL: `http://localhost:8080/realms/blog/protocol/openid-connect/auth?...`

### Test 2: See the Custom Theme

You're now on the Keycloak login page with your custom theme!

**Notice:**
- Custom colors (blue primary color)
- Custom logo area
- Clean, modern design
- "Register" link at the bottom

**This is YOUR theme** from `keycloak/themes/blog-theme/login/templates/login.ftl`

### Test 3: Register a New User

1. Click "Register" (or "Create account")
2. Fill in the form:
   - First name: `Test`
   - Last name: `User`
   - Email: `test@example.com`
   - Username: `testuser`
   - Password: `Test123!`
   - Confirm password: `Test123!`
3. Click "Register"

**What happens:**
- Keycloak creates the user
- Automatically logs you in
- Redirects back to Vue app at `http://localhost:5173`
- Vue app receives the authorization code
- Vue app exchanges code for tokens
- You're now logged in!

### Test 4: Create a Blog Post

You should now be on the "My Posts" page.

1. Fill in the form:
   - Title: `My First Post`
   - Content: `Hello from Keycloak!`
2. Click "Publish"

**What happens:**
```
1. Vue app sends POST request to http://localhost:8002/api/posts
2. Request includes: Authorization: Bearer <your_token>
3. Blog service validates the token:
   - Fetches Keycloak's public keys
   - Verifies token signature
   - Checks expiration
   - Extracts user ID
4. Blog service creates the post
5. Returns the post data
6. Vue app displays it in the list
```

### Test 5: Verify Token Validation

Open your browser's Developer Tools (F12) and go to the Network tab.

1. Create another post
2. Look at the POST request to `/api/posts`
3. Click on it and go to "Headers"
4. Find "Authorization" header
5. You'll see: `Bearer eyJhbGciOiJSUzI1NiIsInR5cCI6IkpXVCJ9...`

**Try This - Invalid Token:**
```bash
# Try to create a post with an invalid token
curl -X POST http://localhost:8002/api/posts \
  -H "Authorization: Bearer invalid_token" \
  -H "Content-Type: application/json" \
  -d '{"title":"Test","content":"Test","published":true}'

# You'll get: {"detail":"Could not validate token"}
```

### Test 6: Logout and Login Again

1. Click "Logout" in the top-right
2. You're redirected to the home page
3. Click "Get Started" again
4. Login with your credentials
5. Your posts are still there!

**Why?**
- Posts are stored in the database
- Associated with your user ID
- Persist across sessions

### Test 7: Test Service-to-Service Communication

```bash
# Get a user token
USER_TOKEN=$(curl -s -X POST http://localhost:8080/realms/blog/protocol/openid-connect/token \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "username=testuser" \
  -d "password=Test123!" \
  -d "grant_type=password" \
  -d "client_id=blog-frontend" | jq -r '.access_token')

# Call auth service to get user profile
curl -H "Authorization: Bearer $USER_TOKEN" \
  http://localhost:8001/api/users/me | jq .

# Expected output:
# {
#   "id": "e6ecbc3b-...",
#   "email": "test@example.com",
#   "username": "testuser",
#   "first_name": "Test",
#   "last_name": "User",
#   "roles": ["user", ...]
# }

# Call auth service to get user's posts (this calls blog service internally)
curl -H "Authorization: Bearer $USER_TOKEN" \
  http://localhost:8001/api/users/me/posts | jq .
```

**What happened:**
1. You called Auth Service with user token
2. Auth Service validated your token
3. Auth Service got a service token from Keycloak
4. Auth Service called Blog Service with service token + your user ID
5. Blog Service validated service token
6. Blog Service returned your posts
7. Auth Service returned them to you

### Test 8: Check the Logs

```bash
# Watch auth service logs
docker compose logs -f auth-service

# In another terminal, make a request
curl -H "Authorization: Bearer $USER_TOKEN" \
  http://localhost:8001/api/users/me

# You'll see in logs:
# INFO: 172.19.0.1:54102 - "GET /api/users/me HTTP/1.1" 200 OK
```

---

## 7. Understanding the Custom Theme

Let's explore how the theme works.

### Theme Structure

```
keycloak/themes/blog-theme/
├── login/
│   ├── theme.properties        # Theme configuration
│   ├── resources/
│   │   └── css/
│   │       └── styles.css      # Your custom CSS
│   └── templates/
│       ├── login.ftl           # Login page
│       ├── register.ftl        # Registration page
│       ├── login-reset-password.ftl
│       └── error.ftl
└── email/
    ├── theme.properties
    ├── html/
    │   ├── email-verification.ftl
    │   └── password-reset.ftl
    └── text/
        ├── email-verification.ftl
        └── password-reset.ftl
```

### How Themes Work

**1. Theme Discovery**
- Keycloak looks in `/opt/keycloak/themes/` directory
- Each subdirectory is a theme
- Theme name = directory name

**2. Theme Types**
- `login`: Login, registration, password reset pages
- `account`: User account management pages
- `email`: Email templates
- `admin`: Admin console (rarely customized)
- `welcome`: Keycloak welcome page

**3. Theme Inheritance**
In `theme.properties`:
```properties
parent=keycloak
```
This means: "Use keycloak theme as base, override only what I specify"

**4. Template Engine: FreeMarker**
- Files end in `.ftl`
- Similar to Jinja2 (Python) or Handlebars (JavaScript)
- Keycloak passes data to templates
- Templates render HTML

### Key Template Variables

Every template receives these variables from Keycloak:

| Variable | Description | Example |
|----------|-------------|---------|
| `url` | URLs for actions | `url.loginAction`, `url.registrationUrl` |
| `realm` | Realm settings | `realm.displayName`, `realm.rememberMe` |
| `client` | Current client | `client.clientId` |
| `user` | User data (if logged in) | `user.username`, `user.email` |
| `message` | Error/success messages | `message.summary`, `message.type` |
| `properties` | Theme properties | `properties.logoUrl` |
| `resourcesPath` | Path to resources | `/realms/blog/login-actions/...` |

### Example: Login Template

Let's look at `login.ftl`:

```freemarker
<!DOCTYPE html>
<html>
<head>
  <title>${msg("loginTitle", realm.displayName)}</title>
  <link rel="stylesheet" href="${resourcesPath}/css/styles.css" />
</head>
<body>
  <#-- Show error message if login failed -->
  <#if message?has_content>
    <div class="alert alert-${message.type}">
      ${kcSanitize(message.summary)?no_esc}
    </div>
  </#if>

  <#-- Login form -->
  <form action="${url.loginAction}" method="post">
    <input type="text" name="username" 
           value="${(login.username!'')?html}" />
    <input type="password" name="password" />
    <button type="submit">${msg("doLogIn")}</button>
  </form>

  <#-- Registration link if enabled -->
  <#if realm.registrationAllowed>
    <a href="${url.registrationUrl}">${msg("doRegister")}</a>
  </#if>
</body>
</html>
```

**Key Points:**
- `${...}`: Print variable
- `<#if>...</#if>`: Conditional
- `?has_content`: Check if variable exists and not empty
- `?html`: HTML escape (security)
- `?no_esc`: Don't escape (use with `kcSanitize()`)
- `msg("key")`: Internationalization

---

## 8. Customizing Your Theme

Now let's customize the theme and see changes in real-time!

### Hot Reload is Enabled

The docker-compose.yml has these settings:
```yaml
KC_SPI_THEME_CACHE_THEMES: "false"
KC_SPI_THEME_CACHE_TEMPLATES: "false"
```

This means: **Edit files → Save → Refresh browser** (no restart needed!)

### Exercise 1: Change the Primary Color

1. Open `keycloak/themes/blog-theme/login/resources/css/styles.css`
2. Find line 3:
```css
--brand-primary: #3B82F6;  /* Blue */
```
3. Change it to:
```css
--brand-primary: #EF4444;  /* Red */
```
4. Save the file
5. Go to http://localhost:8080/realms/blog/account
6. Refresh the page
7. Buttons should now be red!

**Why it works:**
- The CSS file is mounted as a volume in docker-compose.yml
- Keycloak serves it directly from your filesystem
- No caching means changes are immediate

### Exercise 2: Customize the Login Page

1. Open `keycloak/themes/blog-theme/login/templates/login.ftl`
2. Find the brand title section (around line 30):
```freemarker
<h1 class="brand-title">${properties.brandName!realm.displayName}</h1>
```
3. Change it to:
```freemarker
<h1 class="brand-title">🚀 ${properties.brandName!realm.displayName}</h1>
<p class="brand-subtitle">Secure Authentication Made Easy</p>
```
4. Save the file
5. Go to http://localhost:8080/realms/blog/protocol/openid-connect/auth?client_id=blog-frontend&redirect_uri=http://localhost:5173&response_type=code
6. Refresh
7. You should see the rocket emoji and new subtitle!

### Exercise 3: Add a Custom Property

1. Open `keycloak/themes/blog-theme/login/theme.properties`
2. Add a new property:
```properties
companyName=My Awesome Company
supportEmail=support@example.com
```
3. Open `login.ftl`
4. Add at the bottom (before `</body>`):
```freemarker
<footer style="text-align:center; margin-top:2rem; color:#64748B; font-size:0.875rem;">
  <p>&copy; 2026 ${properties.companyName}</p>
  <p>Need help? <a href="mailto:${properties.supportEmail}">${properties.supportEmail}</a></p>
</footer>
```
5. Save both files
6. Refresh the login page
7. You should see your custom footer!

### Exercise 4: Customize the Registration Page

1. Open `keycloak/themes/blog-theme/login/templates/register.ftl`
2. Find the title section:
```freemarker
<h1 class="brand-title">Create your account</h1>
```
3. Change it to:
```freemarker
<h1 class="brand-title">Join ${properties.companyName}</h1>
<p class="brand-subtitle">Start your journey today!</p>
```
4. Save and refresh the registration page

### Understanding CSS Variables

The theme uses CSS variables for easy customization:

```css
:root {
  --brand-primary: #3B82F6;        /* Main color */
  --brand-primary-hover: #2563EB;  /* Hover state */
  --brand-bg: #F8FAFF;             /* Background */
  --brand-card: #FFFFFF;           /* Card background */
  --brand-text: #1E293B;           /* Text color */
  --brand-muted: #64748B;          /* Muted text */
  --brand-border: #E2E8F0;         /* Borders */
  --brand-error: #EF4444;          /* Error messages */
  --brand-success: #10B981;        /* Success messages */
}
```

**Try changing multiple colors:**
```css
:root {
  --brand-primary: #8B5CF6;        /* Purple */
  --brand-primary-hover: #7C3AED;
  --brand-bg: #FAF5FF;             /* Light purple bg */
}
```

### Common Customizations

**1. Add a Logo**
```freemarker
<img class="brand-logo" 
     src="${resourcesPath}/img/logo.svg" 
     alt="${properties.brandName}" />
```

Then add your logo to: `keycloak/themes/blog-theme/login/resources/img/logo.svg`

**2. Change Fonts**
In `styles.css`:
```css
body {
  font-family: 'Your Font', system-ui, sans-serif;
}
```

**3. Add Custom JavaScript**
In `theme.properties`:
```properties
scripts=js/custom.js
```

Then create: `keycloak/themes/blog-theme/login/resources/js/custom.js`

---

## 9. Understanding the Auth Service

Let's dive into how the backend validates tokens.

### Auth Service Architecture

```
services/auth-service/
├── Dockerfile
├── requirements.txt
└── app/
    ├── __init__.py
    ├── main.py          # FastAPI app
    ├── auth.py          # JWT validation
    └── routers/
        └── users.py     # User endpoints
```

### How JWT Validation Works

**Step 1: Fetch Keycloak's Public Keys**

```python
# services/auth-service/app/auth.py

def get_jwks_uri() -> str:
    """Get the JWKS URI from Keycloak's discovery endpoint"""
    response = httpx.get(
        f"{KEYCLOAK_URL}/realms/{KEYCLOAK_REALM}/.well-known/openid-configuration"
    )
    return response.json()["jwks_uri"]

def get_public_keys() -> list[dict]:
    """Fetch Keycloak's public signing keys"""
    jwks_uri = get_jwks_uri()
    response = httpx.get(jwks_uri)
    return response.json()["keys"]
```

**Why?**
- Keycloak signs tokens with its private key
- Anyone can verify with the public key
- Public keys are published at the JWKS endpoint
- No need to call Keycloak for every request!

**Step 2: Verify the Token**

```python
def verify_token(token: str) -> TokenData:
    """Decode and validate a JWT"""
    keys = get_public_keys()
    
    payload = jwt.decode(
        token,
        keys,
        algorithms=["RS256"],
        options={
            "verify_aud": False,  # Relax audience check
            "verify_iss": False   # Allow localhost or keycloak hostname
        }
    )
    
    return TokenData(
        sub=payload["sub"],
        email=payload.get("email"),
        preferred_username=payload.get("preferred_username"),
        realm_roles=payload.get("realm_access", {}).get("roles", [])
    )
```

**What it checks:**
- ✅ Signature is valid (token wasn't tampered with)
- ✅ Token hasn't expired
- ✅ Token was issued by Keycloak
- ✅ Algorithm is RS256 (RSA signature)

**Step 3: Use as a Dependency**

```python
# services/auth-service/app/routers/users.py

@router.get("/me")
async def get_my_profile(user: TokenData = Depends(get_current_user)):
    """Return the authenticated user's profile"""
    return {
        "id": user.sub,
        "email": user.email,
        "username": user.preferred_username,
        "roles": user.realm_roles
    }
```

**FastAPI magic:**
- `Depends(get_current_user)` runs before the endpoint
- Extracts token from `Authorization: Bearer <token>` header
- Validates it
- Passes user data to your function
- Returns 401 if invalid

### Test the Auth Service

```bash
# Get a token
TOKEN=$(curl -s -X POST http://localhost:8080/realms/blog/protocol/openid-connect/token \
  -d "username=testuser" \
  -d "password=Test123!" \
  -d "grant_type=password" \
  -d "client_id=blog-frontend" | jq -r '.access_token')

# Call the endpoint
curl -H "Authorization: Bearer $TOKEN" \
  http://localhost:8001/api/users/me | jq .

# Expected output:
# {
#   "id": "e6ecbc3b-...",
#   "email": "test@example.com",
#   "username": "testuser",
#   "first_name": "Test",
#   "last_name": "User",
#   "roles": ["user", "offline_access", ...]
# }
```

### Why This Approach?

**Stateless Authentication:**
- No session storage needed
- No database lookup for every request
- Scales horizontally easily

**Security:**
- Tokens can't be forged (cryptographic signature)
- Tokens expire automatically
- Revocation possible via token introspection

**Performance:**
- Public keys are cached
- No network call to Keycloak per request
- Fast validation (just signature check)

---

## 10. Understanding the Blog Service

The Blog Service is similar but adds service-to-service authentication.

### Blog Service Endpoints

```python
# services/blog-service/app/routers/posts.py

# Public endpoint - requires user token
@router.get("")
async def list_posts(user: dict = Depends(get_user_token)):
    """Return all published posts"""
    return [p for p in _posts if p["published"]]

# Public endpoint - requires user token
@router.post("")
async def create_post(
    body: PostCreate,
    user: dict = Depends(get_user_token)
):
    """Create a new post"""
    new_post = {
        "id": str(len(_posts) + 1),
        "title": body.title,
        "content": body.content,
        "author_id": user["sub"],
        "author_name": user.get("preferred_username"),
        "published": body.published
    }
    _posts.append(new_post)
    return new_post

# Internal endpoint - requires service token
@internal_router.get("")
async def get_user_posts(
    _: dict = Depends(require_service_token),
    x_user_id: str = Header(..., alias="X-User-Id")
):
    """Called by Auth Service to get a user's posts"""
    return [p for p in _posts if p["author_id"] == x_user_id]
```

### Service-to-Service Pattern

**Problem:**
- Auth Service needs to get a user's posts from Blog Service
- But it shouldn't use the user's token (security risk)
- And Blog Service needs to know which user's posts to return

**Solution:**
1. Auth Service gets its own service token from Keycloak
2. Auth Service calls Blog Service with service token
3. Auth Service passes user ID in `X-User-Id` header
4. Blog Service validates service token
5. Blog Service trusts the `X-User-Id` header (because token is valid)

**Code in Auth Service:**

```python
# services/auth-service/app/routers/users.py

async def get_service_token() -> str:
    """Get a service-to-service token"""
    response = await httpx.post(
        f"{KEYCLOAK_URL}/realms/{KEYCLOAK_REALM}/protocol/openid-connect/token",
        data={
            "grant_type": "client_credentials",
            "client_id": KEYCLOAK_CLIENT_ID,
            "client_secret": KEYCLOAK_CLIENT_SECRET
        }
    )
    return response.json()["access_token"]

@router.get("/me/posts")
async def get_my_posts(user: TokenData = Depends(get_current_user)):
    """Get current user's posts from Blog Service"""
    service_token = await get_service_token()
    
    response = await httpx.get(
        f"{BLOG_SERVICE_URL}/internal/posts",
        headers={
            "Authorization": f"Bearer {service_token}",
            "X-User-Id": user.sub
        }
    )
    return response.json()
```

### Test Service-to-Service Communication

```bash
# Get user token
USER_TOKEN=$(curl -s -X POST http://localhost:8080/realms/blog/protocol/openid-connect/token \
  -d "username=testuser" \
  -d "password=Test123!" \
  -d "grant_type=password" \
  -d "client_id=blog-frontend" | jq -r '.access_token')

# Call Auth Service (which calls Blog Service internally)
curl -H "Authorization: Bearer $USER_TOKEN" \
  http://localhost:8001/api/users/me/posts | jq .

# Check the logs to see the service-to-service call
docker compose logs blog-service | tail -20
```

---

## 11. Service-to-Service Authentication

Let's understand this pattern in depth.

### Why Not Use the User's Token?

**Bad approach:**
```python
# DON'T DO THIS
@router.get("/me/posts")
async def get_my_posts(user_token: str):
    # Forward user's token to Blog Service
    response = await httpx.get(
        f"{BLOG_SERVICE_URL}/posts",
        headers={"Authorization": f"Bearer {user_token}"}
    )
```

**Problems:**
1. **Token leakage**: User's token passes through multiple services
2. **Scope creep**: User token might have permissions it shouldn't
3. **Expiration**: User token expires, breaks service calls
4. **Audit trail**: Can't distinguish user actions from service actions

### The Right Approach: Client Credentials

```
┌─────────────┐
│ Auth Service│
└──────┬──────┘
       │
       │ 1. Request service token
       ▼
┌─────────────┐
│  Keycloak   │
└──────┬──────┘
       │
       │ 2. Return service token
       ▼
┌─────────────┐
│ Auth Service│
└──────┬──────┘
       │
       │ 3. Call with service token + user ID
       ▼
┌─────────────┐
│ Blog Service│
└─────────────┘
```

### Service Token vs User Token

**User Token:**
```json
{
  "sub": "e6ecbc3b-...",           // User ID
  "preferred_username": "testuser",
  "email": "test@example.com",
  "azp": "blog-frontend",          // Authorized party (client)
  "realm_access": {
    "roles": ["user"]
  }
}
```

**Service Token:**
```json
{
  "sub": "service-account-auth-service",  // Service account
  "azp": "auth-service",                  // The service itself
  "clientId": "auth-service",
  "realm_access": {
    "roles": []                           // Service roles
  }
}
```

### Validating Service Tokens

```python
# services/blog-service/app/auth.py

async def require_service_token(
    credentials: HTTPAuthorizationCredentials = Depends(bearer_scheme)
) -> dict:
    """Validate that the token is from a trusted service"""
    payload = _decode(credentials.credentials)
    
    # Check the authorized party
    authorised_party = payload.get("azp", "")
    trusted_services = {"auth-service", "blog-service"}
    
    if authorised_party not in trusted_services:
        raise HTTPException(
            status_code=403,
            detail=f"Service '{authorised_party}' is not trusted"
        )
    
    return payload
```

### Security Considerations

**1. Trust Boundary**
- Only trusted services can call internal endpoints
- Service tokens are validated just like user tokens
- `X-User-Id` header is trusted because token is valid

**2. Least Privilege**
- Service tokens have minimal permissions
- Only what's needed for service-to-service calls
- Can't be used for user-facing operations

**3. Audit Trail**
```python
# Log service calls
logger.info(
    f"Service {payload['azp']} called /internal/posts "
    f"for user {x_user_id}"
)
```

---

## 12. Testing Backend APIs

Let's test all the API endpoints manually.

### Setup: Get Tokens

```bash
# Get a user token
export USER_TOKEN=$(curl -s -X POST http://localhost:8080/realms/blog/protocol/openid-connect/token \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "username=testuser" \
  -d "password=Test123!" \
  -d "grant_type=password" \
  -d "client_id=blog-frontend" | jq -r '.access_token')

echo "User token: ${USER_TOKEN:0:50}..."

# Get a service token
export SERVICE_TOKEN=$(curl -s -X POST http://localhost:8080/realms/blog/protocol/openid-connect/token \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "grant_type=client_credentials" \
  -d "client_id=auth-service" \
  -d "client_secret=auth-service-secret" | jq -r '.access_token')

echo "Service token: ${SERVICE_TOKEN:0:50}..."
```

### Test Auth Service Endpoints

```bash
# 1. Health check (no auth required)
curl http://localhost:8001/health | jq .

# 2. Get user profile
curl -H "Authorization: Bearer $USER_TOKEN" \
  http://localhost:8001/api/users/me | jq .

# 3. Get user's posts (calls Blog Service internally)
curl -H "Authorization: Bearer $USER_TOKEN" \
  http://localhost:8001/api/users/me/posts | jq .
```

### Test Blog Service Endpoints

```bash
# 1. Health check
curl http://localhost:8002/health | jq .

# 2. List all published posts
curl -H "Authorization: Bearer $USER_TOKEN" \
  http://localhost:8002/api/posts | jq .

# 3. Create a new post
curl -X POST http://localhost:8002/api/posts \
  -H "Authorization: Bearer $USER_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "title": "API Test Post",
    "content": "Created via curl",
    "published": true
  }' | jq .

# 4. List posts again (should include new post)
curl -H "Authorization: Bearer $USER_TOKEN" \
  http://localhost:8002/api/posts | jq .
```

### Test Internal Endpoint (Service-to-Service)

```bash
# This should work (service token + user ID header)
curl -H "Authorization: Bearer $SERVICE_TOKEN" \
  -H "X-User-Id: $(echo $USER_TOKEN | cut -d'.' -f2 | base64 -d 2>/dev/null | jq -r '.sub')" \
  http://localhost:8002/internal/posts | jq .

# This should fail (user token on internal endpoint)
curl -H "Authorization: Bearer $USER_TOKEN" \
  http://localhost:8002/internal/posts | jq .
# Expected: {"detail":"Service 'blog-frontend' is not trusted"}
```

### Test Error Cases

```bash
# 1. No token
curl http://localhost:8001/api/users/me
# Expected: {"detail":"Not authenticated"}

# 2. Invalid token
curl -H "Authorization: Bearer invalid_token" \
  http://localhost:8001/api/users/me
# Expected: {"detail":"Could not validate token"}

# 3. Expired token (wait 5 minutes or manually create one)
# Expected: {"detail":"Could not validate token"}
```

---

## 13. Understanding the Vue Frontend

Let's explore how the frontend integrates with Keycloak.

### Frontend Architecture

```
frontend/
├── src/
│   ├── main.js          # App initialization + Keycloak setup
│   ├── App.vue          # Main layout with navigation
│   ├── keycloak.js      # Keycloak adapter configuration
│   └── views/
│       ├── Home.vue     # Landing page
│       └── Blog.vue     # Blog posts page (protected)
```

### Keycloak JS Adapter Setup

```javascript
// frontend/src/keycloak.js

import Keycloak from 'keycloak-js'

const keycloak = new Keycloak({
  url: 'http://localhost:8080',
  realm: 'blog',
  clientId: 'blog-frontend'
})

export function initKeycloak() {
  return keycloak.init({
    onLoad: 'check-sso',              // Check if already logged in
    silentCheckSsoRedirectUri: window.location.origin + '/silent-check-sso.html',
    pkceMethod: 'S256',               // Enable PKCE for security
    checkLoginIframe: false           // Disable iframe check
  })
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
```

### App Initialization

```javascript
// frontend/src/main.js

import { createApp } from 'vue'
import { createRouter, createWebHistory } from 'vue-router'
import App from './App.vue'
import Home from './views/Home.vue'
import Blog from './views/Blog.vue'
import { initKeycloak, isAuthenticated } from './keycloak.js'

const router = createRouter({
  history: createWebHistory(),
  routes: [
    { path: '/', component: Home },
    {
      path: '/blog',
      component: Blog,
      beforeEnter: (_to, _from, next) => {
        if (isAuthenticated()) {
          next()
        } else {
          import('./keycloak.js').then(({ default: kc }) => kc.login())
        }
      }
    }
  ]
})

// Initialize Keycloak BEFORE mounting the app
initKeycloak().then(() => {
  createApp(App).use(router).mount('#app')
})
```

**Why this order?**
1. Initialize Keycloak first
2. Check if user is already logged in
3. Then mount the Vue app
4. This prevents flickering and ensures auth state is ready

### Making Authenticated API Calls

```javascript
// frontend/src/views/Blog.vue

import { getToken } from '../keycloak.js'

async function apiFetch(url, options = {}) {
  const token = getToken()
  return fetch(url, {
    ...options,
    headers: {
      'Content-Type': 'application/json',
      'Authorization': `Bearer ${token}`,
      ...options.headers
    }
  })
}

// Use it
const response = await apiFetch('http://localhost:8002/api/posts')
const posts = await response.json()
```

### Token Refresh

```javascript
// frontend/src/keycloak.js

// Keycloak automatically refreshes tokens
keycloak.onTokenExpired = () => {
  keycloak.updateToken(70).catch(() => {
    console.warn('Token refresh failed — logging out')
    keycloak.logout()
  })
}
```

**How it works:**
- Tokens expire after 5 minutes (default)
- Keycloak JS checks expiration before each request
- Automatically refreshes using refresh token
- If refresh fails, logs user out

---

## 14. Keycloak JS Adapter Deep Dive

### PKCE Flow Explained

**PKCE** = Proof Key for Code Exchange

**Why needed?**
- SPAs can't keep secrets (code is visible in browser)
- Traditional OAuth requires client secret
- PKCE adds security without secrets

**How it works:**

```
1. Generate random code_verifier
   Example: "dBjftJeZ4CVP-mB92K27uhbUJU1p1r_wW1gFWFOEjXk"

2. Hash it to create code_challenge
   SHA256(code_verifier) = "E9Melhoa2OwvFrEMTJguCHaoeK1t8URWbuGJSstw-cM"

3. Send code_challenge to Keycloak
   GET /auth?code_challenge=E9Melhoa...&code_challenge_method=S256

4. User logs in, Keycloak returns code
   Redirect: http://localhost:5173?code=abc123

5. Exchange code for token, send code_verifier
   POST /token
   code=abc123&code_verifier=dBjftJeZ...

6. Keycloak verifies: SHA256(code_verifier) == code_challenge
   If match, returns tokens
```

**Security benefit:**
- Even if someone intercepts the code, they can't use it
- They don't have the code_verifier
- Only the original app can exchange the code

### Silent SSO Check

```html
<!-- frontend/public/silent-check-sso.html -->
<script>
  parent.postMessage(location.href, location.origin)
</script>
```

**What this does:**
- Loaded in hidden iframe
- Checks if user has active Keycloak session
- If yes, silently logs them in
- If no, does nothing
- User doesn't see any redirect

### Token Storage

**Where are tokens stored?**
- In memory (JavaScript variable)
- NOT in localStorage or sessionStorage
- More secure (can't be stolen by XSS)

**Trade-off:**
- Tokens lost on page refresh
- But Keycloak JS handles this with silent SSO check

---

## 15. Testing the Complete Flow

Let's test the entire authentication flow manually.

### Test 1: Fresh User Registration

1. Open browser in incognito mode
2. Go to http://localhost:5173
3. Open Developer Tools (F12) → Network tab
4. Click "Get Started"

**Observe:**
- Redirect to `http://localhost:8080/realms/blog/protocol/openid-connect/auth?...`
- Notice query parameters:
  - `client_id=blog-frontend`
  - `redirect_uri=http://localhost:5173`
  - `response_type=code`
  - `code_challenge=...` (PKCE)
  - `code_challenge_method=S256`

5. Click "Register"
6. Fill in form and submit

**Observe:**
- POST to `/realms/blog/login-actions/registration`
- Redirect back to `http://localhost:5173?code=...`
- JavaScript exchanges code for tokens
- POST to `/realms/blog/protocol/openid-connect/token`
- Response contains `access_token`, `refresh_token`, `id_token`

7. You're now on the Blog page

### Test 2: Create a Post

1. Still in Network tab
2. Fill in post form
3. Click "Publish"

**Observe:**
- POST to `http://localhost:8002/api/posts`
- Request headers include: `Authorization: Bearer eyJhbGc...`
- Response: 201 Created with post data
- Post appears in list

### Test 3: Token Refresh

1. Wait 5 minutes (or change token lifespan in Keycloak)
2. Try to create another post

**Observe:**
- Before the POST request, Keycloak JS checks token expiration
- Automatically sends POST to `/realms/blog/protocol/openid-connect/token`
- With `grant_type=refresh_token`
- Gets new access token
- Then makes the original POST request

### Test 4: Logout

1. Click "Logout"

**Observe:**
- Redirect to `/realms/blog/protocol/openid-connect/logout`
- Keycloak ends the session
- Redirect back to `http://localhost:5173`
- You're logged out

### Test 5: Login Again

1. Click "Get Started"
2. Login with same credentials
3. Your posts are still there!

**Why?**
- Posts are stored in database
- Associated with your user ID (sub claim)
- Persist across sessions

---

## 16. Understanding Kubernetes Concepts

Before deploying to Kubernetes, let's understand the key concepts.

### What is Kubernetes?

**Kubernetes** (k8s) is a container orchestration platform that:
- Runs containers across multiple machines
- Automatically restarts failed containers
- Scales applications up/down
- Manages networking between containers
- Handles load balancing

### Key Kubernetes Objects

**1. Pod**
- Smallest deployable unit
- Contains one or more containers
- Shares network and storage
- Example: One pod runs one Keycloak container

**2. Deployment**
- Manages a set of identical pods
- Ensures desired number of replicas
- Handles rolling updates
- Example: "Run 3 replicas of frontend"

**3. Service**
- Stable network endpoint for pods
- Load balances across pod replicas
- Types:
  - ClusterIP: Internal only
  - NodePort: Accessible from outside
  - LoadBalancer: Cloud load balancer

**4. ConfigMap**
- Stores configuration data
- Can be mounted as files or environment variables
- Example: Keycloak realm configuration

### kind (Kubernetes in Docker)

**kind** creates a Kubernetes cluster using Docker containers.

**Why kind?**
- Runs locally on your machine
- No cloud account needed
- Fast to create/destroy
- Perfect for learning and testing

**Architecture:**
```
Your Machine
├── Docker
│   └── kind-control-plane (container)
│       └── Kubernetes cluster
│           ├── Pod: postgres
│           ├── Pod: keycloak
│           ├── Pod: auth-service
│           ├── Pod: blog-service
│           └── Pod: frontend
```

### Kubernetes vs Docker Compose

| Feature | Docker Compose | Kubernetes |
|---------|----------------|------------|
| **Use case** | Local development | Production |
| **Scaling** | Manual | Automatic |
| **Self-healing** | No | Yes |
| **Load balancing** | No | Yes |
| **Rolling updates** | No | Yes |
| **Multi-host** | No | Yes |
| **Complexity** | Simple | Complex |

---

## 17. Deploy to kind (Kubernetes)

Now let's deploy everything to Kubernetes!

### Step 1: Stop Docker Compose

```bash
# Stop Docker Compose first (ports will conflict)
docker compose down
```

### Step 2: Run the Deployment Script

```bash
# Make sure the script is executable
chmod +x deploy-kind.sh

# Run it
./deploy-kind.sh
```

**What the script does:**
1. Creates kind cluster with port mappings
2. Builds Docker images
3. Loads images into kind
4. Applies Kubernetes manifests
5. Waits for pods to be ready

**This takes 3-5 minutes.**

### Step 3: Watch the Deployment

```bash
# In another terminal, watch pods start
kubectl get pods -w

# You'll see:
# NAME                            READY   STATUS    RESTARTS   AGE
# postgres-xxx                    0/1     Pending   0          0s
# postgres-xxx                    0/1     ContainerCreating   0          1s
# postgres-xxx                    1/1     Running             0          10s
# keycloak-xxx                    0/1     Pending             0          0s
# ...
```

### Step 4: Verify Deployment

```bash
# Check all pods are running
kubectl get pods

# Check services
kubectl get svc

# You should see:
# NAME           TYPE        CLUSTER-IP      EXTERNAL-IP   PORT(S)
# postgres       ClusterIP   10.96.x.x       <none>        5432/TCP
# keycloak       NodePort    10.96.x.x       <none>        8080:30080/TCP
# auth-service   NodePort    10.96.x.x       <none>        8001:30001/TCP
# blog-service   NodePort    10.96.x.x       <none>        8002:30002/TCP
# frontend       NodePort    10.96.x.x       <none>        80:30173/TCP
```

### Step 5: Run Tests

```bash
./test-kind.sh
```

### Understanding the Manifests

**postgres.yaml:**
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: postgres
spec:
  replicas: 1
  selector:
    matchLabels:
      app: postgres
  template:
    metadata:
      labels:
        app: postgres
    spec:
      containers:
        - name: postgres
          image: postgres:16
          env:
            - name: POSTGRES_DB
              value: "keycloak"
          ports:
            - containerPort: 5432
```

**Key points:**
- `replicas: 1`: Run one instance
- `selector`: How deployment finds its pods
- `labels`: Tags for organizing resources
- `env`: Environment variables
- `ports`: Which ports the container exposes

**keycloak.yaml:**
```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: keycloak-realm
data:
  blog-realm.json: |
    { "realm": "blog", ... }
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: keycloak
spec:
  template:
    spec:
      containers:
        - name: keycloak
          image: blog-keycloak:latest
          imagePullPolicy: Never  # Use local image
          volumeMounts:
            - name: realm-config
              mountPath: /opt/keycloak/data/import
      volumes:
        - name: realm-config
          configMap:
            name: keycloak-realm
```

**Key points:**
- ConfigMap stores realm configuration
- Mounted as a volume in the pod
- `imagePullPolicy: Never`: Don't try to pull from registry

**Service with NodePort:**
```yaml
apiVersion: v1
kind: Service
metadata:
  name: keycloak
spec:
  type: NodePort
  selector:
    app: keycloak
  ports:
    - port: 8080
      targetPort: 8080
      nodePort: 30080
```

**Key points:**
- `type: NodePort`: Accessible from outside cluster
- `port`: Port inside cluster
- `targetPort`: Port on the pod
- `nodePort`: Port on your machine (30000-32767 range)

---

## 18. Manual Testing - Kubernetes

Let's test the Kubernetes deployment manually.

### Test 1: Access Services

```bash
# Frontend
curl http://localhost:5173 | head -20

# Keycloak
curl http://localhost:8080/health/ready

# Auth Service
curl http://localhost:8001/health | jq .

# Blog Service
curl http://localhost:8002/health | jq .
```

### Test 2: Check Pod Logs

```bash
# View logs for a specific pod
kubectl logs -l app=keycloak --tail=50

# Follow logs in real-time
kubectl logs -l app=frontend -f

# View logs from all containers in a pod
kubectl logs <pod-name> --all-containers=true
```

### Test 3: Inspect a Pod

```bash
# Get detailed information
kubectl describe pod <pod-name>

# Execute commands inside a pod
kubectl exec -it <pod-name> -- /bin/bash

# Example: Check if Keycloak can reach postgres
kubectl exec -it $(kubectl get pod -l app=keycloak -o name) -- \
  curl -s postgres:5432 || echo "Connection test"
```

### Test 4: Test the Complete Flow

1. Open http://localhost:5173 in your browser
2. Click "Get Started"
3. Register a new user
4. Create a blog post
5. Logout and login again
6. Verify post is still there

**It works exactly the same as Docker Compose!**

### Test 5: Scale the Frontend

```bash
# Scale to 3 replicas
kubectl scale deployment frontend --replicas=3

# Watch pods start
kubectl get pods -l app=frontend -w

# Check that all 3 are running
kubectl get pods -l app=frontend

# Test that load balancing works
for i in {1..10}; do
  curl -s http://localhost:5173 | grep -o "Loading" && echo " - Request $i"
done

# Scale back down
kubectl scale deployment frontend --replicas=1
```

### Test 6: Simulate Pod Failure

```bash
# Delete a pod
kubectl delete pod -l app=frontend

# Watch it automatically restart
kubectl get pods -l app=frontend -w

# The deployment ensures the desired number of replicas
```

### Test 7: Update an Image

```bash
# Make a change to frontend
echo "console.log('Updated!');" >> frontend/src/main.js

# Rebuild image
docker build -t blog-frontend:v2 ./frontend

# Load into kind
kind load docker-image blog-frontend:v2 --name blog-cluster

# Update deployment
kubectl set image deployment/frontend frontend=blog-frontend:v2

# Watch rolling update
kubectl rollout status deployment/frontend

# Rollback if needed
kubectl rollout undo deployment/frontend
```

### Test 8: Check Resource Usage

```bash
# Install metrics server (if not already)
kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml

# Wait a minute, then check
kubectl top pods
kubectl top nodes
```

---

## 19. Comparing Docker Compose vs Kubernetes

### When to Use Each

**Docker Compose:**
- ✅ Local development
- ✅ Simple applications
- ✅ Quick prototyping
- ✅ Learning/testing
- ❌ Production (usually)
- ❌ Multi-host deployments
- ❌ Auto-scaling needed

**Kubernetes:**
- ✅ Production deployments
- ✅ Complex applications
- ✅ High availability required
- ✅ Auto-scaling needed
- ✅ Multi-host clusters
- ❌ Local development (overkill)
- ❌ Simple applications

### Configuration Comparison

**Docker Compose:**
```yaml
services:
  keycloak:
    image: quay.io/keycloak/keycloak:24.0
    ports:
      - "8080:8080"
    environment:
      KEYCLOAK_ADMIN: admin
    depends_on:
      - postgres
```

**Kubernetes:**
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: keycloak
spec:
  replicas: 1
  selector:
    matchLabels:
      app: keycloak
  template:
    metadata:
      labels:
        app: keycloak
    spec:
      containers:
        - name: keycloak
          image: quay.io/keycloak/keycloak:24.0
          ports:
            - containerPort: 8080
          env:
            - name: KEYCLOAK_ADMIN
              value: "admin"
---
apiVersion: v1
kind: Service
metadata:
  name: keycloak
spec:
  selector:
    app: keycloak
  ports:
    - port: 8080
```

**Kubernetes is more verbose but more powerful.**

### Networking Differences

**Docker Compose:**
- Services communicate by service name
- Example: `http://keycloak:8080`
- Automatic DNS resolution
- Single network by default

**Kubernetes:**
- Pods communicate via Services
- Example: `http://keycloak:8080` (service name)
- DNS: `<service-name>.<namespace>.svc.cluster.local`
- Multiple networks (namespaces)

### Persistence Differences

**Docker Compose:**
```yaml
volumes:
  postgres_data:
```
- Named volumes
- Stored on host machine
- Survive container restarts
- Lost if volume deleted

**Kubernetes:**
```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: postgres-data
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 1Gi
```
- PersistentVolumes and PersistentVolumeClaims
- Can use cloud storage (EBS, GCE PD, etc.)
- Survive pod deletions
- Can be backed up/restored

---

## 20. FreeMarker Template Reference

Quick reference for customizing templates.

### Basic Syntax

```freemarker
<#-- Comments -->

${variable}                    <!-- Print variable -->
${variable!"default"}          <!-- With default value -->
${variable?html}               <!-- HTML escape -->
${variable?no_esc}             <!-- Don't escape (use with kcSanitize) -->

<#if condition>...</#if>       <!-- Conditional -->
<#if condition>
  ...
<#else>
  ...
</#if>

<#list items as item>          <!-- Loop -->
  ${item.name}
</#list>

<#include "file.ftl">          <!-- Include another file -->

<#macro name param1 param2>    <!-- Define macro -->
  ...
</#macro>

<@name param1="value" />       <!-- Call macro -->
```

### Common Checks

```freemarker
<#if variable??>                    <!-- Variable exists -->
<#if variable?has_content>          <!-- Not null and not empty -->
<#if variable?is_string>            <!-- Type check -->
<#if variable == "value">           <!-- Equality -->
<#if variable?size gt 0>            <!-- Size check -->
```

### Keycloak-Specific

```freemarker
${msg("key")}                       <!-- i18n message -->
${msg("key", param1, param2)}       <!-- With parameters -->

${url.loginAction}                  <!-- Form action URL -->
${url.registrationUrl}              <!-- Registration page -->
${url.loginResetCredentialsUrl}     <!-- Forgot password -->

${realm.displayName}                <!-- Realm name -->
${realm.registrationAllowed}        <!-- Boolean -->

${kcSanitize(html)?no_esc}          <!-- Sanitize HTML -->

${resourcesPath}                    <!-- /realms/blog/login-actions/... -->

<#if messagesPerField.existsError('username')>
  ${messagesPerField.get('username')}
</#if>
```

### Example: Custom Input Field

```freemarker
<#macro input name label type="text" required=false>
  <div class="form-group">
    <label for="${name}">
      ${label}
      <#if required><span class="required">*</span></#if>
    </label>
    <input 
      type="${type}" 
      id="${name}" 
      name="${name}"
      class="form-control <#if messagesPerField.existsError(name)>error</#if>"
      value="${(register.formData[name]!'')?html}"
      <#if required>required</#if>
    />
    <#if messagesPerField.existsError(name)>
      <div class="field-error">
        ${kcSanitize(messagesPerField.get(name))?no_esc}
      </div>
    </#if>
  </div>
</#macro>

<#-- Use it -->
<@input name="email" label="Email Address" type="email" required=true />
```

---

## 21. Email Templates

Customize the emails Keycloak sends.

### Email Template Structure

```
keycloak/themes/blog-theme/email/
├── theme.properties
├── html/
│   ├── email-verification.ftl
│   ├── password-reset.ftl
│   ├── email-update-confirmation.ftl
│   └── event-login_error.ftl
└── text/
    ├── email-verification.ftl
    └── password-reset.ftl
```

### Email Variables

All email templates receive:

| Variable | Description |
|----------|-------------|
| `realmName` | Realm display name |
| `user.firstName` | Recipient's first name |
| `user.lastName` | Recipient's last name |
| `user.email` | Recipient's email |
| `link` | Action link (verify email, reset password) |
| `linkExpiration` | Expiry time in minutes |
| `linkExpirationFormatter(linkExpiration)` | Human-readable expiry |

### Example: Email Verification

```freemarker
<#-- email/html/email-verification.ftl -->
<!DOCTYPE html>
<html>
<head>
  <meta charset="UTF-8" />
  <style>
    body { font-family: Arial, sans-serif; background: #f5f5f5; }
    .container { max-width: 600px; margin: 40px auto; background: white; padding: 40px; }
    .button { display: inline-block; padding: 12px 24px; background: #3B82F6; 
              color: white; text-decoration: none; border-radius: 4px; }
  </style>
</head>
<body>
  <div class="container">
    <h1>Welcome to ${realmName}!</h1>
    
    <p>Hi ${user.firstName!"there"},</p>
    
    <p>Please verify your email address by clicking the button below:</p>
    
    <p style="text-align: center;">
      <a href="${link}" class="button">Verify Email</a>
    </p>
    
    <p>This link expires in <strong>${linkExpirationFormatter(linkExpiration)}</strong>.</p>
    
    <p>If you didn't create an account, you can safely ignore this email.</p>
    
    <hr />
    <p style="color: #666; font-size: 12px;">
      If the button doesn't work, copy and paste this link:<br/>
      ${link}
    </p>
  </div>
</body>
</html>
```

### Testing Email Templates

**Option 1: Use Mailhog (Local SMTP Server)**

Add to docker-compose.yml:
```yaml
mailhog:
  image: mailhog/mailhog
  ports:
    - "1025:1025"  # SMTP
    - "8025:8025"  # Web UI
```

Configure in Keycloak:
1. Realm Settings → Email
2. Host: `mailhog`
3. Port: `1025`
4. From: `noreply@example.com`

View emails at: http://localhost:8025

**Option 2: Use a Real SMTP Server**

Configure Gmail, SendGrid, or other SMTP provider in Keycloak.

---

## 22. Troubleshooting Guide

Common issues and solutions.

### Docker Compose Issues

**Problem: Port already in use**
```bash
# Find what's using the port
lsof -i :8080

# Stop the process or change port in docker-compose.yml
```

**Problem: Keycloak won't start**
```bash
# Check logs
docker compose logs keycloak

# Common causes:
# - Can't connect to PostgreSQL (wait for it to be healthy)
# - Port conflict
# - Invalid realm import file

# Solution: Restart
docker compose restart keycloak
```

**Problem: Theme not loading**
```bash
# Verify theme is mounted
docker compose exec keycloak ls /opt/keycloak/themes/
# Should show: blog-theme

# Check theme.properties exists
docker compose exec keycloak ls /opt/keycloak/themes/blog-theme/login/
# Should show: theme.properties

# Restart Keycloak
docker compose restart keycloak
```

**Problem: Backend returns 401**
```bash
# Check if token is valid
echo $TOKEN | cut -d'.' -f2 | base64 -d 2>/dev/null | jq .

# Check token expiration
# If "exp" is in the past, token expired

# Check backend logs
docker compose logs auth-service

# Common causes:
# - Token expired
# - Wrong issuer (localhost vs keycloak)
# - Invalid signature
```

### Kubernetes Issues

**Problem: Pods not starting**
```bash
# Check pod status
kubectl get pods

# Describe pod for events
kubectl describe pod <pod-name>

# Common causes:
# - Image not found (did you load it into kind?)
# - Resource limits too low
# - ConfigMap/Secret missing
```

**Problem: Can't access services**
```bash
# Check if service exists
kubectl get svc

# Check if pods are running
kubectl get pods

# Check NodePort mapping
kubectl get svc <service-name> -o yaml | grep nodePort

# Test from inside cluster
kubectl run test --rm -it --image=curlimages/curl -- \
  curl http://keycloak:8080/health/ready
```

**Problem: Image pull errors**
```bash
# Make sure imagePullPolicy is set to Never
# for local images

# Verify image is loaded
docker exec -it blog-cluster-control-plane crictl images | grep blog

# Load image again
kind load docker-image <image-name>:latest --name blog-cluster
```

### Frontend Issues

**Problem: Blank page**
```bash
# Check browser console for errors
# Common causes:
# - Keycloak not accessible
# - CORS issues
# - JavaScript errors

# Check frontend logs
docker compose logs frontend
# or
kubectl logs -l app=frontend
```

**Problem: Infinite redirect loop**
```bash
# Check redirect URIs in Keycloak client settings
# Must match exactly: http://localhost:5173/*

# Check browser console for errors
```

### General Debugging

**Enable verbose logging:**

Keycloak:
```yaml
env:
  - name: KC_LOG_LEVEL
    value: "DEBUG"
```

FastAPI:
```python
import logging
logging.basicConfig(level=logging.DEBUG)
```

---

## 23. Production Considerations

Things to consider for production deployment.

### Security

**1. Use HTTPS Everywhere**
```yaml
# Keycloak
KC_HOSTNAME_STRICT_HTTPS: "true"

# Frontend
# Use a reverse proxy (nginx, Traefik) with SSL
```

**2. Secure Client Secrets**
```yaml
# Don't hardcode secrets
# Use Kubernetes Secrets or environment variables from secret manager

apiVersion: v1
kind: Secret
metadata:
  name: keycloak-secrets
type: Opaque
data:
  auth-service-secret: <base64-encoded>
```

**3. Enable Token Validation**
```python
# Re-enable issuer validation in production
payload = jwt.decode(
    token,
    keys,
    algorithms=["RS256"],
    issuer=f"{KEYCLOAK_URL}/realms/{KEYCLOAK_REALM}",
    options={"verify_aud": True, "verify_iss": True}
)
```

**4. Use Strong Passwords**
- Enforce password policies in Keycloak
- Require MFA for admin accounts
- Rotate secrets regularly

### Performance

**1. Enable Caching**
```yaml
# Keycloak
KC_SPI_THEME_CACHE_THEMES: "true"
KC_SPI_THEME_CACHE_TEMPLATES: "true"
```

**2. Use a CDN**
- Serve static assets (CSS, JS, images) from CDN
- Reduces load on Keycloak

**3. Scale Services**
```bash
# Kubernetes
kubectl scale deployment frontend --replicas=3
kubectl scale deployment auth-service --replicas=2
```

**4. Use Connection Pooling**
```python
# PostgreSQL connection pooling
DATABASE_URL = "postgresql://...?pool_size=20&max_overflow=10"
```

### Monitoring

**1. Health Checks**
```yaml
# Kubernetes
livenessProbe:
  httpGet:
    path: /health
    port: 8001
  initialDelaySeconds: 30
  periodSeconds: 10

readinessProbe:
  httpGet:
    path: /health/ready
    port: 8001
  initialDelaySeconds: 5
  periodSeconds: 5
```

**2. Logging**
- Centralized logging (ELK, Loki)
- Structured logs (JSON format)
- Log levels (DEBUG in dev, INFO in prod)

**3. Metrics**
- Prometheus for metrics collection
- Grafana for visualization
- Alert on errors, high latency, etc.

### Backup and Recovery

**1. Database Backups**
```bash
# PostgreSQL backup
kubectl exec -it <postgres-pod> -- \
  pg_dump -U keycloak keycloak > backup.sql

# Restore
kubectl exec -i <postgres-pod> -- \
  psql -U keycloak keycloak < backup.sql
```

**2. Keycloak Realm Export**
```bash
# Export realm configuration
kubectl exec -it <keycloak-pod> -- \
  /opt/keycloak/bin/kc.sh export \
  --realm blog --file /tmp/blog-realm.json

# Copy out
kubectl cp <keycloak-pod>:/tmp/blog-realm.json ./blog-realm.json
```

### High Availability

**1. Multiple Replicas**
```yaml
spec:
  replicas: 3  # Run 3 instances
```

**2. Pod Disruption Budgets**
```yaml
apiVersion: policy/v1
kind: PodDisruptionBudget
metadata:
  name: keycloak-pdb
spec:
  minAvailable: 2
  selector:
    matchLabels:
      app: keycloak
```

**3. Database Replication**
- Use managed database (RDS, Cloud SQL)
- Or set up PostgreSQL replication

---

## Conclusion

Congratulations! You've learned:

✅ How to deploy Keycloak with Docker Compose
✅ How to customize themes
✅ How to build microservices with JWT validation
✅ How to implement service-to-service authentication
✅ How to integrate a Vue frontend with Keycloak
✅ How to deploy to Kubernetes
✅ How to test everything manually

### Next Steps

1. **Customize further**: Add your own branding, colors, and features
2. **Add more services**: Expand the microservices architecture
3. **Deploy to cloud**: Try AWS EKS, Google GKE, or Azure AKS
4. **Add monitoring**: Set up Prometheus and Grafana
5. **Implement CI/CD**: Automate deployments with GitHub Actions

### Resources

- [Keycloak Documentation](https://www.keycloak.org/documentation)
- [FreeMarker Manual](https://freemarker.apache.org/docs/)
- [FastAPI Documentation](https://fastapi.tiangolo.com/)
- [Vue 3 Documentation](https://vuejs.org/)
- [Kubernetes Documentation](https://kubernetes.io/docs/)

### Get Help

- Check `MANUAL_TEST_CHECKLIST.md` for testing steps
- Check `TEST_RESULTS.md` for known issues
- Check `guide-reference.md` for the original detailed guide
- Run `./test-docker-compose.sh` or `./test-kind.sh` for automated tests

---

**Happy coding!** 🚀
