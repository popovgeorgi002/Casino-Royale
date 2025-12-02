# Oracle Cloud Security List Configuration Guide

## Critical: Port 6443 Must Be Open

If port 6443 is not reachable, follow these EXACT steps:

### Step-by-Step Security List Configuration

1. **Log in to Oracle Cloud Console**
   - Go to: https://cloud.oracle.com/
   - Sign in to your account

2. **Navigate to Security Lists**
   - Click the hamburger menu (☰) in the top left
   - Go to: **Networking** → **Virtual Cloud Networks**
   - Click on your VCN (usually named something like `vcn-...` or `Default VCN`)
   - In the left sidebar, click **Security Lists**
   - Click on **Default Security List** (or the security list attached to your VM)

3. **Add Ingress Rule for Kubernetes API**
   - Click **Add Ingress Rules** button
   - Fill in the form:
     - **Source Type**: `CIDR`
     - **Source CIDR**: `0.0.0.0/0` (or your specific IP for better security)
     - **IP Protocol**: `TCP`
     - **Destination Port Range**: `6443` (NOT 6443-6443, just `6443`)
     - **Description**: `Kubernetes API`
   - Click **Add Ingress Rules**

4. **Verify the Rule**
   - You should see a new rule in the Ingress Rules list
   - It should show: `TCP` | `6443` | `0.0.0.0/0` (or your IP)

5. **Wait 30-60 seconds**
   - Security List changes can take a moment to propagate

### Common Mistakes

❌ **Wrong**: Adding rule to Egress Rules (should be Ingress)
❌ **Wrong**: Using port range `6443-6443` (use just `6443`)
❌ **Wrong**: Using UDP instead of TCP
❌ **Wrong**: Adding to wrong Security List (must be the one attached to your VM)

✅ **Correct**: Ingress Rule, TCP, Port 6443, Source 0.0.0.0/0

### Verify Your VM's Security List

To find which Security List your VM uses:

1. Go to **Compute** → **Instances**
2. Click on your VM instance
3. Look at the **Primary VNIC** section
4. Note the **Subnet** name
5. Go to that Subnet → **Security Lists** to see which lists are attached

### Additional Ports You May Need

For a complete microservices deployment, also open:

- **22** (SSH) - Already open by default
- **6443** (Kubernetes API) - **REQUIRED**
- **30000-32767** (NodePort range) - For services
- **80** (HTTP) - Optional
- **443** (HTTPS) - Optional

### Test After Configuration

After adding the rule, wait 1 minute, then test:

```bash
# From your local machine
nc -zv YOUR_VM_IP 6443

# Or
timeout 5 telnet YOUR_VM_IP 6443
```

If it connects, the Security List is configured correctly!
