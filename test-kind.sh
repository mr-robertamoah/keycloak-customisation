#!/bin/bash

# Automated test script for kind (Kubernetes) deployment
# Tests all services and endpoints in Kubernetes

set -e

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo "🧪 Testing kind (Kubernetes) Deployment"
echo "========================================"
echo ""

# Test 1: Check if kind cluster exists
echo "1️⃣  Checking kind cluster..."
if kind get clusters | grep -q "blog-cluster"; then
    echo -e "${GREEN}✓${NC} blog-cluster exists"
else
    echo -e "${RED}✗${NC} blog-cluster not found"
    echo "Run: kind create cluster --config kind-config.yaml --name blog-cluster"
    exit 1
fi

# Test 2: Check kubectl context
echo ""
echo "2️⃣  Checking kubectl context..."
CURRENT_CONTEXT=$(kubectl config current-context)
if [ "$CURRENT_CONTEXT" = "kind-blog-cluster" ]; then
    echo -e "${GREEN}✓${NC} kubectl context is set to kind-blog-cluster"
else
    echo -e "${YELLOW}⚠${NC}  Current context: $CURRENT_CONTEXT"
    echo "Switching to kind-blog-cluster..."
    kubectl config use-context kind-blog-cluster
fi

# Test 3: Check if pods are running
echo ""
echo "3️⃣  Checking pod status..."
PODS=$(kubectl get pods --no-headers 2>/dev/null | wc -l)
if [ "$PODS" -gt 0 ]; then
    echo -e "${GREEN}✓${NC} Found $PODS pods"
    
    # Check if all pods are running
    NOT_RUNNING=$(kubectl get pods --no-headers | grep -v "Running" | wc -l)
    if [ "$NOT_RUNNING" -eq 0 ]; then
        echo -e "${GREEN}✓${NC} All pods are running"
    else
        echo -e "${YELLOW}⚠${NC}  $NOT_RUNNING pods are not running"
        kubectl get pods
    fi
else
    echo -e "${RED}✗${NC} No pods found"
    echo "Run: kubectl apply -f k8s/"
    exit 1
fi

# Test 4: Check services
echo ""
echo "4️⃣  Checking services..."
SERVICES=$(kubectl get svc --no-headers | wc -l)
if [ "$SERVICES" -gt 0 ]; then
    echo -e "${GREEN}✓${NC} Found $SERVICES services"
else
    echo -e "${RED}✗${NC} No services found"
    exit 1
fi

# Test 5: Test Frontend
echo ""
echo "5️⃣  Testing Frontend..."
FRONTEND_STATUS=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:5173/ 2>/dev/null || echo "000")
if [ "$FRONTEND_STATUS" -eq 200 ]; then
    echo -e "${GREEN}✓${NC} Frontend is accessible (HTTP $FRONTEND_STATUS)"
else
    echo -e "${RED}✗${NC} Frontend is not accessible (HTTP $FRONTEND_STATUS)"
    echo "Check: kubectl logs -l app=frontend"
fi

# Test 6: Test Keycloak
echo ""
echo "6️⃣  Testing Keycloak..."
KEYCLOAK_STATUS=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:8080/health/ready 2>/dev/null || echo "000")
if [ "$KEYCLOAK_STATUS" -eq 200 ]; then
    echo -e "${GREEN}✓${NC} Keycloak is healthy (HTTP $KEYCLOAK_STATUS)"
else
    echo -e "${YELLOW}⚠${NC}  Keycloak health check returned HTTP $KEYCLOAK_STATUS"
    echo "Keycloak may still be starting up..."
fi

# Test 7: Test Auth Service
echo ""
echo "7️⃣  Testing Auth Service..."
AUTH_STATUS=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:8001/health 2>/dev/null || echo "000")
if [ "$AUTH_STATUS" -eq 200 ]; then
    echo -e "${GREEN}✓${NC} Auth Service is healthy (HTTP $AUTH_STATUS)"
else
    echo -e "${YELLOW}⚠${NC}  Auth Service returned HTTP $AUTH_STATUS"
fi

# Test 8: Test Blog Service
echo ""
echo "8️⃣  Testing Blog Service..."
BLOG_STATUS=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:8002/health 2>/dev/null || echo "000")
if [ "$BLOG_STATUS" -eq 200 ]; then
    echo -e "${GREEN}✓${NC} Blog Service is healthy (HTTP $BLOG_STATUS)"
else
    echo -e "${YELLOW}⚠${NC}  Blog Service returned HTTP $BLOG_STATUS"
fi

# Test 9: Check pod logs for errors
echo ""
echo "9️⃣  Checking for errors in pod logs..."
ERROR_COUNT=$(kubectl logs --tail=50 --all-containers=true --selector app 2>/dev/null | grep -i "error\|exception\|fatal" | wc -l)
if [ "$ERROR_COUNT" -eq 0 ]; then
    echo -e "${GREEN}✓${NC} No errors found in recent logs"
else
    echo -e "${YELLOW}⚠${NC}  Found $ERROR_COUNT error messages in logs"
    echo "Run: kubectl logs -l app=<service-name> for details"
fi

# Summary
echo ""
echo "========================================"
if [ "$FRONTEND_STATUS" -eq 200 ] && [ "$KEYCLOAK_STATUS" -eq 200 ]; then
    echo -e "${GREEN}✅ Kubernetes deployment is working!${NC}"
else
    echo -e "${YELLOW}⚠${NC}  Some services may still be starting up"
fi

echo ""
echo "Services are accessible at:"
echo "  Frontend:     http://localhost:5173"
echo "  Keycloak:     http://localhost:8080"
echo "  Auth Service: http://localhost:8001"
echo "  Blog Service: http://localhost:8002"
echo ""
echo "Useful commands:"
echo "  kubectl get pods              # Check pod status"
echo "  kubectl logs -l app=frontend  # View frontend logs"
echo "  kubectl describe pod <name>   # Debug pod issues"
echo ""
