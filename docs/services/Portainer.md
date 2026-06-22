---
tags:
  - homelab
  - service
  - docker
created: 2026-05-30
---

# Portainer

## 📋 Overview
- **Purpose:** Visual container management dashboard for managing Docker environments, stacks, volumes, and networks.
- **Host:** [automation-01](../Servers/automation-01.md) (`10.0.0.67`) (main server), [docker-01](../Servers/docker-01.md) (`10.0.0.33`) (remote agent)
- **Ports:** `9443` (HTTPS Web UI), `9001` (agent connection on docker-01)
- **Local URL:** [https://portainer.local.yourdomain.com](https://portainer.local.yourdomain.com) (Internal IP: `https://portainer.local.yourdomain.com (Internal IP: `https://portainer.local.yourdomain.com (`10.0.0.67:9443`)`)`) (Internal IP: `https://portainer.local.yourdomain.com (Internal IP: `https://portainer.local.yourdomain.com (`10.0.0.67:9443`)`)`)
- **Config / Stack Path:** `/opt/stacks/portainer` (Docker Compose on `automation-01`)

## 🔧 Architecture & Agents
- **Portainer Server**: Runs on `automation-01` inside VM ID 999. It acts as the central interface.
- **Portainer Agent**: Runs on `docker-01` inside VM ID 102. It listens on port `9001` to allow control of `docker-01` containers from the `automation-01` interface.

## 📊 Monitoring
- Monitored by [Uptime Kuma](Uptime Kuma.md):
  - **Portainer automation-01**: HTTPS check on port `9443`.
  - **Portainer Agent docker-01**: TCP port check on port `9001`.

## 🔗 Related
- [automation-01](../Servers/automation-01.md)
- [docker-01](../Servers/docker-01.md)
- [Uptime Kuma](Uptime Kuma.md)
