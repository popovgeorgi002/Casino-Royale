# Quick Debugging Reference

## 🚀 Quick Commands

### View Logs
```bash
# All services
./scripts/debug-logs.sh logs

# Specific service
./scripts/debug-logs.sh logs user-service
./scripts/debug-logs.sh logs auth-service
./scripts/debug-logs.sh logs api-gateway

# Follow logs in real-time
./scripts/debug-logs.sh follow user-service
```

### Check Status
```bash
./scripts/debug-logs.sh status
kubectl get pods -n microservices
```

### Search Logs
```bash
# Search all services
./scripts/debug-logs.sh search "error"

# Search specific service
./scripts/debug-logs.sh search "error" user-service
```

### View Errors
```bash
./scripts/debug-logs.sh errors
```

### Debug Database
```bash
# Check users in user-service DB
cd user-service
./scripts/check-users.sh

# Open Prisma Studio
kubectl port-forward -n microservices svc/postgres-service 5432:5432 &
npx prisma studio
```

### Test Services
```bash
# Health checks
curl http://localhost:3000/health  # user-service
curl http://localhost:3001/health  # auth-service
curl http://localhost:3002/health  # api-gateway
```

### Common Issues

**Service not responding:**
```bash
kubectl get pods -n microservices
kubectl describe pod <pod-name> -n microservices
kubectl logs <pod-name> -n microservices
```

**Database connection issues:**
```bash
kubectl get pods -n microservices -l app=postgres
kubectl logs -n microservices deployment/postgres
```

**Network issues:**
```bash
kubectl exec -n microservices deployment/user-service -- wget -O- http://auth-service:3001/health
```

## 📊 Best Practices

1. **Always check logs first** - Most issues show up in logs
2. **Use correlation IDs** - Track requests across services
3. **Check health endpoints** - Quick way to verify service status
4. **Monitor resource usage** - `kubectl top pods -n microservices`
5. **Use structured logging** - Easier to search and filter

## 🔍 Debugging Workflow

1. **Identify the issue** - What's not working?
2. **Check service status** - `./scripts/debug-logs.sh status`
3. **View relevant logs** - `./scripts/debug-logs.sh logs <service>`
4. **Search for errors** - `./scripts/debug-logs.sh errors`
5. **Check database** - If data-related issue
6. **Test endpoints** - Verify service connectivity
7. **Check resources** - CPU/Memory issues
