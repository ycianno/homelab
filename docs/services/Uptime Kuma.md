---
tags:
  - homelab
  - service
  - monitoring
created: 2026-05-30
---

# Uptime Kuma

## 📋 Overview
- **Purpose:** Self-hosted uptime monitoring tool to track service availability and alerting.
- **Host:** [automation-01](../Servers/automation-01.md) (`10.0.0.67`)
- **Port:** `3001`
- **Internal URL:** [https://kuma.local.yourdomain.com](https://kuma.local.yourdomain.com) (Internal IP: `https://kuma.local.yourdomain.com (Internal IP: `http://kuma.local.yourdomain.com (`10.0.0.67:3001`)`)`)
- **Config / Stack Path:** `/opt/stacks/uptime-kuma` (Docker Compose)

## 🔧 Monitored Targets
Uptime Kuma is configured as the **source of truth** for service monitoring:
- **docker-01** (Server ping)
- **Dozzle** (Port 8088 check)
- **n8n** (Port 5678 check)
- **Nextcloud** (HTTP check)
- **Portainer Agent** (Port 9001 check)
- **Portainer automation-01** (HTTPS check)
- **Proxmox** (Host ping)
- **Semaphore** (Port 3005 check)
- **Pi-hole Web** (HTTP check to `https://pihole.local.yourdomain.com/admin`; internal endpoint `http://10.0.0.20/admin`)
- **Pi-hole DNS** (DNS A-record query for `google.com` using resolver `10.0.0.20`)

## 💾 Backup & Recovery
- SQLite database resides in the mapped volume under `/opt/stacks/uptime-kuma`.
- Back up the state folder to preserve configuration history.

## 🔗 Related
- [automation-01](../Servers/automation-01.md)
- [n8n](n8n.md)
