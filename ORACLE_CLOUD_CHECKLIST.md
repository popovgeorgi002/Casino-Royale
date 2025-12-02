# Oracle Cloud Setup Checklist

Use this checklist to track your progress:

## Account Setup
- [ ] Created Oracle Cloud account at oracle.com/cloud/free
- [ ] Verified email address
- [ ] Logged into Oracle Cloud Console

## VM Creation
- [ ] Created first VM (VM.Standard.E2.1.Micro)
- [ ] Selected Ubuntu 20.04 or 22.04
- [ ] Enabled public IPv4 address
- [ ] Saved SSH private key securely
- [ ] Saved SSH public key
- [ ] Noted VM's public IP address
- [ ] VM status is "Running"

## SSH Access
- [ ] Set correct permissions on private key: `chmod 600 <key-file>`
- [ ] Tested SSH connection: `ssh -i <key> ubuntu@<IP>`
- [ ] Can successfully connect to VM

## Kubernetes Setup
- [ ] Ran `./scripts/setup-oracle-cloud.sh`
- [ ] K3s installed successfully on VM
- [ ] kubectl configured on local machine
- [ ] Tested: `kubectl get nodes` works

## Firewall Configuration
- [ ] Opened port 22 (SSH) in Security List
- [ ] Opened port 6443 (Kubernetes API) in Security List
- [ ] Opened port range 30000-32767 (NodePort) in Security List
- [ ] Opened port range 3000-3010 (Services) in Security List

## Service Deployment
- [ ] Ran `./scripts/deploy-to-oracle.sh`
- [ ] All services deployed successfully
- [ ] Pods are running: `kubectl get pods -n microservices`
- [ ] Services are accessible: `kubectl get svc -n microservices`

## Testing
- [ ] API Gateway health check works: `curl http://<IP>:<PORT>/health`
- [ ] Can access services via browser
- [ ] Front-end configured with cloud gateway URL

## Optional Enhancements
- [ ] Set up domain name
- [ ] Configured SSL/HTTPS (Let's Encrypt)
- [ ] Set up monitoring/logging
- [ ] Configured backups

## Troubleshooting Notes
_Use this space to note any issues and solutions:_



