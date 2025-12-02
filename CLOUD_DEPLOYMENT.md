# Cloud Deployment Options - Budget-Friendly

## Free Tier Options (Best for Testing)

### 1. **Oracle Cloud Infrastructure (OCI) - FREE Forever**
- **Cost**: $0/month (Always Free Tier)
- **Resources**:
  - 2 AMD-based Compute VMs (1/8 OCPU, 1GB RAM each)
  - 4 ARM-based Ampere A1 Compute (24GB RAM, 4 OCPUs total)
  - 10TB data transfer/month
- **Kubernetes**: Can run Kind or K3s on free VMs
- **Best for**: Development, testing, small projects
- **Setup**: Manual Kubernetes installation on VMs

### 2. **Google Cloud Platform (GCP) - Free Credits**
- **Cost**: $300 free credits (90 days), then pay-as-you-go
- **GKE Autopilot**: ~$0.10/hour for small cluster (~$72/month)
- **GKE Standard**: More control, similar pricing
- **Best for**: Production-ready Kubernetes with managed service

### 3. **AWS EKS - Free Tier**
- **Cost**: $0.10/hour for control plane (~$72/month) + worker nodes
- **Free Tier**: First 12 months get some credits
- **t3.micro instances**: ~$7.50/month each
- **Best for**: Enterprise-grade setup

### 4. **DigitalOcean - Simple & Affordable**
- **Cost**: $12/month for basic droplet (2GB RAM, 1 vCPU)
- **Managed Kubernetes**: $12/month + $6/month per node
- **Best for**: Simple, predictable pricing

### 5. **Hetzner Cloud - Cheapest EU Option**
- **Cost**: €4.15/month (CPX11: 2GB RAM, 2 vCPU)
- **Kubernetes**: Manual setup (K3s recommended)
- **Best for**: EU-based, very budget-friendly

## Recommended: Oracle Cloud (Always Free)

### Why Oracle Cloud?
- ✅ **Completely FREE forever** (not just a trial)
- ✅ 2 VMs with 1GB RAM each (enough for your microservices)
- ✅ 10TB data transfer/month
- ✅ No credit card required for free tier
- ✅ Can run Kind or K3s

### Setup Guide for Oracle Cloud

#### Step 1: Create Oracle Cloud Account
1. Go to https://www.oracle.com/cloud/free/
2. Sign up (no credit card needed for free tier)
3. Create a free tier account

#### Step 2: Create Compute Instances
```bash
# Create 2 VMs (1GB RAM each)
# Use Oracle Linux or Ubuntu
# Select: VM.Standard.E2.1.Micro (Always Free)
```

#### Step 3: Install Kubernetes (K3s - Lightweight)
```bash
# On master node
curl -sfL https://get.k3s.io | sh -

# Get kubeconfig
sudo cat /etc/rancher/k3s/k3s.yaml

# On worker nodes (if needed)
# Get token from master: sudo cat /var/lib/rancher/k3s/server/node-token
# Then run: K3S_URL=https://<master-ip>:6443 K3S_TOKEN=<token> curl -sfL https://get.k3s.io | sh -
```

#### Step 4: Deploy Your Services
```bash
# Copy kubeconfig to your local machine
# Update kubeconfig to point to Oracle Cloud VM

# Deploy services
kubectl apply -f user-service/k8s/
kubectl apply -f auth-service/k8s/
kubectl apply -f api-gateway/k8s/
kubectl apply -f deposit-service/k8s/
```

## Alternative: DigitalOcean (Simple & Predictable)

### Why DigitalOcean?
- ✅ Simple pricing ($12/month)
- ✅ Managed Kubernetes available
- ✅ Good documentation
- ✅ Easy setup

### Setup:
1. Create account at https://www.digitalocean.com
2. Create Kubernetes cluster ($12/month)
3. Add 1-2 worker nodes ($6/month each)
4. Deploy your services

**Total Cost**: ~$18-24/month

## Alternative: Hetzner Cloud (Cheapest)

### Why Hetzner?
- ✅ Very cheap (€4.15/month)
- ✅ Good performance
- ✅ EU-based (good for GDPR)
- ✅ Manual Kubernetes setup

### Setup:
1. Create account at https://www.hetzner.com/cloud
2. Create CPX11 instance (€4.15/month)
3. Install K3s manually
4. Deploy services

**Total Cost**: ~€4-8/month

## Cost Comparison

| Provider | Monthly Cost | Setup Complexity | Best For |
|----------|-------------|------------------|----------|
| **Oracle Cloud** | **$0** | Medium | Testing, Development |
| **Hetzner** | **€4-8** | Medium | Budget production |
| **DigitalOcean** | **$18-24** | Easy | Simple production |
| **GCP** | **$72+** | Easy | Enterprise |
| **AWS** | **$80+** | Medium | Enterprise |

## Recommended Architecture for Cloud

### Option 1: Single VM with K3s (Cheapest)
```
┌─────────────────────┐
│  Cloud VM (2GB RAM) │
│  - K3s Kubernetes   │
│  - All Services     │
│  - PostgreSQL       │
└─────────────────────┘
Cost: $0-8/month
```

### Option 2: Managed Kubernetes (Easier)
```
┌─────────────────────┐
│  Managed K8s       │
│  - Control Plane    │
│  - 1-2 Worker Nodes │
└─────────────────────┘
Cost: $12-24/month
```

## Migration Steps

### 1. Prepare Your Services
```bash
# Update service URLs in front-end
# Change localhost to your cloud domain/IP
```

### 2. Update Front-end Configuration
```typescript
// front-end/app/lib/api.ts
const GATEWAY_URL = process.env.NEXT_PUBLIC_GATEWAY_URL || 'https://your-cloud-ip:3002';
```

### 3. Set Up Ingress (Optional)
```yaml
# Use nginx-ingress or traefik for K3s
# This allows you to use domain names instead of IPs
```

### 4. Deploy to Cloud
```bash
# Build and push images to container registry
# Update Kubernetes manifests with cloud-specific configs
# Apply manifests to cloud cluster
```

## Security Considerations

1. **Use HTTPS**: Set up Let's Encrypt SSL certificates
2. **Firewall Rules**: Only expose necessary ports
3. **Secrets Management**: Use Kubernetes secrets (not hardcoded)
4. **Database**: Use managed database or secure PostgreSQL

## Next Steps

1. **Choose a provider** (Oracle Cloud recommended for free)
2. **Set up VM/Cluster**
3. **Install Kubernetes** (K3s for simplicity)
4. **Deploy services**
5. **Configure domain/DNS** (optional)
6. **Set up SSL** (Let's Encrypt)

## Quick Start: Oracle Cloud Free Tier

```bash
# 1. Sign up at oracle.com/cloud/free
# 2. Create 2 free VMs
# 3. Install K3s on one VM:
curl -sfL https://get.k3s.io | sh -

# 4. Get kubeconfig
sudo cat /etc/rancher/k3s/k3s.yaml

# 5. Update kubeconfig on your local machine
# 6. Deploy your services
kubectl apply -f user-service/k8s/
# ... etc
```

## Cost Optimization Tips

1. **Use smaller instances**: 1-2GB RAM is enough for testing
2. **Single node cluster**: K3s works great on single node
3. **Use free tiers**: Oracle Cloud, AWS free tier
4. **Monitor usage**: Set up billing alerts
5. **Auto-shutdown**: Schedule VMs to stop during off-hours

## Support

For help with cloud deployment:
- Oracle Cloud: https://docs.oracle.com/en-us/iaas/
- DigitalOcean: https://docs.digitalocean.com/
- K3s: https://k3s.io/
