# Quick Start Guide - Keycloak Customization

This guide will get you up and running with the Keycloak customization project in **under 10 minutes**.

## Prerequisites

Ensure you have these installed:
- Docker Desktop (≥ 24)
- Node.js (≥ 20) - *only needed for local development mode*
- Python (≥ 3.11) - *only needed for local development mode*

Verify:
```bash
docker --version
```

---

## Step 1: Start with Docker Compose (Fully Containerized)

This is the **recommended starting point** - everything runs in containers.

### 1.1 Start the Stack

```bash
# Start all services (this will build images on first run)
docker compose up -d

# Watch the logs
docker compose logs -f
```

**What's happening:**
- PostgreSQL starts and initializes databases
- Keycloak starts and mounts your custom theme
- Auth Service and Blog Service build and start
- Frontend builds (Vue app) and serves via nginx

Wait about 60-90 seconds for all services to be ready. You'll see:
```
keycloak-1      | ... Keycloak 24.0 ... started
auth-service-1  | INFO: Uvicorn running on http://0.0.0.0:8001
blog-service-1  | INFO: Uvicorn running on http://0.0.0.0:8002
frontend-1      | ... (nginx serving on port 80)
```

### 1.2 Verify Services are Running

Open these URLs in your browser:

| Service | URL | Credentials |
|---------|-----|-------------|
| **Frontend** | http://localhost:5173 | - |
| Keycloak Admin | http://localhost:8080 | admin / admin |
| Auth Service Health | http://localhost:8001/health | - |
| Blog Service Health | http://localhost:8002/health | - |

---

## Step 2: Configure Keycloak

### 2.1 Create the Realm

1. Go to http://localhost:8080
2. Login with `admin` / `admin`
3. Click the realm dropdown (top left, says "master")
4. Click **Create Realm**
5. Name: `blog`
6. Click **Create**

### 2.2 Create the Frontend Client

1. In the `blog` realm, go to **Clients** → **Create client**
2. Fill in:
   - Client ID: `blog-frontend`
   - Client type: `OpenID Connect`
   - Click **Next**
3. Enable these:
   - ✅ Standard flow
   - ✅ Direct access grants
   - Click **Next**
4. Set URLs:
   - Valid redirect URIs: `http://localhost:5173/*`
   - Valid post logout redirect URIs: `http://localhost:5173`
   - Web origins: `http://localhost:5173`
5. Click **Save**

### 2.3 Create the Auth Service Client

1. **Clients** → **Create client**
2. Fill in:
   - Client ID: `auth-service`
   - Client type: `OpenID Connect`
   - Click **Next**
3. Enable:
   - ✅ Client authentication
   - ✅ Service accounts roles
   - Click **Next**, then **Save**
4. Go to **Credentials** tab
5. **Note:** The client secret is already set in docker-compose.yml as `auth-service-secret`

### 2.4 Create the Blog Service Client

Repeat the same steps as auth-service but with:
- Client ID: `blog-service`
- Client secret: `blog-service-secret` (already in docker-compose.yml)

### 2.5 Apply Your Custom Theme

1. Go to **Realm Settings** → **Themes** tab
2. Set:
   - Login theme: `blog-theme`
   - Email theme: `blog-theme`
3. Click **Save**

### 2.6 Enable User Registration

1. **Realm Settings** → **Login** tab
2. Enable:
   - ✅ User registration
   - ✅ Forgot password
   - ✅ Remember me
3. Click **Save**

---

## Step 3: Test the Application

### 3.1 Access the Frontend

Go to http://localhost:5173

You should see:
- A home page with "Welcome to The Blog"
- A "Get Started" button

### 3.2 Register a New User

1. Click **Get Started** on the home page
2. You'll be redirected to the Keycloak login page (with your custom theme!)
3. Click **Register** (or "Create account")
4. Fill in the form:
   - First name: Test
   - Last name: User
   - Email: test@example.com
   - Password: Test123!
5. Click **Register**

### 3.3 Create a Blog Post

After logging in, you'll be redirected back to the Vue app:
1. You should see "My Posts" page
2. Fill in the form:
   - Title: My First Post
   - Content: Hello from Keycloak!
3. Click **Publish**

The post should appear below the form.

---

## Step 4: Customize Your Theme

All theme files are in `keycloak/themes/blog-theme/`.

### Hot Reload is Enabled

With the docker-compose setup, theme caching is **disabled**. This means:
- Edit any `.ftl` file in `keycloak/themes/blog-theme/login/templates/`
- Edit CSS in `keycloak/themes/blog-theme/login/resources/css/styles.css`
- **Just refresh your browser** - no restart needed!

### Try This Now

1. Open `keycloak/themes/blog-theme/login/resources/css/styles.css`
2. Change line 3:
   ```css
   --brand-primary: #EF4444;  /* Change to red */
   ```
3. Save the file
4. Go to http://localhost:8080/realms/blog/account
5. Refresh - the buttons should now be red!

---

## Step 5: View Logs and Debug

### View All Logs
```bash
docker compose logs -f
```

### View Specific Service Logs
```bash
docker compose logs keycloak -f
docker compose logs auth-service -f
docker compose logs blog-service -f
docker compose logs frontend -f
```

### Common Issues

**Frontend shows blank page:**
```bash
# Check frontend logs
docker compose logs frontend

# Rebuild frontend
docker compose up -d --build frontend
```

**Keycloak theme not appearing:**
```bash
# Restart Keycloak
docker compose restart keycloak

# Verify theme is mounted
docker compose exec keycloak ls /opt/keycloak/themes/
# Should show: blog-theme
```

**Backend services can't connect to Keycloak:**
```bash
# Check if Keycloak is fully started
docker compose logs keycloak | grep "started"

# Restart backend services
docker compose restart auth-service blog-service
```

---

## Step 6: Stop Everything

```bash
# Stop all services
docker compose down

# Stop and remove volumes (fresh start)
docker compose down -v
```

---

## Alternative: Local Development Mode

If you want to develop the frontend with hot-reload:

**Terminal 1 - Backend services:**
```bash
docker compose up postgres keycloak auth-service blog-service
```

**Terminal 2 - Frontend (local):**
```bash
cd frontend
npm install
npm run dev
```

This runs the frontend on your local machine with Vite's dev server for instant hot-reload.

---

## Next Steps: Deploy to Kubernetes (kind)

Once you have Docker Compose working, you can deploy to a local Kubernetes cluster.

### 1. Create kind Cluster

```bash
kind create cluster --config kind-config.yaml --name blog-cluster
```

### 2. Build and Load Images

```bash
# Build all images
docker build -t blog-frontend:latest ./frontend
docker build -t auth-service:latest ./services/auth-service
docker build -t blog-service:latest ./services/blog-service

# For Keycloak with custom theme
docker build -t blog-keycloak:latest -f keycloak/Dockerfile ./keycloak

# Load images into kind
kind load docker-image blog-frontend:latest --name blog-cluster
kind load docker-image auth-service:latest --name blog-cluster
kind load docker-image blog-service:latest --name blog-cluster
kind load docker-image blog-keycloak:latest --name blog-cluster
```

### 3. Deploy to Kubernetes

```bash
# Apply all manifests
kubectl apply -f k8s/

# Watch pods start
kubectl get pods -w
```

### 4. Access Services

| Service | URL |
|---------|-----|
| Frontend | http://localhost:5173 |
| Keycloak | http://localhost:8080 |
| Auth Service | http://localhost:8001 |
| Blog Service | http://localhost:8002 |

**Note:** You'll need to reconfigure Keycloak clients (same steps as Docker Compose).

### 5. Clean Up Kubernetes

```bash
# Delete all resources
kubectl delete -f k8s/

# Delete cluster
kind delete cluster --name blog-cluster
```

---

## Architecture Overview

```
Browser (localhost:5173)
    ↓
Vue Frontend (nginx) → Keycloak (localhost:8080) → Custom Theme
    ↓
Auth Service (localhost:8001)
    ↓
Blog Service (localhost:8002)
    ↓
PostgreSQL (localhost:5432)
```

**Token Flow:**
1. User logs in via Keycloak (gets access token)
2. Vue app stores token in memory
3. Vue app sends token to Auth Service
4. Auth Service validates token and calls Blog Service
5. Blog Service validates service token and returns data

---

## Troubleshooting

### "Invalid redirect URI" error
- Make sure you added `http://localhost:5173/*` to the client's redirect URIs
- Check you're in the `blog` realm, not `master`

### "Client not found" error
- Verify client IDs match exactly: `blog-frontend`, `auth-service`, `blog-service`
- Check you created clients in the `blog` realm

### Theme not loading
- Verify the theme directory is mounted: `docker compose exec keycloak ls /opt/keycloak/themes/`
- Should show: `blog-theme`

### Backend 401 errors
- Check client secrets match in docker-compose.yml
- Verify clients have "Service accounts roles" enabled
- Ensure client secrets in Keycloak match: `auth-service-secret` and `blog-service-secret`

### Frontend build fails
```bash
# Rebuild with no cache
docker compose build --no-cache frontend
docker compose up -d frontend
```

---

## Quick Reference

### Restart a Single Service
```bash
docker compose restart keycloak
docker compose restart auth-service
docker compose restart blog-service
docker compose restart frontend
```

### Rebuild a Service
```bash
docker compose up -d --build frontend
docker compose up -d --build auth-service
docker compose up -d --build blog-service
```

### View Database
```bash
docker compose exec postgres psql -U keycloak -d keycloak
\dt  # List tables
\q   # Quit
```

### Export Realm Configuration
```bash
docker compose exec keycloak /opt/keycloak/bin/kc.sh export \
  --realm blog --file /tmp/blog-realm.json
docker compose cp keycloak:/tmp/blog-realm.json ./keycloak/
```

### Shell into a Container
```bash
docker compose exec keycloak bash
docker compose exec frontend sh
docker compose exec auth-service bash
```

---

**You're all set!** 🎉

For detailed explanations of how everything works, see the main `guide.md`.


```bash
# Start all services
docker compose up -d

# Watch the logs
docker compose logs -f
```

Wait about 30-60 seconds for Keycloak to fully start. You'll see:
```
keycloak-customisation-keycloak-1  | ... Keycloak 24.0 ... started
```

### 1.3 Verify Services are Running

Open these URLs in your browser:

| Service | URL | Credentials |
|---------|-----|-------------|
| Keycloak Admin | http://localhost:8080 | admin / admin |
| Auth Service Health | http://localhost:8001/health | - |
| Blog Service Health | http://localhost:8002/health | - |

---

## Step 2: Configure Keycloak

### 2.1 Create the Realm

1. Go to http://localhost:8080
2. Login with `admin` / `admin`
3. Click the realm dropdown (top left, says "master")
4. Click **Create Realm**
5. Name: `blog`
6. Click **Create**

### 2.2 Create the Frontend Client

1. In the `blog` realm, go to **Clients** → **Create client**
2. Fill in:
   - Client ID: `blog-frontend`
   - Client type: `OpenID Connect`
   - Click **Next**
3. Enable these:
   - ✅ Standard flow
   - ✅ Direct access grants
   - Click **Next**
4. Set URLs:
   - Valid redirect URIs: `http://localhost:5173/*`
   - Valid post logout redirect URIs: `http://localhost:5173`
   - Web origins: `http://localhost:5173`
5. Click **Save**

### 2.3 Create the Auth Service Client

1. **Clients** → **Create client**
2. Fill in:
   - Client ID: `auth-service`
   - Client type: `OpenID Connect`
   - Click **Next**
3. Enable:
   - ✅ Client authentication
   - ✅ Service accounts roles
   - Click **Next**, then **Save**
4. Go to **Credentials** tab
5. Copy the **Client secret** (you'll need this)
6. Update your `.env` file or docker-compose.yml with this secret

### 2.4 Create the Blog Service Client

Repeat the same steps as auth-service but with:
- Client ID: `blog-service`

### 2.5 Apply Your Custom Theme

1. Go to **Realm Settings** → **Themes** tab
2. Set:
   - Login theme: `blog-theme`
   - Email theme: `blog-theme`
3. Click **Save**

### 2.6 Enable User Registration

1. **Realm Settings** → **Login** tab
2. Enable:
   - ✅ User registration
   - ✅ Forgot password
   - ✅ Remember me
3. Click **Save**

---

## Step 3: Run the Frontend

```bash
cd frontend
npm run dev
```

Open http://localhost:5173

You should see:
- A home page with "Welcome to The Blog"
- A "Get Started" button that redirects to your **custom Keycloak login page**

---

## Step 4: Test the Flow

### 4.1 Register a New User

1. Click **Get Started** on the home page
2. You'll be redirected to the Keycloak login page (with your custom theme!)
3. Click **Register** (or "Create account")
4. Fill in the form:
   - First name: Test
   - Last name: User
   - Email: test@example.com
   - Password: Test123!
5. Click **Register**

### 4.2 Create a Blog Post

After logging in, you'll be redirected back to the Vue app:
1. You should see "My Posts" page
2. Fill in the form:
   - Title: My First Post
   - Content: Hello from Keycloak!
3. Click **Publish**

The post should appear below the form.

---

## Step 5: Customize Your Theme

All theme files are in `keycloak/themes/blog-theme/`.

### Hot Reload is Enabled

With the docker-compose setup, theme caching is **disabled**. This means:
- Edit any `.ftl` file in `keycloak/themes/blog-theme/login/templates/`
- Edit CSS in `keycloak/themes/blog-theme/login/resources/css/styles.css`
- **Just refresh your browser** - no restart needed!

### Try This Now

1. Open `keycloak/themes/blog-theme/login/resources/css/styles.css`
2. Change line 3:
   ```css
   --brand-primary: #EF4444;  /* Change to red */
   ```
3. Save the file
4. Go to http://localhost:8080/realms/blog/account
5. Refresh - the buttons should now be red!

---

## Step 6: View Logs and Debug

### View Keycloak Logs
```bash
docker compose logs keycloak -f
```

### View Backend Logs
```bash
docker compose logs auth-service blog-service -f
```

### Common Issues

**Frontend build fails:**
```bash
cd frontend
rm -rf node_modules package-lock.json
npm install
```

**Keycloak theme not appearing:**
```bash
# Restart Keycloak
docker compose restart keycloak
```

**Backend services can't connect to Keycloak:**
```bash
# Check if Keycloak is fully started
docker compose logs keycloak | grep "started"
```

---

## Step 7: Stop Everything

```bash
# Stop all services
docker compose down

# Stop and remove volumes (fresh start)
docker compose down -v
```

---

## Next Steps

Once you have this working locally:

1. **Customize Email Templates** - See `guide.md` section 10
2. **Add Custom Fields** - See `guide.md` section 19
3. **Deploy to Kubernetes** - See `guide.md` section 16

---

## Architecture Overview

```
Browser (localhost:5173)
    ↓
Vue Frontend → Keycloak (localhost:8080) → Custom Theme
    ↓
Auth Service (localhost:8001)
    ↓
Blog Service (localhost:8002)
    ↓
PostgreSQL (localhost:5432)
```

**Token Flow:**
1. User logs in via Keycloak (gets access token)
2. Vue app stores token in memory
3. Vue app sends token to Auth Service
4. Auth Service validates token and calls Blog Service
5. Blog Service validates service token and returns data

---

## Troubleshooting

### "Invalid redirect URI" error
- Make sure you added `http://localhost:5173/*` to the client's redirect URIs
- Check you're in the `blog` realm, not `master`

### "Client not found" error
- Verify client IDs match exactly: `blog-frontend`, `auth-service`, `blog-service`
- Check you created clients in the `blog` realm

### Theme not loading
- Verify the theme directory is mounted: `docker compose exec keycloak ls /opt/keycloak/themes/`
- Should show: `blog-theme`

### Backend 401 errors
- Check client secrets match in docker-compose.yml
- Verify clients have "Service accounts roles" enabled

---

## Quick Reference

### Restart a Single Service
```bash
docker compose restart keycloak
docker compose restart auth-service
docker compose restart blog-service
```

### Rebuild Backend Services
```bash
docker compose up -d --build auth-service blog-service
```

### View Database
```bash
docker compose exec postgres psql -U keycloak -d keycloak
\dt  # List tables
\q   # Quit
```

### Export Realm Configuration
```bash
docker compose exec keycloak /opt/keycloak/bin/kc.sh export \
  --realm blog --file /tmp/blog-realm.json
docker compose cp keycloak:/tmp/blog-realm.json ./keycloak/
```

---

**You're all set!** 🎉

For detailed explanations of how everything works, see the main `guide.md`.
