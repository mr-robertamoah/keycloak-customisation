# Keycloak Customisation Guide
### Login, Registration & Email Templates — with Vue, FastAPI & Docker/kind

> **Who this is for:** Complete beginners to Keycloak who want a working, real-world reference that covers theme customisation end-to-end, wired into a full-stack blog application.

---

## Table of Contents

1. [What is Keycloak?](#1-what-is-keycloak)
2. [Architecture Overview](#2-architecture-overview)
3. [Prerequisites & Tooling](#3-prerequisites--tooling)
4. [Project Structure](#4-project-structure)
5. [Running Keycloak Locally with Docker](#5-running-keycloak-locally-with-docker)
6. [Keycloak Concepts You Must Know](#6-keycloak-concepts-you-must-know)
7. [Theme System Deep Dive](#7-theme-system-deep-dive)
8. [Building a Custom Login Theme](#8-building-a-custom-login-theme)
9. [Building a Custom Registration Theme](#9-building-a-custom-registration-theme)
10. [Building Custom Email Templates](#10-building-custom-email-templates)
11. [FreeMarker Syntax Reference](#11-freemarker-syntax-reference)
12. [The FastAPI Backend — Auth Service](#12-the-fastapi-backend--auth-service)
13. [The FastAPI Backend — Blog Service](#13-the-fastapi-backend--blog-service)
14. [Service-to-Service Communication](#14-service-to-service-communication)
15. [The Vue Frontend](#15-the-vue-frontend)
16. [Deploying to kind (Kubernetes)](#16-deploying-to-kind-kubernetes)
17. [Testing Your Theme Changes](#17-testing-your-theme-changes)
18. [Common Errors & Fixes](#18-common-errors--fixes)
19. [Going Further](#19-going-further)

---

## 1. What is Keycloak?

Keycloak is an open-source **Identity and Access Management (IAM)** server. Instead of writing login, registration, password-reset, and session management logic yourself, you delegate it to Keycloak and integrate with it via standard protocols (OpenID Connect / OAuth 2.0 / SAML).

**Key ideas at a glance:**

- **Realm** — An isolated tenant. Think of it as your app's own "universe" of users and settings. You never use the `master` realm for your apps.
- **Client** — A registered application that Keycloak knows about (your Vue app, your FastAPI service, etc.).
- **User** — Someone with credentials stored in the realm.
- **Token** — A signed JWT that proves who a user is and what they are allowed to do.
- **Theme** — The HTML/CSS/FreeMarker templates Keycloak renders for login, registration, account management, and emails.

---

## 2. Architecture Overview

```
┌─────────────────────────────────────────────────────────────────┐
│                         Browser                                  │
│                    Vue SPA (port 5173)                           │
└───────────────────────────┬─────────────────────────────────────┘
                            │  OIDC redirect / API calls
          ┌─────────────────┼─────────────────┐
          │                 │                 │
          ▼                 ▼                 ▼
   ┌─────────────┐  ┌──────────────┐  ┌─────────────────┐
   │  Keycloak   │  │  Auth Service│  │   Blog Service  │
   │  (port 8080)│  │  FastAPI     │  │   FastAPI       │
   │             │  │  (port 8001) │  │   (port 8002)   │
   └─────────────┘  └──────┬───────┘  └────────┬────────┘
                           │  service-to-service│
                           │  (token exchange)  │
                           └────────────────────┘
                                     │
                              ┌──────▼──────┐
                              │  PostgreSQL  │
                              │  (port 5432) │
                              └─────────────┘
```

**What each piece does:**

- **Vue SPA** — The blog frontend. Uses the Keycloak JS adapter to initiate login and carry the JWT in API calls.
- **Keycloak** — Handles all authentication. Serves your custom login/registration/email templates.
- **Auth Service** — A FastAPI service that validates tokens, exposes user profile endpoints, and calls the Blog Service on behalf of users.
- **Blog Service** — A FastAPI service that manages posts. It trusts calls from the Auth Service via a shared service account token.
- **PostgreSQL** — Shared database (separate schemas for each service).

---

## 3. Prerequisites & Tooling

Install the following before proceeding.

| Tool | Version | Purpose |
|---|---|---|
| Docker Desktop | ≥ 24 | Containers |
| kind | ≥ 0.22 | Local Kubernetes cluster |
| kubectl | ≥ 1.29 | Kubernetes CLI |
| Python | ≥ 3.11 | FastAPI services |
| Node.js | ≥ 20 | Vue frontend |
| httpie or curl | any | API testing |

**Verify everything is installed:**

```bash
docker --version
kind --version
kubectl version --client
python --version
node --version
```

---

## 4. Project Structure

```
keycloak-customisation/
├── docker-compose.yml          # Local dev stack
├── kind-config.yaml            # kind cluster config
├── keycloak/
│   └── themes/
│       └── blog-theme/         # ← your custom theme lives here
│           ├── login/
│           │   ├── theme.properties
│           │   ├── resources/
│           │   │   ├── css/
│           │   │   │   └── styles.css
│           │   │   └── img/
│           │   │       └── logo.svg
│           │   └── templates/
│           │       ├── login.ftl
│           │       ├── register.ftl
│           │       ├── login-reset-password.ftl
│           │       ├── login-update-password.ftl
│           │       ├── error.ftl
│           │       └── info.ftl
│           └── email/
│               ├── theme.properties
│               ├── html/
│               │   ├── email-verification.ftl
│               │   ├── password-reset.ftl
│               │   └── welcome.ftl
│               └── text/
│                   ├── email-verification.ftl
│                   └── password-reset.ftl
├── services/
│   ├── auth-service/
│   │   ├── Dockerfile
│   │   ├── requirements.txt
│   │   └── app/
│   │       ├── main.py
│   │       ├── auth.py
│   │       └── routers/
│   │           └── users.py
│   └── blog-service/
│       ├── Dockerfile
│       ├── requirements.txt
│       └── app/
│           ├── main.py
│           ├── auth.py
│           └── routers/
│               └── posts.py
└── frontend/
    ├── package.json
    └── src/
        ├── main.js
        ├── keycloak.js
        ├── App.vue
        └── views/
            ├── Home.vue
            ├── Login.vue
            └── Blog.vue
```

Create the skeleton now:

```bash
mkdir -p keycloak-customisation/keycloak/themes/blog-theme/{login/{resources/{css,img},templates},email/{html,text}}
mkdir -p keycloak-customisation/services/{auth-service/app/routers,blog-service/app/routers}
mkdir -p keycloak-customisation/frontend/src/views
cd keycloak-customisation
```

---

## 5. Running Keycloak Locally with Docker

### 5.1 docker-compose.yml

Create `docker-compose.yml` in the project root:

```yaml
version: "3.9"

services:

  postgres:
    image: postgres:16
    environment:
      POSTGRES_DB: keycloak
      POSTGRES_USER: keycloak
      POSTGRES_PASSWORD: keycloak_secret
    volumes:
      - postgres_data:/var/lib/postgresql/data
      - ./init.sql:/docker-entrypoint-initdb.d/init.sql
    ports:
      - "5432:5432"
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U keycloak"]
      interval: 5s
      timeout: 5s
      retries: 5

  keycloak:
    image: quay.io/keycloak/keycloak:24.0
    command: start-dev --import-realm
    environment:
      KC_DB: postgres
      KC_DB_URL: jdbc:postgresql://postgres:5432/keycloak
      KC_DB_USERNAME: keycloak
      KC_DB_PASSWORD: keycloak_secret
      KEYCLOAK_ADMIN: admin
      KEYCLOAK_ADMIN_PASSWORD: admin
      KC_HTTP_PORT: 8080
      # Tells Keycloak where to look for themes
      KC_SPI_THEME_STATIC_MAX_AGE: -1
      KC_SPI_THEME_CACHE_THEMES: "false"
      KC_SPI_THEME_CACHE_TEMPLATES: "false"
    volumes:
      # Mount your custom theme directory into the Keycloak themes directory
      - ./keycloak/themes/blog-theme:/opt/keycloak/themes/blog-theme
    ports:
      - "8080:8080"
    depends_on:
      postgres:
        condition: service_healthy

  auth-service:
    build: ./services/auth-service
    environment:
      KEYCLOAK_URL: http://keycloak:8080
      KEYCLOAK_REALM: blog
      KEYCLOAK_CLIENT_ID: auth-service
      KEYCLOAK_CLIENT_SECRET: auth-service-secret
      BLOG_SERVICE_URL: http://blog-service:8002
      DATABASE_URL: postgresql://keycloak:keycloak_secret@postgres:5432/auth_db
    ports:
      - "8001:8001"
    depends_on:
      - keycloak

  blog-service:
    build: ./services/blog-service
    environment:
      KEYCLOAK_URL: http://keycloak:8080
      KEYCLOAK_REALM: blog
      KEYCLOAK_CLIENT_ID: blog-service
      KEYCLOAK_CLIENT_SECRET: blog-service-secret
      DATABASE_URL: postgresql://keycloak:keycloak_secret@postgres:5432/blog_db
    ports:
      - "8002:8002"
    depends_on:
      - keycloak

volumes:
  postgres_data:
```

### 5.2 Database Init Script

Create `init.sql`:

```sql
-- Create separate databases for each service
CREATE DATABASE auth_db;
CREATE DATABASE blog_db;
GRANT ALL PRIVILEGES ON DATABASE auth_db TO keycloak;
GRANT ALL PRIVILEGES ON DATABASE blog_db TO keycloak;
```

### 5.3 Start the Stack

```bash
docker compose up -d postgres
# Wait for postgres to be healthy, then start keycloak
docker compose up -d keycloak
# Wait ~30 seconds for Keycloak to boot
docker compose up -d
```

### 5.4 Configure Keycloak via the Admin UI

Open `http://localhost:8080` and log in with `admin` / `admin`.

**Create a Realm:**
1. Click the realm dropdown (top left) → **Create Realm**
2. Name it `blog` → **Create**

**Create Clients:**

For the Vue frontend (`blog-frontend`):
1. Clients → **Create client**
2. Client ID: `blog-frontend`
3. Client type: `OpenID Connect`
4. Next → Enable **Standard flow** and **Implicit flow**
5. Valid redirect URIs: `http://localhost:5173/*`
6. Valid post logout redirect URIs: `http://localhost:5173`
7. Web origins: `http://localhost:5173`
8. Save

For the Auth Service (`auth-service`):
1. Clients → **Create client**
2. Client ID: `auth-service`
3. Client type: `OpenID Connect`
4. Next → Enable **Service accounts roles** (this is Client Credentials grant)
5. Save
6. Go to **Credentials** tab → copy the client secret, put it in your `.env`

For the Blog Service (`blog-service`):
1. Same as auth-service but Client ID: `blog-service`

**Apply your custom theme (you'll do this after building it in sections 8–10):**
1. Realm Settings → **Themes** tab
2. Login theme: `blog-theme`
3. Email theme: `blog-theme`
4. Save

---

## 6. Keycloak Concepts You Must Know

### 6.1 Flows

Keycloak uses **Authentication Flows** — configurable pipelines of steps a user goes through. Examples: Browser Flow (login), Registration Flow, Reset Credentials Flow. Each flow maps to different template files.

### 6.2 The Token Trio

| Token | Lifespan | Purpose |
|---|---|---|
| **Access Token** | Short (5 min) | Passed as `Authorization: Bearer <token>` to APIs |
| **Refresh Token** | Long (30 min) | Used to get a new access token without re-login |
| **ID Token** | Short | Contains user identity claims for the frontend |

### 6.3 OIDC vs OAuth 2.0

- **OAuth 2.0** — Authorisation framework. "App X can do Y on behalf of user Z."
- **OpenID Connect (OIDC)** — A layer on top of OAuth 2.0 that adds identity. Your app learns *who* the user is via the `id_token`.

### 6.4 PKCE (Proof Key for Code Exchange)

SPAs use the **Authorization Code Flow with PKCE** because they can't safely store a client secret. Keycloak handles the PKCE challenge/verifier exchange automatically when configured correctly.

---

## 7. Theme System Deep Dive

### 7.1 Theme Types

Keycloak has five theme types. You will mostly use two:

| Type | What it controls | Key templates |
|---|---|---|
| `login` | Login, register, password reset, OTP, error pages | `login.ftl`, `register.ftl`, etc. |
| `account` | User self-service account console | `account/index.ftl`, etc. |
| `admin` | Admin UI | (rarely customised) |
| `email` | All emails Keycloak sends | `email-verification.ftl`, `password-reset.ftl`, etc. |
| `welcome` | Keycloak's own welcome page | (rarely customised) |

### 7.2 Theme Inheritance

Every theme can declare a **parent**. Keycloak looks up the override chain:

```
your-theme → parent-theme → base (built-in)
```

If Keycloak can't find `register.ftl` in your theme, it falls back to the parent, then to `base`. This means you only need to override the files you actually want to change.

In `theme.properties` you declare the parent:

```properties
parent=keycloak   # inherit from the default Keycloak theme
```

Or to start completely fresh:

```properties
parent=base       # inherit from the minimal base, no Keycloak chrome
```

### 7.3 Template Engine: FreeMarker

Keycloak templates use **Apache FreeMarker** (`.ftl` files). FreeMarker is a Java-based templating language. Think of it like Jinja2 for Java.

**FreeMarker at a glance:**

```freemarker
${variable}                  <!-- print a variable -->
${variable!"default"}        <!-- print with a default if null -->
<#if condition>...</#if>     <!-- conditional -->
<#list items as item>...</#list>  <!-- loop -->
<#include "file.ftl">        <!-- include another file -->
<#macro name>...</#macro>    <!-- define a macro (reusable block) -->
<@name />                    <!-- call a macro -->
```

### 7.4 What Keycloak Passes to Templates

Every `.ftl` file receives a rich context object from Keycloak. The most important variables are:

| Variable | Type | Description |
|---|---|---|
| `url` | Object | URLs for actions (login, register, reset password, etc.) |
| `realm` | Object | Realm settings (name, SMTP config, etc.) |
| `client` | Object | The client that initiated the flow |
| `locale` | String | Active locale (e.g., `en`) |
| `properties` | Map | All key-value pairs from `theme.properties` |
| `msg("key")` | Function | Looks up an i18n message |
| `kcSanitize(html)` | Function | Sanitises HTML for safe output |
| `login` | Object | Login-specific data (username, rememberMe, etc.) |
| `register` | Object | Registration form data |
| `messagesPerField` | Object | Per-field validation errors |

---

## 8. Building a Custom Login Theme

### 8.1 theme.properties

Create `keycloak/themes/blog-theme/login/theme.properties`:

```properties
# Inherit from Keycloak's default theme so we only override what we need
parent=keycloak

# Import styles from the parent AND add our own
styles=css/login.css css/styles.css

# Import scripts — we keep the parent's
scripts=

# Custom properties accessible in templates via ${properties.variableName}
logoUrl=${resourcesPath}/img/logo.svg
brandName=The Blog
primaryColor=#3B82F6
```

**`${resourcesPath}`** is a built-in variable Keycloak injects — it resolves to the full URL of your theme's `resources/` directory. Always use it instead of hardcoding paths.

### 8.2 styles.css

Create `keycloak/themes/blog-theme/login/resources/css/styles.css`:

```css
/* ─── Reset & Variables ─── */
:root {
  --brand-primary: #3B82F6;
  --brand-primary-hover: #2563EB;
  --brand-bg: #F8FAFF;
  --brand-card: #FFFFFF;
  --brand-text: #1E293B;
  --brand-muted: #64748B;
  --brand-border: #E2E8F0;
  --brand-error: #EF4444;
  --brand-success: #10B981;
  --radius: 0.5rem;
  --shadow: 0 4px 24px rgba(59, 130, 246, 0.08);
}

body {
  background: var(--brand-bg);
  font-family: 'Inter', system-ui, -apple-system, sans-serif;
  color: var(--brand-text);
  min-height: 100vh;
  display: flex;
  align-items: center;
  justify-content: center;
  margin: 0;
}

/* ─── Card wrapper ─── */
#kc-container {
  background: var(--brand-card);
  border-radius: var(--radius);
  box-shadow: var(--shadow);
  max-width: 440px;
  width: 100%;
  padding: 2.5rem;
}

/* ─── Logo ─── */
.brand-logo {
  display: block;
  margin: 0 auto 1.5rem;
  height: 48px;
}

.brand-title {
  text-align: center;
  font-size: 1.5rem;
  font-weight: 700;
  margin-bottom: 0.5rem;
  color: var(--brand-text);
}

.brand-subtitle {
  text-align: center;
  color: var(--brand-muted);
  font-size: 0.9rem;
  margin-bottom: 2rem;
}

/* ─── Form fields ─── */
.form-group {
  margin-bottom: 1.25rem;
}

.form-group label {
  display: block;
  font-size: 0.875rem;
  font-weight: 500;
  margin-bottom: 0.375rem;
  color: var(--brand-text);
}

.form-control {
  width: 100%;
  padding: 0.625rem 0.875rem;
  border: 1.5px solid var(--brand-border);
  border-radius: var(--radius);
  font-size: 0.9375rem;
  transition: border-color 0.15s, box-shadow 0.15s;
  box-sizing: border-box;
  background: #fff;
  color: var(--brand-text);
}

.form-control:focus {
  outline: none;
  border-color: var(--brand-primary);
  box-shadow: 0 0 0 3px rgba(59, 130, 246, 0.15);
}

.form-control.error {
  border-color: var(--brand-error);
}

/* ─── Field-level errors ─── */
.field-error {
  color: var(--brand-error);
  font-size: 0.8rem;
  margin-top: 0.3rem;
}

/* ─── Alert (top-level messages) ─── */
.alert {
  border-radius: var(--radius);
  padding: 0.75rem 1rem;
  margin-bottom: 1.25rem;
  font-size: 0.875rem;
}
.alert-error   { background: #FEF2F2; color: #B91C1C; border: 1px solid #FECACA; }
.alert-warning { background: #FFFBEB; color: #92400E; border: 1px solid #FDE68A; }
.alert-success { background: #F0FDF4; color: #166534; border: 1px solid #BBF7D0; }
.alert-info    { background: #EFF6FF; color: #1D4ED8; border: 1px solid #BFDBFE; }

/* ─── Primary button ─── */
.btn-primary {
  width: 100%;
  padding: 0.75rem;
  background: var(--brand-primary);
  color: #fff;
  border: none;
  border-radius: var(--radius);
  font-size: 1rem;
  font-weight: 600;
  cursor: pointer;
  transition: background 0.15s;
  margin-top: 0.5rem;
}
.btn-primary:hover { background: var(--brand-primary-hover); }

/* ─── Links ─── */
.kc-links {
  text-align: center;
  margin-top: 1.25rem;
  font-size: 0.875rem;
  color: var(--brand-muted);
}
.kc-links a {
  color: var(--brand-primary);
  text-decoration: none;
  font-weight: 500;
}
.kc-links a:hover { text-decoration: underline; }

/* ─── Remember me / checkbox ─── */
.checkbox-row {
  display: flex;
  align-items: center;
  gap: 0.5rem;
  margin-bottom: 1rem;
  font-size: 0.875rem;
  color: var(--brand-muted);
}
```

### 8.3 login.ftl — The Login Template

Create `keycloak/themes/blog-theme/login/templates/login.ftl`:

```freemarker
<#-- 
  login.ftl — custom login page for blog-theme
  Keycloak injects these variables into every login template:
    - url         : URLs object (loginAction, registrationUrl, etc.)
    - realm       : Realm config (name, registrationAllowed, rememberMe, etc.)
    - login       : Login state (username, rememberMe)
    - auth         : Social/identity provider links
    - registrationDisabled : boolean
    - messagesPerField     : per-field error helper
    - message              : top-level message object (type, summary)
    - properties           : all theme.properties values
-->
<!DOCTYPE html>
<html lang="${locale.currentLanguageTag}">
<head>
  <meta charset="UTF-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1.0" />
  <title>${msg("loginTitle", realm.displayName)}</title>

  <#-- Load Google Fonts (optional — remove if offline) -->
  <link rel="preconnect" href="https://fonts.googleapis.com">
  <link href="https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700&display=swap" rel="stylesheet">

  <#-- Load our custom CSS via ${resourcesPath} which Keycloak resolves at runtime -->
  <link rel="stylesheet" href="${resourcesPath}/css/styles.css" />
</head>
<body>

<div id="kc-container">

  <#-- ── Brand header ── -->
  <img class="brand-logo"
       src="${properties.logoUrl}"
       alt="${properties.brandName!realm.displayName}" />
  <h1 class="brand-title">${properties.brandName!realm.displayName}</h1>
  <p class="brand-subtitle">${msg("loginTitleHtml", realm.displayName)}</p>

  <#-- ── Top-level alert messages ──
       message.type can be: error | warning | success | info              -->
  <#if message?has_content>
    <div class="alert alert-${message.type}">
      ${kcSanitize(message.summary)?no_esc}
    </div>
  </#if>

  <#-- ── Login form ── -->
  <form action="${url.loginAction}" method="post">

    <#-- Hidden field required by Keycloak for CSRF -->
    <input type="hidden" name="credentialId"
           value="<#if auth.selectedCredential?has_content>${auth.selectedCredential}</#if>" />

    <#-- Username / Email field -->
    <div class="form-group">
      <label for="username">
        <#if !realm.loginWithEmailAllowed>
          ${msg("username")}
        <#elseif !realm.registrationEmailAsUsername>
          ${msg("usernameOrEmail")}
        <#else>
          ${msg("email")}
        </#if>
      </label>
      <input
        type="text"
        id="username"
        name="username"
        class="form-control <#if messagesPerField.existsError('username','password')>error</#if>"
        value="${(login.username!'')?html}"
        autofocus
        autocomplete="username"
      />
      <#-- Per-field error for username -->
      <#if messagesPerField.existsError('username')>
        <div class="field-error">
          ${kcSanitize(messagesPerField.get('username'))?no_esc}
        </div>
      </#if>
    </div>

    <#-- Password field -->
    <div class="form-group">
      <label for="password">${msg("password")}</label>
      <input
        type="password"
        id="password"
        name="password"
        class="form-control <#if messagesPerField.existsError('username','password')>error</#if>"
        autocomplete="current-password"
      />
      <#if messagesPerField.existsError('password')>
        <div class="field-error">
          ${kcSanitize(messagesPerField.get('password'))?no_esc}
        </div>
      </#if>
    </div>

    <#-- Remember me + Forgot password row -->
    <div style="display:flex; justify-content:space-between; align-items:center; margin-bottom:1rem;">
      <#if realm.rememberMe && !usernameHidden??>
        <label class="checkbox-row">
          <input type="checkbox" name="rememberMe"
            <#if login.rememberMe??>checked</#if> />
          ${msg("rememberMe")}
        </label>
      <#else>
        <span></span>
      </#if>

      <#if realm.resetPasswordAllowed>
        <a href="${url.loginResetCredentialsUrl}" style="font-size:0.875rem; color:var(--brand-primary);">
          ${msg("doForgotPassword")}
        </a>
      </#if>
    </div>

    <#-- Submit button -->
    <input class="btn-primary" type="submit" value="${msg("doLogIn")}" />
  </form>

  <#-- ── Registration link ── -->
  <#if realm.password && realm.registrationAllowed && !registrationDisabled??>
    <div class="kc-links">
      ${msg("noAccount")} <a href="${url.registrationUrl}">${msg("doRegister")}</a>
    </div>
  </#if>

  <#-- ── Social / Identity Provider buttons ──
       Only rendered if the realm has any configured identity providers -->
  <#if auth.showSocialProviders()>
    <hr style="margin: 1.5rem 0; border-color: var(--brand-border);" />
    <p style="text-align:center; font-size:0.875rem; color:var(--brand-muted);">
      ${msg("identity-provider-login-label")}
    </p>
    <#list auth.providers as provider>
      <a href="${provider.loginUrl}"
         style="display:block; text-align:center; padding:0.6rem; margin-bottom:0.5rem;
                border:1.5px solid var(--brand-border); border-radius:var(--radius);
                text-decoration:none; color:var(--brand-text); font-size:0.9rem;">
        ${provider.displayName}
      </a>
    </#list>
  </#if>

</div><!-- /#kc-container -->

</body>
</html>
```

---

## 9. Building a Custom Registration Theme

### 9.1 register.ftl

Create `keycloak/themes/blog-theme/login/templates/register.ftl`:

```freemarker
<#--
  register.ftl — Custom registration page
  Extra variables available on this page (on top of the login set):
    - register         : Object with form field values (firstName, lastName, email, username)
    - passwordRequired : boolean — whether password fields are shown
    - recaptchaRequired: boolean — whether reCAPTCHA is enabled
    - recaptchaSiteKey : string  — public reCAPTCHA key
-->
<!DOCTYPE html>
<html lang="${locale.currentLanguageTag}">
<head>
  <meta charset="UTF-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1.0" />
  <title>${msg("registerTitle")}</title>
  <link rel="preconnect" href="https://fonts.googleapis.com">
  <link href="https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700&display=swap" rel="stylesheet">
  <link rel="stylesheet" href="${resourcesPath}/css/styles.css" />
</head>
<body>

<div id="kc-container">

  <img class="brand-logo" src="${properties.logoUrl}" alt="${properties.brandName!realm.displayName}" />
  <h1 class="brand-title">Create your account</h1>
  <p class="brand-subtitle">Join ${properties.brandName!realm.displayName} today</p>

  <#if message?has_content>
    <div class="alert alert-${message.type}">
      ${kcSanitize(message.summary)?no_esc}
    </div>
  </#if>

  <#--
    The form action must point to url.registrationAction — never hardcode it.
    Keycloak signs this URL with a session code and CSRF token.
  -->
  <form action="${url.registrationAction}" method="post">

    <#-- Two-column row for names -->
    <div style="display:grid; grid-template-columns:1fr 1fr; gap:1rem;">

      <div class="form-group">
        <label for="firstName">${msg("firstName")}</label>
        <input
          type="text"
          id="firstName"
          name="firstName"
          class="form-control <#if messagesPerField.existsError('firstName')>error</#if>"
          value="${(register.formData.firstName!'')?html}"
          autocomplete="given-name"
        />
        <#if messagesPerField.existsError('firstName')>
          <div class="field-error">${kcSanitize(messagesPerField.get('firstName'))?no_esc}</div>
        </#if>
      </div>

      <div class="form-group">
        <label for="lastName">${msg("lastName")}</label>
        <input
          type="text"
          id="lastName"
          name="lastName"
          class="form-control <#if messagesPerField.existsError('lastName')>error</#if>"
          value="${(register.formData.lastName!'')?html}"
          autocomplete="family-name"
        />
        <#if messagesPerField.existsError('lastName')>
          <div class="field-error">${kcSanitize(messagesPerField.get('lastName'))?no_esc}</div>
        </#if>
      </div>

    </div>

    <#-- Email -->
    <div class="form-group">
      <label for="email">${msg("email")}</label>
      <input
        type="email"
        id="email"
        name="email"
        class="form-control <#if messagesPerField.existsError('email')>error</#if>"
        value="${(register.formData.email!'')?html}"
        autocomplete="email"
      />
      <#if messagesPerField.existsError('email')>
        <div class="field-error">${kcSanitize(messagesPerField.get('email'))?no_esc}</div>
      </#if>
    </div>

    <#-- Username (only shown if email-as-username is disabled) -->
    <#if !realm.registrationEmailAsUsername>
      <div class="form-group">
        <label for="username">${msg("username")}</label>
        <input
          type="text"
          id="username"
          name="username"
          class="form-control <#if messagesPerField.existsError('username')>error</#if>"
          value="${(register.formData.username!'')?html}"
          autocomplete="username"
        />
        <#if messagesPerField.existsError('username')>
          <div class="field-error">${kcSanitize(messagesPerField.get('username'))?no_esc}</div>
        </#if>
      </div>
    </#if>

    <#-- Password fields (only shown when passwordRequired is true) -->
    <#if passwordRequired??>
      <div class="form-group">
        <label for="password">${msg("password")}</label>
        <input
          type="password"
          id="password"
          name="password"
          class="form-control <#if messagesPerField.existsError('password','password-confirm')>error</#if>"
          autocomplete="new-password"
        />
        <#if messagesPerField.existsError('password')>
          <div class="field-error">${kcSanitize(messagesPerField.get('password'))?no_esc}</div>
        </#if>
      </div>

      <div class="form-group">
        <label for="password-confirm">${msg("passwordConfirm")}</label>
        <input
          type="password"
          id="password-confirm"
          name="password-confirm"
          class="form-control <#if messagesPerField.existsError('password-confirm')>error</#if>"
          autocomplete="new-password"
        />
        <#if messagesPerField.existsError('password-confirm')>
          <div class="field-error">${kcSanitize(messagesPerField.get('password-confirm'))?no_esc}</div>
        </#if>
      </div>
    </#if>

    <#-- reCAPTCHA — only rendered when enabled in realm settings -->
    <#if recaptchaRequired??>
      <div style="margin-bottom:1.25rem;">
        <div class="g-recaptcha" data-size="normal" data-sitekey="${recaptchaSiteKey}"></div>
      </div>
    </#if>

    <input class="btn-primary" type="submit" value="${msg("doRegister")}" />
  </form>

  <div class="kc-links">
    Already have an account? <a href="${url.loginUrl}">${msg("backToLogin")}</a>
  </div>

</div>

<#if recaptchaRequired??>
  <script src="https://www.google.com/recaptcha/api.js" async defer></script>
</#if>
</body>
</html>
```

### 9.2 login-reset-password.ftl (Forgot Password page)

Create `keycloak/themes/blog-theme/login/templates/login-reset-password.ftl`:

```freemarker
<!DOCTYPE html>
<html lang="${locale.currentLanguageTag}">
<head>
  <meta charset="UTF-8" />
  <title>${msg("emailForgotTitle")}</title>
  <link rel="preconnect" href="https://fonts.googleapis.com">
  <link href="https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700&display=swap" rel="stylesheet">
  <link rel="stylesheet" href="${resourcesPath}/css/styles.css" />
</head>
<body>
<div id="kc-container">

  <img class="brand-logo" src="${properties.logoUrl}" alt="${properties.brandName!realm.displayName}" />
  <h1 class="brand-title">Reset your password</h1>
  <p class="brand-subtitle">
    Enter your email and we&rsquo;ll send you a reset link.
  </p>

  <#if message?has_content>
    <div class="alert alert-${message.type}">
      ${kcSanitize(message.summary)?no_esc}
    </div>
  </#if>

  <form action="${url.loginAction}" method="post">
    <div class="form-group">
      <label for="username">
        <#if !realm.loginWithEmailAllowed>
          ${msg("username")}
        <#elseif !realm.registrationEmailAsUsername>
          ${msg("usernameOrEmail")}
        <#else>
          ${msg("email")}
        </#if>
      </label>
      <input
        type="text"
        id="username"
        name="username"
        class="form-control"
        autofocus
        value="${(auth.attemptedUsername!'')?html}"
      />
    </div>
    <input class="btn-primary" type="submit" value="${msg("doSubmit")}" />
  </form>

  <div class="kc-links">
    <a href="${url.loginUrl}">&larr; ${msg("backToLogin")}</a>
  </div>

</div>
</body>
</html>
```

### 9.3 error.ftl

Create `keycloak/themes/blog-theme/login/templates/error.ftl`:

```freemarker
<!DOCTYPE html>
<html lang="${locale.currentLanguageTag}">
<head>
  <meta charset="UTF-8" />
  <title>${msg("errorTitle")}</title>
  <link rel="preconnect" href="https://fonts.googleapis.com">
  <link href="https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700&display=swap" rel="stylesheet">
  <link rel="stylesheet" href="${resourcesPath}/css/styles.css" />
</head>
<body>
<div id="kc-container">
  <h1 class="brand-title" style="color:#EF4444;">${msg("errorTitle")}</h1>
  <div class="alert alert-error">${kcSanitize(message.summary)?no_esc}</div>
  <#if skipLink??>
    <p style="text-align:center;">
      <a href="${url.loginRestartFlowUrl}">Restart</a>
    </p>
  </#if>
</div>
</body>
</html>
```

---

## 10. Building Custom Email Templates

Email templates live under `email/html/` (rich HTML emails) and `email/text/` (plain-text fallbacks). Keycloak sends both, and email clients choose which to render.

### 10.1 email/theme.properties

Create `keycloak/themes/blog-theme/email/theme.properties`:

```properties
parent=base
```

### 10.2 Email Template Variables

All email templates receive:

| Variable | Description |
|---|---|
| `realmName` | The realm's display name |
| `user` | Object with `firstName`, `lastName`, `username`, `email` |
| `link` | The action link (verify email, reset password, etc.) |
| `linkExpiration` | Expiry time in minutes |
| `linkExpirationFormatter(linkExpiration)` | Human-readable expiry string |

### 10.3 HTML Email: email-verification.ftl

Create `keycloak/themes/blog-theme/email/html/email-verification.ftl`:

```freemarker
<#--
  Keycloak injects:
    realmName       - realm display name
    user.firstName  - recipient's first name
    link            - the verification URL
    linkExpiration  - expiry in minutes
-->
<!DOCTYPE html>
<html>
<head>
  <meta charset="UTF-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1.0" />
  <!--[if mso]><xml><o:OfficeDocumentSettings><o:PixelsPerInch>96</o:PixelsPerInch></o:OfficeDocumentSettings></xml><![endif]-->
  <style>
    body { margin: 0; padding: 0; background-color: #F8FAFF; font-family: 'Helvetica Neue', Arial, sans-serif; }
    .email-wrapper { max-width: 600px; margin: 40px auto; }
    .email-header  { background: #3B82F6; padding: 32px 40px; border-radius: 8px 8px 0 0; text-align: center; }
    .email-header h1 { color: #ffffff; font-size: 24px; margin: 0; }
    .email-body    { background: #FFFFFF; padding: 40px; border: 1px solid #E2E8F0; }
    .email-footer  { background: #F1F5F9; padding: 24px 40px; border-radius: 0 0 8px 8px; text-align: center;
                     font-size: 13px; color: #64748B; border: 1px solid #E2E8F0; border-top: 0; }
    .btn           { display: inline-block; padding: 14px 32px; background: #3B82F6; color: #FFFFFF !important;
                     text-decoration: none; border-radius: 6px; font-weight: 600; font-size: 16px;
                     margin: 24px 0; }
    p              { color: #1E293B; line-height: 1.7; font-size: 15px; }
    .expiry-note   { background: #FFF7ED; border: 1px solid #FED7AA; border-radius: 6px;
                     padding: 12px 16px; color: #9A3412; font-size: 13px; margin-top: 16px; }
  </style>
</head>
<body>
  <div class="email-wrapper">

    <div class="email-header">
      <h1>The Blog ✍️</h1>
    </div>

    <div class="email-body">
      <p>Hi ${user.firstName!"there"},</p>

      <p>
        Welcome to <strong>${realmName}</strong>! We just need to verify your
        email address to activate your account.
      </p>

      <p style="text-align:center;">
        <a class="btn" href="${link}">Verify my email address</a>
      </p>

      <div class="expiry-note">
        ⏳ This link expires in
        <strong>${linkExpirationFormatter(linkExpiration)}</strong>.
        If you didn&rsquo;t create an account, you can safely ignore this email.
      </div>

      <p style="margin-top:24px;">
        If the button doesn&rsquo;t work, copy and paste this link into your browser:
      </p>
      <p style="word-break:break-all; font-size:13px; color:#3B82F6;">
        <a href="${link}">${link}</a>
      </p>
    </div>

    <div class="email-footer">
      &copy; ${.now?string("yyyy")} ${realmName}. All rights reserved.
    </div>

  </div>
</body>
</html>
```

**Key FreeMarker patterns used here:**

- `${user.firstName!"there"}` — prints `firstName` or falls back to `"there"` if null
- `${linkExpirationFormatter(linkExpiration)}` — calls a Keycloak-provided helper function
- `${.now?string("yyyy")}` — current year (FreeMarker built-in)

### 10.4 HTML Email: password-reset.ftl

Create `keycloak/themes/blog-theme/email/html/password-reset.ftl`:

```freemarker
<!DOCTYPE html>
<html>
<head>
  <meta charset="UTF-8" />
  <style>
    body { background:#F8FAFF; font-family:'Helvetica Neue',Arial,sans-serif; margin:0; padding:0; }
    .wrapper { max-width:600px; margin:40px auto; }
    .header  { background:#EF4444; padding:32px 40px; border-radius:8px 8px 0 0; text-align:center; }
    .header h1 { color:#fff; margin:0; font-size:24px; }
    .body    { background:#fff; padding:40px; border:1px solid #E2E8F0; }
    .footer  { background:#F1F5F9; padding:24px; text-align:center; font-size:13px;
               color:#64748B; border:1px solid #E2E8F0; border-top:0; border-radius:0 0 8px 8px; }
    .btn     { display:inline-block; padding:14px 32px; background:#EF4444; color:#fff !important;
               text-decoration:none; border-radius:6px; font-weight:600; margin:24px 0; }
    p        { color:#1E293B; line-height:1.7; font-size:15px; }
    .warning { background:#FEF2F2; border:1px solid #FECACA; border-radius:6px;
               padding:12px 16px; color:#B91C1C; font-size:13px; margin-top:16px; }
  </style>
</head>
<body>
<div class="wrapper">

  <div class="header">
    <h1>🔐 Password Reset</h1>
  </div>

  <div class="body">
    <p>Hi ${user.firstName!"there"},</p>

    <p>
      We received a request to reset the password for your
      <strong>${realmName}</strong> account.
    </p>

    <p style="text-align:center;">
      <a class="btn" href="${link}">Reset my password</a>
    </p>

    <div class="warning">
      ⚠️ This link expires in <strong>${linkExpirationFormatter(linkExpiration)}</strong>.
      If you didn&rsquo;t request a password reset, please ignore this email —
      your password will not change.
    </div>

    <p style="margin-top:24px; font-size:13px; color:#64748B;">
      Link not working? Copy and paste:<br/>
      <a href="${link}" style="color:#3B82F6; word-break:break-all;">${link}</a>
    </p>
  </div>

  <div class="footer">&copy; ${.now?string("yyyy")} ${realmName}</div>
</div>
</body>
</html>
```

### 10.5 Plain Text Fallbacks

Create `keycloak/themes/blog-theme/email/text/email-verification.ftl`:

```freemarker
Hi ${user.firstName!"there"},

Welcome to ${realmName}! Please verify your email address by clicking the link below.

${link}

This link expires in ${linkExpirationFormatter(linkExpiration)}.

If you didn't create an account, ignore this email.

-- The ${realmName} Team
```

Create `keycloak/themes/blog-theme/email/text/password-reset.ftl`:

```freemarker
Hi ${user.firstName!"there"},

You requested a password reset for your ${realmName} account.

Click the link below to reset your password:
${link}

This link expires in ${linkExpirationFormatter(linkExpiration)}.

If you didn't request this, ignore this email.

-- The ${realmName} Team
```

---

## 11. FreeMarker Syntax Reference

This section is a complete reference for everything you will use in Keycloak templates.

### 11.1 Printing Variables

```freemarker
${myVar}                  <#-- prints myVar; throws if null -->
${myVar!}                 <#-- prints myVar; prints "" if null -->
${myVar!"default"}        <#-- prints myVar; prints "default" if null -->
${myVar?html}             <#-- HTML-escapes the value -->
${myVar?no_esc}           <#-- prints raw (unescaped) HTML — use only with kcSanitize() -->
${myVar?upper_case}       <#-- uppercase -->
${myVar?lower_case}       <#-- lowercase -->
${myVar?trim}             <#-- trim whitespace -->
${myVar?length}           <#-- string length -->
${myVar?string("yyyy")}   <#-- date formatting (use on date objects) -->
```

### 11.2 Conditionals

```freemarker
<#-- Basic if -->
<#if realm.rememberMe>
  Show remember me checkbox
</#if>

<#-- if / else -->
<#if user.email?has_content>
  <p>${user.email}</p>
<#else>
  <p>No email set</p>
</#if>

<#-- if / else if / else -->
<#if message.type == "error">
  <div class="alert-error">...
<#elseif message.type == "warning">
  <div class="alert-warning">...
<#else>
  <div class="alert-info">...
</#if>

<#-- Null/existence checks -->
<#if myVar??>              <#-- true if myVar is not null -->
<#if myVar?has_content>    <#-- true if myVar is not null AND not empty string/collection -->
<#if myVar?is_string>      <#-- type check -->
```

### 11.3 Loops

```freemarker
<#-- List / array -->
<#list auth.providers as provider>
  <a href="${provider.loginUrl}">${provider.displayName}</a>
</#list>

<#-- Loop with index -->
<#list items as item>
  ${item?index}: ${item.name}     <#-- ?index is zero-based -->
  ${item?counter}: ${item.name}   <#-- ?counter is one-based -->
</#list>

<#-- Empty check -->
<#list items as item>
  ${item.name}
<#else>
  <p>No items found.</p>
</#list>

<#-- Map iteration -->
<#list myMap?keys as key>
  ${key}: ${myMap[key]}
</#list>
```

### 11.4 Macros (Reusable Blocks)

```freemarker
<#-- Define a macro -->
<#macro field id label type="text" required=false>
  <div class="form-group">
    <label for="${id}">
      ${label}<#if required><span class="required">*</span></#if>
    </label>
    <input type="${type}" id="${id}" name="${id}" class="form-control" />
  </div>
</#macro>

<#-- Call the macro -->
<@field id="email" label="Email Address" type="email" required=true />
<@field id="bio" label="Bio" />
```

### 11.5 Including Other Files

```freemarker
<#include "partials/header.ftl">   <#-- relative to the same templates/ dir -->
```

### 11.6 Keycloak-Specific Helpers

```freemarker
<#-- Internationalised messages -->
${msg("loginTitle", realm.displayName)}
<#--  ↑ looks up "loginTitle" in messages_en.properties, interpolating realm.displayName -->

<#-- Sanitise HTML before printing raw -->
${kcSanitize(message.summary)?no_esc}
<#--  ↑ Always wrap untrusted HTML in kcSanitize() before ?no_esc -->

<#-- messagesPerField — per-field error API -->
<#if messagesPerField.existsError('email')>       <#-- check if a field has an error -->
  ${messagesPerField.get('email')}                <#-- get the error string -->
</#if>
<#if messagesPerField.existsError('email','username')>  <#-- check either field -->

<#-- Check if field exists and has a non-error value -->
<#if messagesPerField.existsInfo('email')>

<#-- URL helpers -->
${url.loginUrl}                    <#-- link back to login page -->
${url.loginAction}                 <#-- form POST target for login -->
${url.registrationUrl}             <#-- link to registration page -->
${url.registrationAction}          <#-- form POST target for registration -->
${url.loginResetCredentialsUrl}    <#-- forgot password page -->
${url.loginRestartFlowUrl}         <#-- restart auth flow -->
${url.getFirstValidTabUrl()}       <#-- returns the URL to the first valid tab -->

<#-- Resource path (your theme's /resources/ directory) -->
${resourcesPath}                   <#-- e.g. /realms/blog/login-actions/authenticate?... -->
<#-- Use it like: -->
<link rel="stylesheet" href="${resourcesPath}/css/styles.css" />
<img src="${resourcesPath}/img/logo.svg" />
```

### 11.7 Realm Object Reference

```freemarker
${realm.name}                        <#-- realm internal name, e.g. "blog" -->
${realm.displayName}                 <#-- human-readable name -->
${realm.displayNameHtml}             <#-- HTML display name (may have markup) -->
${realm.rememberMe}                  <#-- boolean: show "Remember me" -->
${realm.password}                    <#-- boolean: password auth enabled -->
${realm.registrationAllowed}         <#-- boolean: can users self-register -->
${realm.registrationEmailAsUsername} <#-- boolean: email doubles as username -->
${realm.loginWithEmailAllowed}       <#-- boolean: login with email allowed -->
${realm.resetPasswordAllowed}        <#-- boolean: forgot-password flow enabled -->
${realm.verifyEmail}                 <#-- boolean: email verification required -->
${realm.internationalizationEnabled} <#-- boolean: i18n on/off -->
```

---

## 12. The FastAPI Backend — Auth Service

The Auth Service:
1. Validates JWTs issued by Keycloak
2. Exposes user profile endpoints
3. Calls the Blog Service using a service account token (Client Credentials)

### 12.1 requirements.txt

Create `services/auth-service/requirements.txt`:

```
fastapi==0.111.0
uvicorn[standard]==0.30.0
python-jose[cryptography]==3.3.0
httpx==0.27.0
pydantic-settings==2.2.1
```

### 12.2 app/main.py

Create `services/auth-service/app/main.py`:

```python
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from app.routers import users

app = FastAPI(title="Auth Service", version="1.0.0")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["http://localhost:5173"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(users.router, prefix="/api/users", tags=["users"])


@app.get("/health")
async def health():
    return {"status": "ok", "service": "auth-service"}
```

### 12.3 app/auth.py — JWT Validation

Create `services/auth-service/app/auth.py`:

```python
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
            issuer=f"{KEYCLOAK_URL}/realms/{KEYCLOAK_REALM}",
            options={"verify_aud": False},  # Relax audience check for simplicity
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
```

### 12.4 app/routers/users.py

Create `services/auth-service/app/routers/users.py`:

```python
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
```

### 12.5 Dockerfile

Create `services/auth-service/Dockerfile`:

```dockerfile
FROM python:3.11-slim

WORKDIR /app

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY app/ ./app/

CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8001"]
```

---

## 13. The FastAPI Backend — Blog Service

### 13.1 requirements.txt

Create `services/blog-service/requirements.txt`:

```
fastapi==0.111.0
uvicorn[standard]==0.30.0
python-jose[cryptography]==3.3.0
httpx==0.27.0
sqlalchemy==2.0.30
asyncpg==0.29.0
pydantic-settings==2.2.1
```

### 13.2 app/main.py

Create `services/blog-service/app/main.py`:

```python
from fastapi import FastAPI
from app.routers import posts

app = FastAPI(title="Blog Service", version="1.0.0")

app.include_router(posts.router, prefix="/api/posts", tags=["posts"])

# Internal routes called only by other services (not the public internet)
app.include_router(posts.internal_router, prefix="/internal/posts", tags=["internal"])


@app.get("/health")
async def health():
    return {"status": "ok", "service": "blog-service"}
```

### 13.3 app/auth.py — Service-to-Service Auth

Create `services/blog-service/app/auth.py`:

```python
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
            options={"verify_aud": False},
            issuer=f"{KEYCLOAK_URL}/realms/{KEYCLOAK_REALM}",
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
```

### 13.4 app/routers/posts.py

Create `services/blog-service/app/routers/posts.py`:

```python
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
```

---

## 14. Service-to-Service Communication

Here is a complete diagram of the token flows:

```
┌──────────────────────────────────────────────────────────────────────────┐
│  FLOW 1: User logs in (Authorization Code + PKCE)                        │
│                                                                           │
│  Vue SPA ──redirect──▶ Keycloak login page (your custom theme)           │
│  Keycloak ──redirect──▶ Vue SPA with ?code=xxxxx                         │
│  Vue SPA ──POST code──▶ Keycloak /token endpoint                         │
│  Keycloak ──────────▶ {access_token, refresh_token, id_token}            │
└──────────────────────────────────────────────────────────────────────────┘

┌──────────────────────────────────────────────────────────────────────────┐
│  FLOW 2: Frontend calls Auth Service                                      │
│                                                                           │
│  Vue SPA ──GET /api/users/me──▶ Auth Service                             │
│             Authorization: Bearer <user_access_token>                    │
│  Auth Service: verify token signature against Keycloak JWKS              │
│  Auth Service ──────────────▶ { id, email, roles... }                   │
└──────────────────────────────────────────────────────────────────────────┘

┌──────────────────────────────────────────────────────────────────────────┐
│  FLOW 3: Auth Service calls Blog Service (service-to-service)            │
│                                                                           │
│  Vue SPA ──GET /api/users/me/posts──▶ Auth Service (user token)          │
│  Auth Service ──POST /token──▶ Keycloak (client_credentials grant)       │
│  Keycloak ────────────────▶ { service_access_token }                    │
│  Auth Service ──GET /internal/posts──▶ Blog Service                      │
│               Authorization: Bearer <service_access_token>               │
│               X-User-Id: <original user's sub>                           │
│  Blog Service: verify service token, trust X-User-Id header              │
│  Blog Service ────────────▶ [ posts... ]                                │
└──────────────────────────────────────────────────────────────────────────┘
```

### Why this pattern?

- The Blog Service never sees the user's personal access token — it only receives service tokens it can verify.
- The `X-User-Id` header carries the user context through the chain. The Blog Service trusts it because the service token proves the request came from the trusted Auth Service.
- In production you would add mutual TLS (mTLS) between services for defence in depth.

---

## 15. The Vue Frontend

### 15.1 Install Dependencies

```bash
cd frontend
npm create vue@latest . -- --router
npm install keycloak-js
```

### 15.2 src/keycloak.js — Keycloak JS Adapter

```javascript
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
```

### 15.3 public/silent-check-sso.html

Create `frontend/public/silent-check-sso.html`:

```html
<!DOCTYPE html>
<html>
<body>
<script>
  // This page is loaded in a hidden iframe by the Keycloak adapter
  // to silently detect if the user is already logged in.
  parent.postMessage(location.href, location.origin)
</script>
</body>
</html>
```

### 15.4 src/main.js

```javascript
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
      // Navigation guard — redirect to Keycloak login if not authenticated
      beforeEnter: (_to, _from, next) => {
        if (isAuthenticated()) {
          next()
        } else {
          // Import keycloak default export to trigger redirect
          import('./keycloak.js').then(({ default: kc }) => kc.login())
        }
      },
    },
  ],
})

// Initialise Keycloak before mounting the app
initKeycloak().then(() => {
  createApp(App).use(router).mount('#app')
})
```

### 15.5 src/App.vue

```vue
<template>
  <div id="app">
    <nav>
      <RouterLink to="/">Home</RouterLink>
      <RouterLink to="/blog" v-if="user">My Blog</RouterLink>

      <div class="nav-right">
        <span v-if="user">Hi, {{ user.firstName }}</span>
        <button v-if="user" @click="handleLogout">Logout</button>
        <button v-else @click="handleLogin">Login</button>
      </div>
    </nav>
    <RouterView />
  </div>
</template>

<script setup>
import { ref, onMounted } from 'vue'
import { RouterLink, RouterView } from 'vue-router'
import { getUserInfo, login, logout } from './keycloak.js'

const user = ref(null)

onMounted(() => {
  user.value = getUserInfo()
})

function handleLogin() {
  login()
}

function handleLogout() {
  logout()
}
</script>
```

### 15.6 src/views/Blog.vue — Calling the Backend

```vue
<template>
  <div class="blog-page">
    <h1>My Posts</h1>

    <div v-if="loading">Loading...</div>
    <div v-else-if="error" class="error">{{ error }}</div>

    <div v-else>
      <div class="post-form">
        <h2>New Post</h2>
        <input v-model="newPost.title" placeholder="Post title" />
        <textarea v-model="newPost.content" placeholder="Write something..." />
        <button @click="createPost">Publish</button>
      </div>

      <div class="posts">
        <div v-for="post in posts" :key="post.id" class="post-card">
          <h3>{{ post.title }}</h3>
          <p>{{ post.content }}</p>
          <small>{{ post.created_at }}</small>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, onMounted } from 'vue'
import { getToken } from '../keycloak.js'

const posts = ref([])
const loading = ref(true)
const error = ref(null)
const newPost = ref({ title: '', content: '' })

/**
 * All API calls include the Keycloak access token in the Authorization header.
 * The backend validates this token without ever calling Keycloak again —
 * it just checks the signature against the public keys.
 */
async function apiFetch(url, options = {}) {
  const token = getToken()
  return fetch(url, {
    ...options,
    headers: {
      'Content-Type': 'application/json',
      'Authorization': `Bearer ${token}`,
      ...options.headers,
    },
  })
}

onMounted(async () => {
  try {
    // This calls Auth Service which calls Blog Service internally
    const res = await apiFetch('http://localhost:8001/api/users/me/posts')
    if (!res.ok) throw new Error(`HTTP ${res.status}`)
    posts.value = await res.json()
  } catch (e) {
    error.value = e.message
  } finally {
    loading.value = false
  }
})

async function createPost() {
  try {
    const res = await apiFetch('http://localhost:8002/api/posts', {
      method: 'POST',
      body: JSON.stringify({ ...newPost.value, published: true }),
    })
    if (!res.ok) throw new Error(`HTTP ${res.status}`)
    const post = await res.json()
    posts.value.unshift(post)
    newPost.value = { title: '', content: '' }
  } catch (e) {
    error.value = e.message
  }
}
</script>
```

---

## 16. Deploying to kind (Kubernetes)

### 16.1 Create the Cluster

Create `kind-config.yaml`:

```yaml
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
nodes:
  - role: control-plane
    extraPortMappings:
      - containerPort: 30080     # Keycloak
        hostPort: 8080
      - containerPort: 30001     # Auth Service
        hostPort: 8001
      - containerPort: 30002     # Blog Service
        hostPort: 8002
```

```bash
kind create cluster --config kind-config.yaml --name blog-cluster
```

### 16.2 Load Local Images

```bash
# Build images
docker build -t auth-service:latest ./services/auth-service
docker build -t blog-service:latest ./services/blog-service

# Load them into kind (kind doesn't use your local Docker daemon directly)
kind load docker-image auth-service:latest --name blog-cluster
kind load docker-image blog-service:latest --name blog-cluster
```

### 16.3 Kubernetes Manifests

Create `k8s/keycloak.yaml`:

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
          args: ["start-dev"]
          env:
            - name: KEYCLOAK_ADMIN
              value: "admin"
            - name: KEYCLOAK_ADMIN_PASSWORD
              value: "admin"
            - name: KC_SPI_THEME_CACHE_THEMES
              value: "false"
            - name: KC_SPI_THEME_CACHE_TEMPLATES
              value: "false"
          ports:
            - containerPort: 8080
          volumeMounts:
            - name: blog-theme
              mountPath: /opt/keycloak/themes/blog-theme
      volumes:
        - name: blog-theme
          configMap:
            name: blog-theme
---
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
      nodePort: 30080
```

> **Tip:** For production, mount themes via an `initContainer` that copies them from an image, or bake the theme directly into a custom Keycloak image. ConfigMaps have a 1 MB size limit which may not hold all theme files.

**Build a custom Keycloak image with your theme baked in (recommended):**

Create `keycloak/Dockerfile`:

```dockerfile
FROM quay.io/keycloak/keycloak:24.0

# Copy your theme into the Keycloak themes directory
COPY themes/blog-theme /opt/keycloak/themes/blog-theme

# Run in development mode (use 'start' for production with proper certs)
ENTRYPOINT ["/opt/keycloak/bin/kc.sh"]
CMD ["start-dev"]
```

```bash
docker build -t blog-keycloak:latest ./keycloak
kind load docker-image blog-keycloak:latest --name blog-cluster
```

---

## 17. Testing Your Theme Changes

### 17.1 Hot Reload During Development

Keycloak caches templates in production. For development, theme caching is disabled via these environment variables (already set in your `docker-compose.yml`):

```yaml
KC_SPI_THEME_CACHE_THEMES: "false"
KC_SPI_THEME_CACHE_TEMPLATES: "false"
KC_SPI_THEME_STATIC_MAX_AGE: -1
```

With these set, **just edit your `.ftl` files and refresh the browser** — no Keycloak restart needed.

### 17.2 Verify Theme is Loaded

1. Go to `http://localhost:8080/admin` → your realm → **Realm Settings** → **Themes**
2. Set Login Theme to `blog-theme`
3. Open `http://localhost:8080/realms/blog/account` — you should see your styled page

### 17.3 Test Email Templates

1. In the admin console go to your realm → **Realm Settings** → **Email**
2. Fill in SMTP settings (use Mailhog for local testing — add it to docker-compose):

```yaml
mailhog:
  image: mailhog/mailhog
  ports:
    - "1025:1025"    # SMTP
    - "8025:8025"    # Web UI
```

SMTP settings in Keycloak:
- Host: `mailhog`
- Port: `1025`
- From: `noreply@blog.local`

3. Use **Test connection** to send a test email, then view it at `http://localhost:8025`

4. Trigger email flows by:
   - Registering a new user (triggers verification email if realm requires it)
   - Using "Forgot password" on the login page

### 17.4 Common FreeMarker Debugging

If your template throws an error, Keycloak shows a generic error page. To see the actual FreeMarker error:

```bash
docker compose logs keycloak --follow | grep -i "freemarker\|template\|error"
```

Or check the Keycloak admin console: **Events** → **Admin events** for auth-related errors.

---

## 18. Common Errors & Fixes

| Error | Cause | Fix |
|---|---|---|
| Theme not appearing in dropdown | Theme directory name doesn't match or theme.properties is missing | Check `keycloak/themes/blog-theme/login/theme.properties` exists |
| `${resourcesPath}` returns empty | Cache still enabled | Set `KC_SPI_THEME_CACHE_THEMES=false` and restart |
| FreeMarker `null` error on `user.firstName` | Variable can be null | Use `${user.firstName!""}` with a default |
| CORS error calling backend | Backend missing CORS middleware | Add `CORSMiddleware` to FastAPI |
| `401 Unauthorized` from backend | Token expired or wrong audience | Check `verify_aud` setting and token expiry |
| Email not sending | SMTP not configured | Set up Mailhog and configure realm SMTP settings |
| Registration form doesn't appear | `registrationAllowed` is false in realm | Enable it: Realm Settings → Login → User registration |
| `Invalid token` from Blog Service | Service calling with user token, not service token | Ensure Auth Service uses client_credentials grant |

---

## 19. Going Further

Once you have the basics working, here are the natural next steps:

**Custom i18n messages** — Override just the text strings without touching HTML. Create `login/messages/messages_en.properties` in your theme and override keys like `loginTitle=Welcome back to The Blog`.

**Custom user attributes** — Add extra fields to registration (e.g., a bio or username). You need to: (1) add the field to `register.ftl`, (2) configure the attribute in Keycloak's User Profile (Realm Settings → User Profile), and (3) read the attribute from the token in your backend.

**OTP / Two-Factor Authentication** — Keycloak has built-in TOTP support. Customise `login-otp.ftl` for your branded OTP entry screen.

**Password policy feedback** — Use `passwordPolicyMessageIds` in `register.ftl` to show real-time password strength requirements.

**Keycloakify** — A tool that lets you write Keycloak themes in React. Worth exploring once you understand the native FreeMarker approach.

**Token exchange** — Instead of the Auth Service fetching a service token each time, explore Keycloak's Token Exchange feature to convert a user token into a scoped service token on the fly.

**Realm export** — Export your configured realm as JSON for reproducible setups:
```bash
docker exec -it <keycloak-container> /opt/keycloak/bin/kc.sh export \
  --realm blog --file /tmp/blog-realm.json
docker cp <keycloak-container>:/tmp/blog-realm.json ./keycloak/
```
Then mount it and use `--import-realm` in your docker-compose command to auto-configure on startup.

---

*Guide complete. You now have a fully styled Keycloak login/registration/email experience wired into a Vue + FastAPI blog application, with service-to-service authentication patterns and a path to Kubernetes deployment via kind.*