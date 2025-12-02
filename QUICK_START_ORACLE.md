# Quick Start: Oracle Cloud (5 Minutes)

## Prerequisites
- Email address
- 5 minutes

## Step 1: Create Account (2 minutes)
1. Go to: **https://www.oracle.com/cloud/free/**
2. Click **"Start for Free"**
3. Sign up (no credit card needed!)
4. Verify email

## Step 2: Create VM (2 minutes)
1. Login: **https://cloud.oracle.com/**
2. Menu (☰) → **Compute** → **Instances**
3. Click **"Create Instance"**
4. Configure:
   - **Name**: `microservices-vm`
   - **Image**: Ubuntu 20.04 or 22.04
   - **Shape**: VM.Standard.E2.1.Micro (Always Free)
   - **Networking**: Check "Assign public IPv4"
   - **SSH Keys**: Save both keys!
5. Click **"Create"**
6. Wait 2-3 minutes, note the **Public IP**

## Step 3: Install K3s (1 minute)
Run this script on your local machine:

```bash
cd /home/georgi/microservices/microservices1
./scripts/setup-oracle-cloud.sh
```

When prompted:
- Enter your VM's **Public IP**
- Username: `ubuntu` (or `opc` for Oracle Linux)
- Path to your **private key file**

The script will:
- ✅ Install K3s on your VM
- ✅ Configure kubectl on your local machine
- ✅ Test the connection

## Step 4: Deploy Services (1 minute)
```bash
./scripts/deploy-to-oracle.sh
```

When prompted, enter your VM's **Public IP** again.

## Step 5: Access Your Services
The script will show you the URLs, like:
- API Gateway: `http://<YOUR_IP>:<PORT>`

**Done!** Your microservices are now running in the cloud for FREE! 🎉

## Troubleshooting

### Can't SSH?
- Check Security List → Ingress Rules → Allow port 22
- Verify you're using the correct private key

### kubectl not working?
- Make sure you ran `setup-oracle-cloud.sh` first
- Check: `kubectl get nodes`

### Services not accessible?
- Check Security List allows the NodePort (30000-32767 range)
- Verify pods are running: `kubectl get pods -n microservices`

## Next Steps
- Update front-end to use cloud gateway URL
- Set up a domain name (optional)
- Configure SSL with Let's Encrypt (optional)

## Full Documentation
See `ORACLE_CLOUD_SETUP.md` for detailed instructions.
