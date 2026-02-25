#!/bin/bash

# Deploy to kind (Kubernetes) cluster
# This script automates the entire deployment process

set -e

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo "🚀 Deploying to kind (Kubernetes)"
echo "=================================="
echo ""

# Step 1: Stop Docker Compose if running
echo "1️⃣  Stopping Docker Compose (if running)..."
cd "$(dirname "$0")"
docker compose down 2>/dev/null || true
echo -e "${GREEN}✓${NC} Docker Compose stopped"

# Step 2: Create kind cluster
echo ""
echo "2️⃣  Creating kind cluster..."
if kind get clusters | grep -q "blog-cluster"; then
    echo -e "${YELLOW}⚠${NC}  Cluster already exists, deleting..."
    kind delete cluster --name blog-cluster
fi
kind create cluster --config kind-config.yaml --name blog-cluster
echo -e "${GREEN}✓${NC} Cluster created"

# Step 3: Build images
echo ""
echo "3️⃣  Building Docker images..."
docker build -t blog-frontend:latest ./frontend
docker build -t blog-keycloak:latest -f keycloak/Dockerfile ./keycloak
docker build -t auth-service:latest ./services/auth-service
docker build -t blog-service:latest ./services/blog-service
echo -e "${GREEN}✓${NC} Images built"

# Step 4: Load images into kind
echo ""
echo "4️⃣  Loading images into kind..."
kind load docker-image blog-frontend:latest --name blog-cluster
kind load docker-image blog-keycloak:latest --name blog-cluster
kind load docker-image auth-service:latest --name blog-cluster
kind load docker-image blog-service:latest --name blog-cluster
echo -e "${GREEN}✓${NC} Images loaded"

# Step 5: Deploy to Kubernetes
echo ""
echo "5️⃣  Deploying to Kubernetes..."
kubectl apply -f k8s/postgres.yaml
kubectl apply -f k8s/keycloak.yaml
kubectl apply -f k8s/auth-service.yaml
kubectl apply -f k8s/blog-service.yaml
kubectl apply -f k8s/frontend.yaml
echo -e "${GREEN}✓${NC} Manifests applied"

# Step 6: Wait for pods
echo ""
echo "6️⃣  Waiting for pods to be ready..."
echo "This may take 1-2 minutes..."
kubectl wait --for=condition=ready pod -l app=postgres --timeout=120s
kubectl wait --for=condition=ready pod -l app=keycloak --timeout=180s
kubectl wait --for=condition=ready pod -l app=auth-service --timeout=120s
kubectl wait --for=condition=ready pod -l app=blog-service --timeout=120s
kubectl wait --for=condition=ready pod -l app=frontend --timeout=120s
echo -e "${GREEN}✓${NC} All pods are ready"

# Step 7: Show status
echo ""
echo "=================================="
echo -e "${GREEN}✅ Deployment complete!${NC}"
echo ""
echo "Services are accessible at:"
echo "  Frontend:     http://localhost:5173"
echo "  Keycloak:     http://localhost:8080"
echo "  Auth Service: http://localhost:8001"
echo "  Blog Service: http://localhost:8002"
echo ""
echo "Check status:"
echo "  kubectl get pods"
echo "  kubectl get svc"
echo ""
echo "Run tests:"
echo "  ./test-kind.sh"
echo ""
