# Keycloak Customization Project

A complete, production-ready example of Keycloak theme customization integrated with a full-stack blog application.

## 🎯 What This Project Demonstrates

- **Custom Keycloak Themes** - Fully branded login, registration, and email templates
- **Vue 3 Frontend** - SPA with Keycloak JS adapter and PKCE flow
- **FastAPI Backends** - Two microservices with JWT validation
- **Service-to-Service Auth** - Client credentials flow between services
- **Docker Compose** - Complete local development environment
- **Kubernetes Ready** - kind cluster configuration included

## 🚀 Quick Start

**New to this project? Start here:**

1. **[QUICKSTART.md](./QUICKSTART.md)** - Get running in 10 minutes with Docker Compose
2. **[guide.md](./guide.md)** - Complete deep-dive guide (78,000 words)

## 📁 Project Structure

```
keycloak-customisation/
├── QUICKSTART.md              # ⭐ Start here
├── guide.md                   # Complete reference guide
├── docker-compose.yml         # Local development stack
├── kind-config.yaml           # Kubernetes cluster config
│
├── keycloak/
│   └── themes/blog-theme/     # Custom Keycloak theme
│       ├── login/             # Login, registration pages
│       │   ├── theme.properties
│       │   ├── resources/     # CSS, images
│       │   └── templates/     # FreeMarker templates
│       └── email/             # Email templates
│           ├── html/
│           └── text/
│
├── services/
│   ├── auth-service/          # User authentication API
│   │   ├── Dockerfile
│   │   ├── requirements.txt
│   │   └── app/
│   └── blog-service/          # Blog posts API
│       ├── Dockerfile
│       ├── requirements.txt
│       └── app/
│
└── frontend/                  # Vue 3 SPA
    ├── Dockerfile
    ├── package.json
    ├── vite.config.js
    └── src/
        ├── keycloak.js        # Keycloak adapter setup
        ├── App.vue
        ├── main.js
        └── views/
```

## 🛠️ Prerequisites

| Tool | Version | Purpose |
|------|---------|---------|
| Docker Desktop | ≥ 24 | Container runtime |
| Node.js | ≥ 20 | Frontend build |
| Python | ≥ 3.11 | Backend services |
| kind | ≥ 0.22 | Local Kubernetes (optional) |
| kubectl | ≥ 1.29 | Kubernetes CLI (optional) |

## 🏃 Running Locally

### Option 1: Docker Compose (Recommended - Fully Containerized)

Everything runs in containers - no local Node.js or Python needed!

```bash
# Start all services (builds images on first run)
docker compose up -d

# View logs
docker compose logs -f
```

**Then follow the setup steps in [QUICKSTART.md](./QUICKSTART.md).**

Access the app at http://localhost:5173

### Option 2: Development Mode (Frontend Hot Reload)

Run backend services in Docker, frontend locally for instant hot-reload:

**Terminal 1 - Backend services:**
```bash
docker compose up postgres keycloak auth-service blog-service
```

**Terminal 2 - Frontend:**
```bash
cd frontend
npm install
npm run dev
```

Access the app at http://localhost:5173

## 🎨 Customizing the Theme

All theme files are in `keycloak/themes/blog-theme/`.

**Hot reload is enabled** - just edit and refresh:

- **Templates**: `login/templates/*.ftl` (FreeMarker)
- **Styles**: `login/resources/css/styles.css`
- **Images**: `login/resources/img/`
- **Emails**: `email/html/*.ftl` and `email/text/*.ftl`

### Key Files to Customize

| File | Purpose |
|------|---------|
| `login/templates/login.ftl` | Login page |
| `login/templates/register.ftl` | Registration page |
| `login/resources/css/styles.css` | All styling |
| `email/html/email-verification.ftl` | Verification email |
| `email/html/password-reset.ftl` | Password reset email |

## 🔑 Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                         Browser                              │
│                    Vue SPA (port 5173)                       │
└───────────────────────┬─────────────────────────────────────┘
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

### Authentication Flows

1. **User Login** - Authorization Code + PKCE
2. **Frontend → Backend** - Bearer token validation
3. **Service → Service** - Client credentials grant

## 📚 Documentation

- **[QUICKSTART.md](./QUICKSTART.md)** - Step-by-step setup (10 minutes)
- **[guide.md](./guide.md)** - Complete guide covering:
  - Keycloak concepts and architecture
  - Theme system deep dive
  - FreeMarker syntax reference
  - FastAPI backend implementation
  - Vue frontend with Keycloak JS
  - Kubernetes deployment
  - Troubleshooting

## 🧪 Testing

### Test the Login Flow
1. Go to http://localhost:5173
2. Click "Get Started"
3. You'll see your custom login page
4. Click "Register" to create an account
5. After login, create a blog post

### Test Email Templates
1. Set up Mailhog (see guide.md section 17.3)
2. Trigger "Forgot Password" flow
3. View email at http://localhost:8025

## 🐛 Troubleshooting

### Frontend build fails
```bash
cd frontend
rm -rf node_modules package-lock.json
npm install
```

### Theme not loading
```bash
docker compose restart keycloak
# Wait 30 seconds, then refresh browser
```

### Backend 401 errors
- Check client secrets in docker-compose.yml
- Verify clients are created in Keycloak
- Check client IDs match exactly

### More help
See the **Common Errors & Fixes** section in [guide.md](./guide.md#18-common-errors--fixes).

## 🚢 Deployment

### Docker Compose (Development/Production)
```bash
# Start all services
docker compose up -d

# View logs
docker compose logs -f

# Stop services
docker compose down
```

### Kubernetes with kind (Local)
```bash
# Create cluster
kind create cluster --config kind-config.yaml --name blog-cluster

# Build and load images
docker build -t blog-frontend:latest ./frontend
docker build -t blog-keycloak:latest -f keycloak/Dockerfile ./keycloak
docker build -t auth-service:latest ./services/auth-service
docker build -t blog-service:latest ./services/blog-service

kind load docker-image blog-frontend:latest --name blog-cluster
kind load docker-image blog-keycloak:latest --name blog-cluster
kind load docker-image auth-service:latest --name blog-cluster
kind load docker-image blog-service:latest --name blog-cluster

# Apply manifests
kubectl apply -f k8s/

# Watch deployment
kubectl get pods -w
```

Access services at the same ports: http://localhost:5173 (frontend), http://localhost:8080 (Keycloak)

See [QUICKSTART.md](./QUICKSTART.md) for detailed Kubernetes setup.

## 📖 Learning Resources

This project is designed as a **complete learning reference** for:
- Keycloak theme customization
- OpenID Connect / OAuth 2.0 flows
- Microservices authentication patterns
- FreeMarker templating
- Vue 3 with Keycloak
- FastAPI JWT validation

## 🤝 Contributing

This is a reference project. Feel free to:
- Fork and customize for your needs
- Report issues or suggest improvements
- Use as a template for your own projects

## 📝 License

MIT License - use freely for learning and production projects.

## 🎓 Who This Is For

- **Beginners** learning Keycloak customization
- **Developers** building authenticated web apps
- **Teams** needing a production-ready auth setup
- **Anyone** wanting to understand modern authentication flows

---

**Ready to start?** → [QUICKSTART.md](./QUICKSTART.md)

**Need details?** → [guide.md](./guide.md)
