# Microservices Debugging Guide

## Current Setup Analysis
- **user-service**: Uses Winston logger ✅
- **auth-service**: Uses console.log ⚠️
- **api-gateway**: Uses console.log ⚠️
- **Environment**: Kubernetes cluster
- **No distributed tracing**: ⚠️

## 1. Immediate Debugging Methods

### A. View Logs from Kubernetes

```bash
# View logs for a specific service
kubectl logs -n microservices deployment/user-service -f
kubectl logs -n microservices deployment/auth-service -f
kubectl logs -n microservices deployment/api-gateway -f

# View logs from all pods of a service
kubectl logs -n microservices -l app=user-service -f

# View logs with timestamps
kubectl logs -n microservices deployment/user-service --timestamps

# View last 100 lines
kubectl logs -n microservices deployment/user-service --tail=100

# View logs from a specific pod
kubectl get pods -n microservices
kubectl logs -n microservices <pod-name> -f
```

### B. Debug Script (All-in-One Log Viewer)

```bash
# Use the provided debug script
./scripts/debug-logs.sh [service-name]
```

### C. Port-Forward and Test Locally

```bash
# Port-forward all services
kubectl port-forward -n microservices svc/user-service 3000:3000 &
kubectl port-forward -n microservices svc/auth-service 3001:3001 &
kubectl port-forward -n microservices svc/api-gateway 3002:3002 &

# Test endpoints
curl http://localhost:3000/health
curl http://localhost:3001/health
curl http://localhost:3002/health
```

## 2. Structured Logging (Recommended)

### Benefits:
- Consistent log format across services
- Easy to search and filter
- Better for production debugging

### Implementation:
- ✅ user-service already uses Winston
- ⚠️ Need to add Winston to auth-service and api-gateway

## 3. Request Tracing (Critical for Microservices)

### Problem:
When a request goes: Frontend → API Gateway → Auth Service → User Service, it's hard to trace which service failed.

### Solution: Correlation IDs

Add a unique request ID that flows through all services:

```typescript
// Middleware to add correlation ID
app.use((req, res, next) => {
  req.correlationId = req.headers['x-correlation-id'] || uuid();
  res.setHeader('X-Correlation-ID', req.correlationId);
  logger.info('Request started', { 
    correlationId: req.correlationId,
    method: req.method,
    path: req.path 
  });
  next();
});
```

## 4. Debugging Tools

### A. Prisma Studio (Database Debugging)
```bash
cd user-service
kubectl port-forward -n microservices svc/postgres-service 5432:5432 &
npx prisma studio
```

### B. Network Debugging
```bash
# Check service connectivity
kubectl exec -n microservices deployment/user-service -- wget -O- http://auth-service:3001/health
kubectl exec -n microservices deployment/api-gateway -- wget -O- http://user-service:3000/health
```

### C. Resource Debugging
```bash
# Check resource usage
kubectl top pods -n microservices
kubectl describe pod <pod-name> -n microservices
```

## 5. Best Practices

### ✅ DO:
1. **Use structured logging** with correlation IDs
2. **Log at appropriate levels** (debug, info, warn, error)
3. **Include context** in logs (user ID, request ID, etc.)
4. **Use health checks** to monitor service status
5. **Log errors with stack traces**
6. **Use distributed tracing** for complex flows

### ❌ DON'T:
1. Log sensitive data (passwords, tokens)
2. Use console.log in production
3. Log too much (performance impact)
4. Ignore error handling
5. Debug in production (use staging)

## 6. Advanced: Distributed Tracing

### Option 1: OpenTelemetry (Recommended)
- Industry standard
- Works with many backends (Jaeger, Zipkin, etc.)

### Option 2: Jaeger
- Lightweight
- Good for Kubernetes

### Option 3: Custom Solution
- Simple correlation IDs
- Log aggregation (ELK stack)

## 7. Quick Debug Checklist

When debugging an issue:

1. ✅ Check service health: `kubectl get pods -n microservices`
2. ✅ View logs: `kubectl logs -n microservices deployment/<service> -f`
3. ✅ Check database: Use Prisma Studio or direct query
4. ✅ Test endpoints: Use curl or Postman
5. ✅ Check network: Verify service-to-service communication
6. ✅ Review error messages: Look for correlation IDs
7. ✅ Check resource usage: `kubectl top pods`

## 8. Common Issues & Solutions

### Issue: Service can't reach another service
```bash
# Check service DNS
kubectl exec -n microservices deployment/user-service -- nslookup auth-service
```

### Issue: Database connection failed
```bash
# Check database pod
kubectl get pods -n microservices -l app=postgres
kubectl logs -n microservices deployment/postgres
```

### Issue: Port already in use
```bash
# Find process using port
lsof -i :3000
# Kill it
kill -9 <PID>
```

## 9. Development vs Production Debugging

### Development:
- Use detailed logging (debug level)
- Run services locally when possible
- Use Prisma Studio
- Enable verbose error messages

### Production:
- Use structured logging (info level)
- Aggregate logs (ELK, Loki, etc.)
- Use distributed tracing
- Monitor metrics (Prometheus)
- Set up alerts
