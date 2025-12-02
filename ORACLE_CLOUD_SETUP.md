# Oracle Cloud Infrastructure - Free Tier Setup Guide

## Step-by-Step Guide to Deploy Your Microservices for FREE

### Prerequisites
- Email address (for Oracle Cloud account)
- SSH client (built into Linux/Mac, use PuTTY on Windows)
- Basic command line knowledge

---

## Part 1: Create Oracle Cloud Account

### Step 1: Sign Up
1. Go to: https://www.oracle.com/cloud/free/
2. Click **"Start for Free"**
3. Fill in your details:
   - Email address
   - Password
   - Country
   - **IMPORTANT**: Select "Individual" account type
4. **No credit card required** for free tier!
5. Verify your email

### Step 2: Complete Account Setup
1. Log in to Oracle Cloud Console: https://cloud.oracle.com/
2. Complete the account verification (may take a few minutes)
3. You'll see the dashboard

---

## Part 2: Create Free Compute Instances

### Step 3: Create Your First VM
1. In the Oracle Cloud Console, click the **hamburger menu** (☰) top left
2. Go to **Compute** → **Instances**
3. Click **"Create Instance"**

### Step 4: Configure Instance
Fill in the form:

**Name**: `microservices-vm-1`

**Image**: 
- Click **"Change Image"**
- Select **"Canonical Ubuntu"** → **20.04** or **22.04**
- Click **"Select Image"**

**Shape**:
- Click **"Change Shape"**
- Select **"VM.Standard.E2.1.Micro"** (Always Free Eligible)
- This gives you: 1/8 OCPU, 1GB RAM
- Click **"Select Shape"**

**Networking**:
- Keep default VCN (Virtual Cloud Network)
- **IMPORTANT**: Check **"Assign a public IPv4 address"**

**SSH Keys**:
- Click **"Save Private Key"** and **"Save Public Key"**
- Save both files securely! You'll need the private key to connect.

**Boot Volume**:
- Keep default (47GB - free tier includes 200GB total)

4. Click **"Create"**

### Step 5: Wait for Instance to Start
- Status will change from "Provisioning" → "Running" (takes 2-3 minutes)
- Note the **Public IP address** (you'll need this!)

### Step 6: Create Second VM (Optional but Recommended)
Repeat Steps 3-5 to create a second VM:
- Name: `microservices-vm-2`
- Same configuration (Ubuntu, E2.1.Micro, public IP)

**Why two VMs?**
- One for Kubernetes master
- One for worker (or use single VM for simplicity)

---

## Part 3: Configure SSH Access

### Step 7: Set Up SSH Keys
On your local machine:

```bash
# Make sure your private key has correct permissions
chmod 600 /path/to/your/private-key

# Test connection
ssh -i /path/to/your/private-key ubuntu@<PUBLIC_IP>
```

Replace:
- `/path/to/your/private-key` with the private key file you downloaded
- `<PUBLIC_IP>` with your VM's public IP address

If connection works, you'll see the Ubuntu welcome message!

---

## Part 4: Install Kubernetes (K3s)

### Step 8: Install K3s on Master Node
SSH into your first VM:

```bash
ssh -i /path/to/your/private-key ubuntu@<PUBLIC_IP>
```

Once connected, run:

```bash
# Update system
sudo apt-get update
sudo apt-get upgrade -y

# Install K3s (lightweight Kubernetes)
curl -sfL https://get.k3s.io | sh -

# Wait for K3s to start (about 30 seconds)
sudo systemctl status k3s

# Check if it's running
sudo k3s kubectl get nodes
```

You should see your node listed!

### Step 9: Get Kubeconfig
On your VM, run:

```bash
sudo cat /etc/rancher/k3s/k3s.yaml
```

**Copy this entire output** - you'll need it!

### Step 10: Configure kubectl on Your Local Machine
On your local machine:

```bash
# Create .kube directory if it doesn't exist
mkdir -p ~/.kube

# Save the kubeconfig
# Replace <PUBLIC_IP> with your VM's IP
# Replace the entire kubeconfig content
cat > ~/.kube/config << EOF
# Paste the kubeconfig content here, but replace:
# 127.0.0.1 → <PUBLIC_IP>
# localhost → <PUBLIC_IP>
EOF

# Or use sed to replace automatically
# First, get kubeconfig from VM and save to file
ssh -i /path/to/private-key ubuntu@<PUBLIC_IP> 'sudo cat /etc/rancher/k3s/k3s.yaml' > /tmp/k3s-config.yaml

# Replace localhost with your VM IP
sed -i "s/127.0.0.1/<PUBLIC_IP>/g" /tmp/k3s-config.yaml
sed -i "s/localhost/<PUBLIC_IP>/g" /tmp/k3s-config.yaml

# Copy to kubectl config
cp /tmp/k3s-config.yaml ~/.kube/config

# Test connection
kubectl get nodes
```

You should see your node!

---

## Part 5: Configure Firewall (Security Rules)

### Step 11: Open Required Ports
In Oracle Cloud Console:

1. Go to **Networking** → **Virtual Cloud Networks**
2. Click on your VCN
3. Click **"Security Lists"**
4. Click **"Default Security List"**
5. Click **"Add Ingress Rules"**

Add these rules:

**Rule 1: Kubernetes API**
- Source: `0.0.0.0/0` (or your IP for security)
- IP Protocol: `TCP`
- Destination Port Range: `6443`
- Description: `Kubernetes API`

**Rule 2: HTTP**
- Source: `0.0.0.0/0`
- IP Protocol: `TCP`
- Destination Port Range: `80`
- Description: `HTTP`

**Rule 3: HTTPS**
- Source: `0.0.0.0/0`
- IP Protocol: `TCP`
- Destination Port Range: `443`
- Description: `HTTPS`

**Rule 4: NodePort Range (for services)**
- Source: `0.0.0.0/0`
- IP Protocol: `TCP`
- Destination Port Range: `30000-32767`
- Description: `Kubernetes NodePort`

**Rule 5: Your Services**
- Source: `0.0.0.0/0`
- IP Protocol: `TCP`
- Destination Port Range: `3000-3010`
- Description: `Microservices`

Click **"Add Ingress Rules"** for each.

---

## Part 6: Deploy Your Microservices

### Step 12: Prepare Your Services
On your local machine:

```bash
cd /home/georgi/microservices/microservices1

# Make sure kubectl is configured
kubectl get nodes

# Create namespace
kubectl create namespace microservices

# Deploy PostgreSQL (if not using external DB)
# You may need to adjust storage class for Oracle Cloud
```

### Step 13: Update Service Manifests
You may need to update your Kubernetes manifests for cloud deployment:

1. **Update service types** to `NodePort` or `LoadBalancer` (if available)
2. **Update image pull policies** if using external registry
3. **Update resource limits** (1GB RAM is limited!)

### Step 14: Deploy Services
```bash
# Deploy all services
kubectl apply -f user-service/k8s/
kubectl apply -f auth-service/k8s/
kubectl apply -f api-gateway/k8s/
kubectl apply -f deposit-service/k8s/

# Check status
kubectl get pods -n microservices
kubectl get svc -n microservices
```

### Step 15: Access Your Services
Get your VM's public IP and access services:

```bash
# Get NodePort for a service
kubectl get svc api-gateway -n microservices

# Access via: http://<PUBLIC_IP>:<NODEPORT>
```

---

## Part 7: Deploy Front-end (Optional)

### Option A: Deploy Front-end to Same VM
```bash
# SSH into VM
ssh -i /path/to/private-key ubuntu@<PUBLIC_IP>

# Install Node.js
curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
sudo apt-get install -y nodejs

# Clone or copy your front-end
# Build and run
cd front-end
npm install
npm run build
PORT=3003 npm start
```

### Option B: Run Front-end Locally, Connect to Cloud
Update your front-end `.env.local`:

```bash
NEXT_PUBLIC_GATEWAY_URL=http://<PUBLIC_IP>:<NODEPORT>
```

---

## Troubleshooting

### Can't SSH to VM
- Check Security List rules (allow SSH port 22)
- Verify you're using the correct private key
- Check VM is in "Running" state

### kubectl Connection Refused
- Verify kubeconfig has correct IP (not 127.0.0.1)
- Check port 6443 is open in Security List
- Verify K3s is running: `sudo systemctl status k3s` on VM

### Pods Not Starting
- Check resources: `kubectl describe pod <pod-name> -n microservices`
- 1GB RAM is limited - reduce resource requests if needed
- Check logs: `kubectl logs <pod-name> -n microservices`

### Services Not Accessible
- Verify NodePort is in range 30000-32767
- Check Security List allows the port
- Test from VM: `curl http://localhost:<port>`

---

## Resource Limits & Optimization

### Free Tier Limits:
- **2 VMs**: 1/8 OCPU, 1GB RAM each
- **Total**: ~2GB RAM, 2/8 OCPU
- **Storage**: 200GB total

### Optimization Tips:
1. **Use single VM** for testing (saves resources)
2. **Reduce resource requests** in your deployments
3. **Use K3s** (lightweight, perfect for small VMs)
4. **Consider ARM instances** (4 ARM VMs with 24GB total RAM!)

### Resource Recommendations:
```yaml
# In your deployment.yaml, use:
resources:
  requests:
    memory: "128Mi"
    cpu: "100m"
  limits:
    memory: "256Mi"
    cpu: "200m"
```

---

## Next Steps

1. ✅ Set up Oracle Cloud account
2. ✅ Create VMs
3. ✅ Install K3s
4. ✅ Configure kubectl
5. ✅ Deploy services
6. ✅ Access via web browser

## Quick Reference

**VM Public IP**: `<YOUR_VM_IP>`

**Access Services**:
- API Gateway: `http://<YOUR_VM_IP>:<NODEPORT>`
- Health Check: `http://<YOUR_VM_IP>:<NODEPORT>/health`

**Useful Commands**:
```bash
# On VM
sudo systemctl status k3s
sudo k3s kubectl get nodes

# On local machine
kubectl get pods -n microservices
kubectl logs <pod-name> -n microservices
kubectl get svc -n microservices
```

---

## Support

- Oracle Cloud Docs: https://docs.oracle.com/en-us/iaas/
- K3s Docs: https://docs.k3s.io/
- Free Tier FAQ: https://www.oracle.com/cloud/free/faq/
