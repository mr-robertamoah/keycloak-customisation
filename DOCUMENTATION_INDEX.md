# 📚 Documentation Index

Welcome to the Keycloak Customization Project! This index helps you find the right documentation for your needs.

## 🚀 Getting Started (Start Here!)

### For First-Time Users
1. **[README.md](./README.md)** (9 KB) - Project overview and quick links
2. **[QUICKSTART.md](./QUICKSTART.md)** (16 KB) - 10-minute setup guide
3. **[PROJECT_COMPLETE.md](./PROJECT_COMPLETE.md)** (13 KB) - What's been built and how to use it

### For Learning
4. **[GUIDE.md](./GUIDE.md)** (71 KB) ⭐ **MAIN TUTORIAL**
   - Complete hands-on tutorial
   - Explains concepts before doing
   - Docker Compose section (complete)
   - Kubernetes section (complete)
   - Manual testing procedures
   - Troubleshooting guide

## 📖 Reference Documentation

### Technical Details
5. **[SETUP_SUMMARY.md](./SETUP_SUMMARY.md)** (11 KB) - Technical architecture and fixes applied
6. **[guide-reference.md](./guide-reference.md)** (77 KB) - Original detailed reference guide

### Testing
7. **[TEST_RESULTS.md](./TEST_RESULTS.md)** (6 KB) - Automated test results
8. **[MANUAL_TEST_CHECKLIST.md](./MANUAL_TEST_CHECKLIST.md)** (6 KB) - Step-by-step testing checklist

## 🎯 Choose Your Path

### Path 1: "I just want it working"
```
README.md → QUICKSTART.md → Test in browser
```
**Time: 15 minutes**

### Path 2: "I want to understand everything"
```
README.md → GUIDE.md (read sections 1-15) → Test → GUIDE.md (sections 16-23)
```
**Time: 2-3 hours**

### Path 3: "I need to customize it"
```
QUICKSTART.md → Get it running → GUIDE.md (section 8) → Customize theme
```
**Time: 30 minutes**

### Path 4: "I'm deploying to production"
```
GUIDE.md → Test locally → GUIDE.md (section 23) → Deploy
```
**Time: 4-6 hours**

## 📋 Documentation by Topic

### Deployment
- **Docker Compose**: GUIDE.md sections 4, 6
- **Kubernetes**: GUIDE.md sections 16-18
- **Automated Scripts**: `./deploy-kind.sh`, `./test-docker-compose.sh`

### Authentication
- **Keycloak Concepts**: GUIDE.md section 5
- **JWT Validation**: GUIDE.md sections 9-10
- **Service-to-Service**: GUIDE.md section 11
- **Frontend Integration**: GUIDE.md sections 13-14

### Theme Customization
- **Understanding Themes**: GUIDE.md section 7
- **Customizing**: GUIDE.md section 8
- **FreeMarker Reference**: GUIDE.md section 20
- **Email Templates**: GUIDE.md section 21

### Testing
- **Manual Testing**: GUIDE.md sections 6, 15, 18
- **API Testing**: GUIDE.md section 12
- **Automated Tests**: TEST_RESULTS.md
- **Checklists**: MANUAL_TEST_CHECKLIST.md

### Troubleshooting
- **Common Issues**: GUIDE.md section 22
- **Docker Compose**: QUICKSTART.md "Troubleshooting" section
- **Kubernetes**: GUIDE.md section 18

## 🔧 Scripts and Tools

### Deployment Scripts
- `./deploy-kind.sh` - Deploy to Kubernetes (one command)
- `docker compose up -d` - Deploy with Docker Compose

### Testing Scripts
- `./test-docker-compose.sh` - Test Docker Compose deployment
- `./test-kind.sh` - Test Kubernetes deployment
- `./validate-setup.sh` - Validate project structure

### Utility Scripts
- `docker compose logs -f` - View logs
- `kubectl get pods` - Check Kubernetes status
- `docker compose down` - Stop services

## 📊 Documentation Statistics

| File | Size | Purpose | Audience |
|------|------|---------|----------|
| README.md | 9 KB | Overview | Everyone |
| QUICKSTART.md | 16 KB | Quick setup | Beginners |
| GUIDE.md | 71 KB | Complete tutorial | Learners |
| guide-reference.md | 77 KB | Detailed reference | Advanced |
| PROJECT_COMPLETE.md | 13 KB | Summary | Project managers |
| SETUP_SUMMARY.md | 11 KB | Technical details | Developers |
| TEST_RESULTS.md | 6 KB | Test results | QA/Testers |
| MANUAL_TEST_CHECKLIST.md | 6 KB | Testing steps | QA/Testers |

**Total Documentation: ~210 KB / ~35,000 words**

## 🎓 Learning Objectives by Document

### README.md
- ✓ Understand what the project does
- ✓ Know where to start
- ✓ See the architecture overview

### QUICKSTART.md
- ✓ Get services running in 10 minutes
- ✓ Configure Keycloak
- ✓ Test the application
- ✓ Troubleshoot common issues

### GUIDE.md (Main Tutorial)
- ✓ Understand Keycloak concepts (realms, clients, tokens)
- ✓ Deploy with Docker Compose
- ✓ Test manually to verify everything works
- ✓ Understand JWT authentication
- ✓ Customize themes with hot reload
- ✓ Understand backend services
- ✓ Implement service-to-service auth
- ✓ Integrate Vue frontend
- ✓ Deploy to Kubernetes
- ✓ Compare Docker Compose vs Kubernetes
- ✓ Learn FreeMarker templating
- ✓ Troubleshoot issues
- ✓ Prepare for production

### MANUAL_TEST_CHECKLIST.md
- ✓ Verify Docker Compose deployment
- ✓ Verify Kubernetes deployment
- ✓ Test all features manually
- ✓ Validate authentication flows
- ✓ Check service-to-service communication

## 🔍 Quick Reference

### Common Commands

**Docker Compose:**
```bash
docker compose up -d              # Start
docker compose ps                 # Status
docker compose logs -f            # Logs
docker compose down               # Stop
./test-docker-compose.sh          # Test
```

**Kubernetes:**
```bash
./deploy-kind.sh                  # Deploy
kubectl get pods                  # Status
kubectl logs -f <pod>             # Logs
./test-kind.sh                    # Test
kind delete cluster --name blog-cluster  # Clean up
```

**Testing:**
```bash
# Frontend
open http://localhost:5173

# Keycloak
open http://localhost:8080

# Get user token
curl -X POST http://localhost:8080/realms/blog/protocol/openid-connect/token \
  -d "username=testuser" \
  -d "password=Test123!" \
  -d "grant_type=password" \
  -d "client_id=blog-frontend"
```

### Service URLs

| Service | Docker Compose | Kubernetes | Purpose |
|---------|----------------|------------|---------|
| Frontend | http://localhost:5173 | http://localhost:5173 | Vue SPA |
| Keycloak | http://localhost:8080 | http://localhost:8080 | Auth server |
| Auth Service | http://localhost:8001 | http://localhost:8001 | User API |
| Blog Service | http://localhost:8002 | http://localhost:8002 | Posts API |

### Default Credentials

| Service | Username | Password |
|---------|----------|----------|
| Keycloak Admin | admin | admin |
| Test User | testuser | Test123! |
| PostgreSQL | keycloak | keycloak_secret |

## 💡 Tips

1. **Start with QUICKSTART.md** - Get it running first, understand later
2. **Read GUIDE.md in order** - It's designed as a tutorial
3. **Use the test scripts** - They verify everything works
4. **Check logs when stuck** - `docker compose logs -f` or `kubectl logs`
5. **Hot reload is enabled** - Edit theme files and refresh browser

## 🆘 Getting Help

1. **Check the troubleshooting section**: GUIDE.md section 22
2. **Run validation**: `./validate-setup.sh`
3. **Check test results**: TEST_RESULTS.md
4. **Review checklist**: MANUAL_TEST_CHECKLIST.md
5. **Check logs**: `docker compose logs -f` or `kubectl logs -f <pod>`

## 📝 Document Versions

- **GUIDE.md**: v2.0 - Complete rewrite (tutorial-style)
- **guide-reference.md**: v1.0 - Original guide (reference)
- **All other docs**: v1.0 - New documentation

## 🎯 Success Criteria

After reading the appropriate documentation, you should be able to:

- [ ] Deploy with Docker Compose
- [ ] Deploy to Kubernetes
- [ ] Customize the theme
- [ ] Understand JWT authentication
- [ ] Test all features manually
- [ ] Troubleshoot common issues
- [ ] Prepare for production deployment

---

**Start here:** [README.md](./README.md) → [QUICKSTART.md](./QUICKSTART.md) → [GUIDE.md](./GUIDE.md)

**Happy learning!** 🚀
