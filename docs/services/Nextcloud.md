---
tags:
  - homelab
  - service
  - storage
  - cloud
created: 2026-05-30
---

# Nextcloud

## 📋 Overview
- **Purpose:** Self-hosted personal cloud storage and productivity platform.
- **Host:** [docker-01](../Servers/docker-01.md) (`10.0.0.33`)
- **Port:** `8081`
- **External URL:** [https://cloud.yourdomain.com](https://cloud.yourdomain.com)
- **Local URL:** [https://cloud.local.yourdomain.com](https://cloud.local.yourdomain.com) (Internal IP: `https://cloud.local.yourdomain.com (Internal IP: `http://cloud.local.yourdomain.com (`10.0.0.33:8081`)`)`) (Internal IP: `https://cloud.local.yourdomain.com (Internal IP: `http://cloud.local.yourdomain.com (`10.0.0.33:8081`)`)`)
- **Config / Stack Path:** `/opt/stacks/nextcloud` (Docker Compose on `docker-01`)

## 🔧 Architecture & Stack
Nextcloud is deployed as a multi-container Docker Compose stack on `docker-01`:
1. **nextcloud-app**: Nextcloud application container on port `8081`.
2. **nextcloud-redis**: Redis cache container on port `6379` (internal) to optimize performance.
3. **nextcloud-db**: PostgreSQL database container on port `5432` (internal).
4. **cloudflared**: Tunnels web traffic securely to Cloudflare for external DNS routing (`cloud.yourdomain.com`).

## 💾 Backup & Recovery
- File uploads and application configuration are persisted under `/opt/stacks/nextcloud`.
- Make sure to dump the PostgreSQL database (`nextcloud-db`) before performing major system upgrades.

## 📊 Monitoring
- Monitored by [Uptime Kuma](Uptime Kuma.md) via HTTP health check.

## 🔗 Related
- [docker-01](../Servers/docker-01.md)
- [Uptime Kuma](Uptime Kuma.md)
