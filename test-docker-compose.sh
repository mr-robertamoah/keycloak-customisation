#!/bin/bash

# Automated test script for Docker Compose deployment
# Tests all services and endpoints

set -e

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo "🧪 Testing Docker Compose Deployment"
echo "====================================="
echo ""

# Test 1: Check if all containers are running
echo "1️⃣  Checking container status..."
CONTAINERS=$(docker compose ps --format json | jq -r '.Name' | wc -l)
if [ "$CONTAINERS" -eq 5 ]; then
    echo -e "${GREEN}✓${NC} All 5 containers are running"
else
    echo -e "${RED}✗${NC} Expected 5 containers, found $CONTAINERS"
    docker compose ps
    exit 1
fi

# Test 2: Check PostgreSQL
echo ""
echo "2️⃣  Testing PostgreSQL..."
if docker compose exec -T postgres pg_isready -U keycloak > /dev/null 2>&1; then
    echo -e "${GREEN}✓${NC} PostgreSQL is ready"
else
    echo -e "${RED}✗${NC} PostgreSQL is not ready"
    exit 1
fi

# Test 3: Check Keycloak
echo ""
echo "3️⃣  Testing Keycloak..."
KEYCLOAK_STATUS=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:8080/health/ready)
if [ "$KEYCLOAK_STATUS" -eq 200 ]; then
    echo -e "${GREEN}✓${NC} Keycloak is healthy (HTTP $KEYCLOAK_STATUS)"
else
    echo -e "${RED}✗${NC} Keycloak health check failed (HTTP $KEYCLOAK_STATUS)"
    exit 1
fi

# Test 4: Check if blog realm was imported
echo ""
echo "4️⃣  Testing Keycloak realm import..."
REALM_CHECK=$(curl -s http://localhost:8080/realms/blog | jq -r '.realm' 2>/dev/null || echo "")
if [ "$REALM_CHECK" = "blog" ]; then
    echo -e "${GREEN}✓${NC} Blog realm imported successfully"
else
    echo -e "${YELLOW}⚠${NC}  Blog realm not found (may need manual import)"
fi

# Test 5: Check custom theme
echo ""
echo "5️⃣  Testing custom theme..."
THEME_CHECK=$(curl -s http://localhost:8080/realms/blog/account | grep -o "blog-theme" | head -1 || echo "")
if [ -n "$THEME_CHECK" ]; then
    echo -e "${GREEN}✓${NC} Custom theme is loaded"
else
    echo -e "${YELLOW}⚠${NC}  Custom theme may not be applied (check realm settings)"
fi

# Test 6: Check Auth Service
echo ""
echo "6️⃣  Testing Auth Service..."
AUTH_STATUS=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:8001/health)
if [ "$AUTH_STATUS" -eq 200 ]; then
    AUTH_RESPONSE=$(curl -s http://localhost:8001/health | jq -r '.service')
    if [ "$AUTH_RESPONSE" = "auth-service" ]; then
        echo -e "${GREEN}✓${NC} Auth Service is healthy"
    else
        echo -e "${YELLOW}⚠${NC}  Auth Service responded but unexpected response"
    fi
else
    echo -e "${RED}✗${NC} Auth Service health check failed (HTTP $AUTH_STATUS)"
    exit 1
fi

# Test 7: Check Blog Service
echo ""
echo "7️⃣  Testing Blog Service..."
BLOG_STATUS=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:8002/health)
if [ "$BLOG_STATUS" -eq 200 ]; then
    BLOG_RESPONSE=$(curl -s http://localhost:8002/health | jq -r '.service')
    if [ "$BLOG_RESPONSE" = "blog-service" ]; then
        echo -e "${GREEN}✓${NC} Blog Service is healthy"
    else
        echo -e "${YELLOW}⚠${NC}  Blog Service responded but unexpected response"
    fi
else
    echo -e "${RED}✗${NC} Blog Service health check failed (HTTP $BLOG_STATUS)"
    exit 1
fi

# Test 8: Check Frontend
echo ""
echo "8️⃣  Testing Frontend..."
FRONTEND_STATUS=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:5173/)
if [ "$FRONTEND_STATUS" -eq 200 ]; then
    echo -e "${GREEN}✓${NC} Frontend is serving (HTTP $FRONTEND_STATUS)"
    
    # Check if it's actually the Vue app
    FRONTEND_CONTENT=$(curl -s http://localhost:5173/ | grep -o "vite" | head -1 || echo "")
    if [ -n "$FRONTEND_CONTENT" ]; then
        echo -e "${GREEN}✓${NC} Frontend is serving Vue application"
    fi
else
    echo -e "${RED}✗${NC} Frontend is not accessible (HTTP $FRONTEND_STATUS)"
    exit 1
fi

# Test 9: Test Keycloak admin login
echo ""
echo "9️⃣  Testing Keycloak admin access..."
ADMIN_TOKEN=$(curl -s -X POST http://localhost:8080/realms/master/protocol/openid-connect/token \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "username=admin" \
  -d "password=admin" \
  -d "grant_type=password" \
  -d "client_id=admin-cli" | jq -r '.access_token' 2>/dev/null || echo "")

if [ -n "$ADMIN_TOKEN" ] && [ "$ADMIN_TOKEN" != "null" ]; then
    echo -e "${GREEN}✓${NC} Keycloak admin login successful"
else
    echo -e "${RED}✗${NC} Keycloak admin login failed"
    exit 1
fi

# Test 10: Check if clients exist in blog realm
echo ""
echo "🔟  Testing Keycloak clients..."
CLIENTS=$(curl -s -H "Authorization: Bearer $ADMIN_TOKEN" \
  http://localhost:8080/admin/realms/blog/clients | jq -r '.[].clientId' 2>/dev/null || echo "")

if echo "$CLIENTS" | grep -q "blog-frontend"; then
    echo -e "${GREEN}✓${NC} blog-frontend client exists"
else
    echo -e "${YELLOW}⚠${NC}  blog-frontend client not found"
fi

if echo "$CLIENTS" | grep -q "auth-service"; then
    echo -e "${GREEN}✓${NC} auth-service client exists"
else
    echo -e "${YELLOW}⚠${NC}  auth-service client not found"
fi

if echo "$CLIENTS" | grep -q "blog-service"; then
    echo -e "${GREEN}✓${NC} blog-service client exists"
else
    echo -e "${YELLOW}⚠${NC}  blog-service client not found"
fi

# Summary
echo ""
echo "====================================="
echo -e "${GREEN}✅ All critical tests passed!${NC}"
echo ""
echo "Services are accessible at:"
echo "  Frontend:    http://localhost:5173"
echo "  Keycloak:    http://localhost:8080"
echo "  Auth Service: http://localhost:8001"
echo "  Blog Service: http://localhost:8002"
echo ""
echo "Next steps:"
echo "  1. Open http://localhost:5173 in your browser"
echo "  2. Click 'Get Started' to test the login flow"
echo "  3. Register a new user to see the custom theme"
echo ""
