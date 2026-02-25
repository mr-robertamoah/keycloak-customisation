#!/bin/bash

# START HERE - Quick start script
# This script helps you get started with the project

clear

cat << 'EOF'
╔══════════════════════════════════════════════════════════════════════════════╗
║                   KEYCLOAK CUSTOMIZATION PROJECT                              ║
║                            WELCOME!                                           ║
╚══════════════════════════════════════════════════════════════════════════════╝

This project teaches you Keycloak customization through hands-on practice.

📚 DOCUMENTATION AVAILABLE:

  1. DOCUMENTATION_INDEX.md - Navigation guide (START HERE!)
  2. README.md - Project overview
  3. QUICKSTART.md - 10-minute setup
  4. GUIDE.md - Complete tutorial (71 KB)
  5. MANUAL_TEST_CHECKLIST.md - Testing procedures

═══════════════════════════════════════════════════════════════════════════════

🚀 QUICK START OPTIONS:

  [1] Deploy with Docker Compose (Recommended)
  [2] Deploy to Kubernetes (kind)
  [3] Run validation checks
  [4] View documentation
  [5] Exit

═══════════════════════════════════════════════════════════════════════════════
EOF

read -p "Choose an option (1-5): " choice

case $choice in
  1)
    echo ""
    echo "🐳 Starting Docker Compose deployment..."
    echo ""
    echo "Step 1: Starting services..."
    docker compose up -d
    echo ""
    echo "Step 2: Waiting for services to be ready (30 seconds)..."
    sleep 30
    echo ""
    echo "Step 3: Running tests..."
    ./test-docker-compose.sh
    echo ""
    echo "═══════════════════════════════════════════════════════════════════════════════"
    echo "✅ Deployment complete!"
    echo ""
    echo "Next steps:"
    echo "  1. Open http://localhost:5173 in your browser"
    echo "  2. Click 'Get Started'"
    echo "  3. Register a new user"
    echo "  4. Create a blog post"
    echo ""
    echo "Read GUIDE.md for detailed explanations!"
    echo "═══════════════════════════════════════════════════════════════════════════════"
    ;;
  
  2)
    echo ""
    echo "☸️  Starting Kubernetes deployment..."
    echo ""
    echo "This will:"
    echo "  1. Stop Docker Compose (if running)"
    echo "  2. Create kind cluster"
    echo "  3. Build and load images"
    echo "  4. Deploy to Kubernetes"
    echo "  5. Run tests"
    echo ""
    read -p "Continue? (y/n): " confirm
    if [ "$confirm" = "y" ]; then
      ./deploy-kind.sh
      echo ""
      echo "═══════════════════════════════════════════════════════════════════════════════"
      echo "✅ Kubernetes deployment complete!"
      echo ""
      echo "Next steps:"
      echo "  1. Open http://localhost:5173 in your browser"
      echo "  2. Test the application"
      echo "  3. Run: kubectl get pods"
      echo ""
      echo "Read GUIDE.md sections 16-18 for Kubernetes details!"
      echo "═══════════════════════════════════════════════════════════════════════════════"
    fi
    ;;
  
  3)
    echo ""
    echo "🔍 Running validation checks..."
    echo ""
    ./validate-setup.sh
    ;;
  
  4)
    echo ""
    echo "📚 Available Documentation:"
    echo ""
    ls -lh *.md | awk '{print "  " $9 " (" $5 ")"}'
    echo ""
    echo "Start with: DOCUMENTATION_INDEX.md"
    echo ""
    read -p "Open DOCUMENTATION_INDEX.md? (y/n): " open_doc
    if [ "$open_doc" = "y" ]; then
      if command -v less &> /dev/null; then
        less DOCUMENTATION_INDEX.md
      else
        cat DOCUMENTATION_INDEX.md
      fi
    fi
    ;;
  
  5)
    echo ""
    echo "👋 Goodbye! Read DOCUMENTATION_INDEX.md to get started."
    echo ""
    exit 0
    ;;
  
  *)
    echo ""
    echo "❌ Invalid option. Please run the script again."
    echo ""
    exit 1
    ;;
esac
