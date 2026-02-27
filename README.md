# Keycloak Customization Project

A complete, production-ready example of Keycloak theme customization integrated with a full-stack blog application featuring custom red-themed UI, simplified registration, and seamless navigation between frontend and account console.

## 🎯 What This Project Demonstrates

- **Custom Keycloak Themes** - Red-themed login, registration, account console, and email templates
- **Simplified Registration** - Email-only registration with auto-filled optional fields
- **Seamless Navigation** - Links between frontend and Keycloak account console
- **Vue 3 Frontend** - SPA with Keycloak JS adapter and PKCE flow
- **FastAPI Backends** - Two microservices with JWT validation and CORS
- **Service-to-Service Auth** - Client credentials flow between services
- **Docker Compose** - Complete local development environment

## 🚀 Quick Start

**New to this project? Start here:**

1. **[GUIDE.md](./GUIDE.md)** - Complete guide with step-by-step exercises
2. **[THEME_QUICK_REFERENCE.md](./THEME_QUICK_REFERENCE.md)** - Quick reference for theme customization

## 📁 Project Structure

```
keycloak-customisation/
├── GUIDE.md                   # ⭐ Complete reference guide
├── THEME_QUICK_REFERENCE.md   # Quick theme customization reference
├── docker-compose.yml         # Local development stack
│
├── keycloak/
│   ├── blog-realm.json        # Realm configuration
│   └── themes/blog-theme/     # Custom Keycloak theme
│       ├── login/             # Login, registration pages
│       │   ├── theme.properties
│       │   ├── messages/      # Custom text (tab titles)
│       │   ├── resources/
│       │   │   ├── css/       # Red theme styling
│       │   │   ├── js/        # Auto-fill registration fields
│       │   │   └── img/       # Logo and favicon
│       │   └── templates/     # FreeMarker templates
│       ├── account/           # Account console theme
│       │   ├── theme.properties
│       │   ├── messages/
│       │   └── resources/
│       │       ├── css/       # PatternFly v5 overrides
│       │       ├── js/        # Back to blog navigation
│       │       └── img/       # Logo and favicon
│       └── email/             # Email templates
│           ├── html/          # Red-themed HTML emails
│           └── text/          # Plain text versions
│
├── services/
│   ├── auth-service/          # User authentication API
│   │   ├── Dockerfile
│   │   └── app/
│   └── blog-service/          # Blog posts API (with CORS)
│       ├── Dockerfile
│       └── app/
│
└── frontend/                  # Vue 3 SPA
    ├── Dockerfile
    └── src/
        ├── App.vue            # Navigation with Account link
        ├── keycloak.js
        └── views/
```

## 🛠️ Prerequisites

| Tool | Version | Purpose |
|------|---------|---------|
| Docker Desktop | ≥ 24 | Container runtime |
| Git | Any | Version control |

**That's it!** Everything else runs in containers.

## 🏃 Running Locally

### Start All Services

```bash
# Clone the repository
git clone <your-repo-url>
cd keycloak-customisation

# Start all services (builds images on first run)
docker compose up -d

# View logs
docker compose logs -f

# Check all services are running
docker compose ps
```

### Access the Application

- **Frontend**: http://localhost:5173
- **Keycloak Admin**: http://localhost:8080 (admin/admin)
- **Account Console**: http://localhost:8080/realms/blog/account/

### First Time Setup

1. Go to http://localhost:5173
2. Click "Get Started"
3. Click "Register" on the login page
4. Fill in: Email, Username, Password
5. Click "Register" (first/last name auto-filled)
6. You're logged in! Try creating a blog post
7. Click the red "Account" button to manage your profile
8. Click "← Back to Blog" to return to the frontend

## 🎨 Theme Features

### Red Color Scheme
- Primary color: `#EF4444` (red)
- Light background: `#FEE2E2` (light red)
- Consistent across login, account console, and emails

### Simplified Registration
- Only Email, Username, and Password required
- First/Last name hidden and auto-filled
- Compact, scrollable form layout

### Custom Branding
- "🚀 The Blog" logo and title
- Custom favicons for browser tabs
- "Secure Authentication Made Easy" subtitle

### Navigation
- Frontend → Account console link (red button)
- Account console → Frontend link (← Back to Blog)

## 🎨 Customizing the Theme

All theme files are in `keycloak/themes/blog-theme/`.

**Hot reload is enabled** - just edit and refresh:

```bash
# Edit CSS
vim keycloak/themes/blog-theme/login/resources/css/styles.css

# Edit templates
vim keycloak/themes/blog-theme/login/templates/login.ftl

# Changes appear immediately (Ctrl+Shift+R to hard refresh)
```

### Key Customization Points

| What to Change | File | Example |
|----------------|------|---------|
| Primary color | `login/resources/css/styles.css` | `--brand-primary: #EF4444;` |
| Logo | `login/resources/img/logo.svg` | Replace SVG file |
| Tab title | `login/messages/messages_en.properties` | `loginTitle=Your App` |
| Email header | `email/html/*.ftl` | Change inline styles |

See **[THEME_QUICK_REFERENCE.md](./THEME_QUICK_REFERENCE.md)** for complete customization guide.

## 🔑 Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                         Browser                              │
│                    Vue SPA (port 5173)                       │
│                    [Account] [Logout]                        │
└───────────────────────┬─────────────────────────────────────┘
                        │  OIDC redirect / API calls
      ┌─────────────────┼─────────────────┐
      │                 │                 │
      ▼                 ▼                 ▼
┌─────────────┐  ┌──────────────┐  ┌─────────────────┐
│  Keycloak   │  │  Auth Service│  │   Blog Service  │
│  (port 8080)│  │  FastAPI     │  │   FastAPI       │
│  Custom     │  │  (port 8001) │  │   (port 8002)   │
│  Themes     │  │              │  │   + CORS        │
└─────────────┘  └──────┬───────┘  └────────┬────────┘
                        │                    │
                        └────────┬───────────┘
                                 │
                          ┌──────▼──────┐
                          │  PostgreSQL  │
                          │  (port 5432) │
                          └─────────────┘
```

## 📚 Documentation

### Main Guides
- **[GUIDE.md](./GUIDE.md)** - Complete guide with 7 hands-on exercises covering:
  - Theme customization (colors, logos, branding)
  - Tab titles and favicons
  - Navigation between frontend and account
  - Registration form simplification
  - CSS override techniques
  - JavaScript integration
  - Troubleshooting

- **[THEME_QUICK_REFERENCE.md](./THEME_QUICK_REFERENCE.md)** - Quick reference for:
  - Theme structure
  - CSS techniques
  - Common customizations
  - Commands and best practices

## 🧪 Testing

### Test the Complete Flow
1. **Registration**: http://localhost:5173 → "Get Started" → "Register"
   - Only email, username, password required
   - Red buttons and light red background
   - Logo and "🚀 The Blog" title visible

2. **Login**: Use your credentials
   - Custom login page with red theme
   - Tab title: "Sign in to The Blog"

3. **Create Post**: After login, create a blog post
   - Tests JWT authentication
   - Tests CORS configuration

4. **Account Management**: Click red "Account" button
   - Opens Keycloak account console
   - Red theme with custom branding
   - Click "← Back to Blog" to return

## 🐛 Troubleshooting

### Theme changes don't appear
```bash
# Hard refresh browser
Ctrl+Shift+R (or Cmd+Shift+R on Mac)

# Or use incognito mode
```

### Services won't start
```bash
# Check logs
docker compose logs keycloak
docker compose logs frontend

# Restart services
docker compose restart
```

### Registration fails
- Check browser console for errors
- Verify JavaScript is enabled
- Check Keycloak logs: `docker compose logs keycloak`

### More help
See troubleshooting section in [GUIDE.md](./GUIDE.md).

## 🚢 Deployment

### Stop Services
```bash
docker compose down
```

### Rebuild After Changes
```bash
# Rebuild specific service
docker compose up -d --build frontend

# Rebuild all
docker compose up -d --build
```

### Production Considerations
- Change admin password in `docker-compose.yml`
- Update client secrets
- Configure proper CORS origins
- Use external PostgreSQL
- Enable HTTPS
- Set up email provider for verification emails

## 📖 What You'll Learn

This project teaches:
- **Keycloak Theme Customization** - CSS overrides, template structure, parent themes
- **OpenID Connect / OAuth 2.0** - Authorization code flow, PKCE, JWT validation
- **Frontend Integration** - Vue 3 with Keycloak JS adapter
- **Backend APIs** - FastAPI with JWT validation, CORS configuration
- **Docker Compose** - Multi-service orchestration
- **FreeMarker Templates** - Dynamic HTML generation
- **CSS Techniques** - Pseudo-elements, !important, PatternFly overrides
- **JavaScript Integration** - Dynamic content injection, form manipulation

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
- **Teams** needing a production-ready auth setup with custom branding
- **Anyone** wanting to understand modern authentication flows

---

**Ready to start?** → [GUIDE.md](./GUIDE.md)

**Quick reference?** → [THEME_QUICK_REFERENCE.md](./THEME_QUICK_REFERENCE.md)

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
