#!/bin/bash

# Test script for Keycloak Customization Project
# This script validates the setup and provides helpful feedback

set -e

echo "🔍 Keycloak Customization Project - Setup Validator"
echo "=================================================="
echo ""

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check functions
check_command() {
    if command -v $1 &> /dev/null; then
        echo -e "${GREEN}✓${NC} $1 is installed"
        return 0
    else
        echo -e "${RED}✗${NC} $1 is not installed"
        return 1
    fi
}

check_file() {
    if [ -f "$1" ]; then
        echo -e "${GREEN}✓${NC} $1 exists"
        return 0
    else
        echo -e "${RED}✗${NC} $1 is missing"
        return 1
    fi
}

check_dir() {
    if [ -d "$1" ]; then
        echo -e "${GREEN}✓${NC} $1 exists"
        return 0
    else
        echo -e "${RED}✗${NC} $1 is missing"
        return 1
    fi
}

# 1. Check prerequisites
echo "1️⃣  Checking Prerequisites..."
check_command docker || MISSING_DEPS=1
check_command docker-compose || check_command "docker compose" || MISSING_DEPS=1

if [ ! -z "$MISSING_DEPS" ]; then
    echo -e "${RED}Missing required dependencies. Please install Docker Desktop.${NC}"
    exit 1
fi
echo ""

# 2. Check project structure
echo "2️⃣  Checking Project Structure..."
check_file "docker-compose.yml" || exit 1
check_file "QUICKSTART.md" || exit 1
check_file "README.md" || exit 1
check_file "guide.md" || exit 1
check_dir "keycloak/themes/blog-theme" || exit 1
check_dir "services/auth-service" || exit 1
check_dir "services/blog-service" || exit 1
check_dir "frontend" || exit 1
check_dir "k8s" || exit 1
echo ""

# 3. Check frontend files
echo "3️⃣  Checking Frontend Files..."
check_file "frontend/package.json" || exit 1
check_file "frontend/vite.config.js" || exit 1
check_file "frontend/Dockerfile" || exit 1
check_file "frontend/nginx.conf" || exit 1
check_file "frontend/src/main.js" || exit 1
check_file "frontend/src/App.vue" || exit 1
check_file "frontend/src/keycloak.js" || exit 1
check_file "frontend/src/views/Home.vue" || exit 1
check_file "frontend/src/views/Blog.vue" || exit 1
echo ""

# 4. Check theme files
echo "4️⃣  Checking Theme Files..."
check_file "keycloak/themes/blog-theme/login/theme.properties" || exit 1
check_file "keycloak/themes/blog-theme/login/resources/css/styles.css" || exit 1
check_file "keycloak/themes/blog-theme/login/templates/login.ftl" || exit 1
check_file "keycloak/themes/blog-theme/login/templates/register.ftl" || exit 1
echo ""

# 5. Check backend files
echo "5️⃣  Checking Backend Files..."
check_file "services/auth-service/Dockerfile" || exit 1
check_file "services/auth-service/requirements.txt" || exit 1
check_file "services/auth-service/app/main.py" || exit 1
check_file "services/blog-service/Dockerfile" || exit 1
check_file "services/blog-service/requirements.txt" || exit 1
check_file "services/blog-service/app/main.py" || exit 1
echo ""

# 6. Check Kubernetes files
echo "6️⃣  Checking Kubernetes Files..."
check_file "kind-config.yaml" || exit 1
check_file "k8s/frontend.yaml" || exit 1
echo ""

# 7. Validate docker-compose
echo "7️⃣  Validating Docker Compose Configuration..."
if docker compose config > /dev/null 2>&1; then
    echo -e "${GREEN}✓${NC} docker-compose.yml is valid"
else
    echo -e "${RED}✗${NC} docker-compose.yml has errors"
    docker compose config
    exit 1
fi
echo ""

# 8. Check if services are running
echo "8️⃣  Checking Running Services..."
if docker compose ps | grep -q "Up"; then
    echo -e "${YELLOW}⚠${NC}  Some services are already running"
    echo "Run 'docker compose ps' to see status"
else
    echo -e "${GREEN}✓${NC} No services currently running"
fi
echo ""

# Summary
echo "=================================================="
echo -e "${GREEN}✅ All checks passed!${NC}"
echo ""
echo "Next steps:"
echo "1. Start services: docker compose up -d"
echo "2. Follow QUICKSTART.md for Keycloak configuration"
echo "3. Access frontend at http://localhost:5173"
echo ""
echo "For detailed instructions, see:"
echo "  - QUICKSTART.md (10-minute setup)"
echo "  - README.md (overview)"
echo "  - guide.md (complete reference)"
echo ""
