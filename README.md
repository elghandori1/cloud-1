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
