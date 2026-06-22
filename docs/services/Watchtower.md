---
tags:
  - homelab
  - service
  - maintenance
created: 2026-05-30
---

# Watchtower

## 📋 Overview
- **Purpose:** Monitors Docker containers for base image updates and publishes status alerts.
- **Host:** Running on both [automation-01](../Servers/automation-01.md) (`10.0.0.67`) and [docker-01](../Servers/docker-01.md) (`10.0.0.33`).
- **Web UI:** None. Runs as a background service listening to the local `/var/run/docker.sock`.

## 🔧 Operational Rules & Mode
- **Opt-In Auto-Updates:** Configured with `WATCHTOWER_LABEL_ENABLE=true` and `WATCHTOWER_MONITOR_ONLY=false` in environment variables.
- **Why:** Safely auto-updates simple stateless containers (like Homepage, Dozzle, Netdata, Portainer Agent) that have the label `com.centurylinklabs.watchtower.enable=true`, while keeping stateful infrastructure (Supabase, Nextcloud, n8n) on alert-only mode.
- **Alerts:** Watchtower monitors all containers and pushes notifications of available updates to Discord via webhooks.
- **Reference:** See [System & Container Update Strategy](../Runbooks/System Updates.md) for detailed docker-compose labels and upgrade playbooks.

## 🔗 Related
- [automation-01](../Servers/automation-01.md)
- [docker-01](../Servers/docker-01.md)
- [System Updates Runbook](../Runbooks/System Updates.md)
