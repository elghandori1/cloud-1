## Architecture Overview

```

    ┌────────────▼────────────┐
    │   YOUR LAPTOP           │
    │   (Ansible Controller)  │
    └────────────┬────────────┘
                 │ SSH (Port 22)
                 ▼
    ┌─────────────────────────────────────────────┐
    │   CLOUD VM (Ubuntu 22.04 LTS)               │
    │  ┌─────────────────────────────────────┐    │
    │  │  UFW Firewall: ALLOW 22,80,443     │    │
    │  │  DENY everything else inbound        │    │
    │  └─────────────────────────────────────┘    │
    │  ┌─────────────────────────────────────┐    │
    │  │  Docker + Docker Compose installed   │    │
    │  └─────────────────────────────────────┘    │
    │  ┌─────────────────────────────────────┐    │
    │  │  Nginx Container (Reverse Proxy)     │    │
    │  │  - TLS/HTTPS (Let's Encrypt)         │    │
    │  │  - Routes: / → WordPress             │    │
    │  │            /pma → phpMyAdmin         │    │
    │  └──────┬──────────────────┬───────────┘    │
    │         │                  │                │
    │  ┌──────▼──────┐   ┌──────▼──────┐         │
    │  │ WordPress   │   │ phpMyAdmin  │         │
    │  │ (PHP-FPM)   │   │ (Web UI)    │         │
    │  └──────┬──────┘   └─────────────┘         │
    │         │                                   │
    │  ┌──────▼──────┐                          │
    │  │  MariaDB    │  ◄── Port 3306 NOT        │
    │  │  (Database) │      exposed to internet  │
    │  └─────────────┘                          │
    │                                             │
    │  Volumes (persistent across reboots):      │
    │    - wordpress_data:/var/www/html          │
    │    - db_data:/var/lib/mysql                │
    │    - certs_data:/etc/letsencrypt           │
    └─────────────────────────────────────────────┘
```

- **However**, When you create a droplet with SSH key authentication, you connect as `root` , And using **`root`** for daily operations is a **bad security practice**:
    
    
    | Risk | Why It's Dangerous |
    | --- | --- |
    | No audit trail | Can't tell who did what |
    | Accidental destruction | `rm -rf /` runs without any protection |
    | Malware runs as root | Full system compromise |
    | Brute force target | Attackers always try `root` first |
    
    The correct flow: connect as `root` → create `ubuntu` user → switch to `ubuntu` for daily use.
    
    ```
    ┌─────────────────────────────────────────┐
    │  ROOT ACCOUNT                           │
    │  • Used for: initial setup, emergencies │
    │  • SSH: disabled password, key only     │
    │  • Daily use: NO                        │
    └─────────────────────────────────────────┘
    │
    ▼
    ┌─────────────────────────────────────────┐
    │  UBUNTU USER (or your name)             │
    │  • Used for: daily work, Ansible runs   │
    │  • Has sudo privileges                  │
    │  • Can become root when needed          │
    └─────────────────────────────────────────┘
    ```
    
- **COMPLETE STEP-BY-STEP CREATE ubuntu USER (or login shool)**
    - **Step-by-Step: Create `ubuntu` User Properly**
        - SSH into your droplet as `root`, then create the user:
            
            ```bash
            SSH as root (this works now)
            ssh -i ~/.ssh/cloud1_key root@DROPLET_IP
            ```
            
        - **Create the `ubuntu` user**
            
            ```bash
            # Create user with home directory and bash shell
            useradd -m -s /bin/bash ubuntu
            
            # Set a password (you'll type it twice 12345)
            passwd ubuntu
            
            # Add to sudo group
            usermod -aG sudo ubuntu
            ```
            
        - **Add your SSH key to `ubuntu` user**
            
            ```bash
            # Create .ssh directory
            mkdir -p /home/ubuntu/.ssh
            
            # Copy your public key
            cp /root/.ssh/authorized_keys /home/ubuntu/.ssh/authorized_keys
            
            # Fix ownership and permissions
            chown -R ubuntu:ubuntu /home/ubuntu/.ssh
            chmod 700 /home/ubuntu/.ssh
            chmod 600 /home/ubuntu/.ssh/authorized_keys
            
            # to allow passwordless sudo
            echo "ubuntu ALL=(ALL) NOPASSWD:ALL" | tee /etc/sudoers.d/ubuntu
            ```
            
        - **Harden SSH (Disable root login, disable password auth)**
            
            ```bash
            # Edit SSH config
            nano /etc/ssh/sshd_config
            ```
            
        - **Edit `/etc/ssh/sshd_config` as root inside the droplet:**
            
            ```bash
            # Disable root login via SSH and without password
            PermitRootLogin prohibit-password
            
            # Disables password logins for ALL users. (only keys)
            PasswordAuthentication no
            
            # Allows SSH key authentication
            PubkeyAuthentication yes
            ```
            
        - Save (`Ctrl+O`, `Enter`, `Ctrl+X`), then restart SSH: **`systemctl restart sshd`  or `systemctl restart ssh`**
        - **Test: Can you login as `ubuntu`**
            - **Open a NEW terminal** (don't close the root session yet — you might lock yourself out!):
            
            ```bash
            # From your laptop, NEW terminal
            ssh -i ~/.ssh/cloud1_key ubuntu@DROPLET_IP
            ```
            
        - **(Optional but recommended) Lock root password**
            
            ```bash
            # As root, lock the root password (can't login with password)
            passwd -l root
            ```