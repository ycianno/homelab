---
tags:
  - homelab
  - service
  - reverse-proxy
  - ssl
created: 2026-05-31
---

# Nginx Proxy Manager

## 📋 Overview
- **Purpose:** Secure reverse proxy and Let's Encrypt SSL certificate manager for the internal local network.
- **Host:** [automation-01](../Servers/automation-01.md) (`10.0.0.67`)
- **Admin UI Port:** `81` (Internal URL: [https://npm.local.yourdomain.com](https://npm.local.yourdomain.com) (Internal IP: `https://npm.local.yourdomain.com (Internal IP: `http://npm.local.yourdomain.com (`10.0.0.67:81`)`)`))
- **Public Traffic Ports:** `80` (HTTP) and `443` (HTTPS)
- **Config / Stack Path:** `/opt/stacks/nginx-proxy-manager` (Docker Compose)
- **Git Backup Path:** `~/repos/homelab/docker/automation-01/nginx-proxy-manager/`

---

## 🔒 Wildcard SSL Certificate Configuration

NPM is configured with a wildcard certificate to allow secure local access (`https`) without browser warnings:
- **Domains:** `local.yourdomain.com`, `*.local.yourdomain.com`
- **SSL Provider:** Let's Encrypt
- **Challenge Type:** DNS-01 Challenge via **Cloudflare DNS**
- **Cloudflare API Token:** Configured inside NPM to automatically handle challenge record creation and renewals.

---

## 🗺️ Configured Proxy Hosts

All internal hosts are routed securely via NPM using the wildcard certificate:

| Subdomain | Forward Host | Forward Port | Service Description | SSL Forced |
| :--- | :--- | :---: | :--- | :---: |
| `dashboard.local.yourdomain.com (`10.0.0.67:3000`)` | `10.0.0.67` | `3000` | [Homepage](Homepage.md) Dashboard | Yes |
| `npm.local.yourdomain.com (`10.0.0.67:81`)` | `10.0.0.67` | `81` | Nginx Proxy Manager Web UI | Yes |
| `kuma.local.yourdomain.com (`10.0.0.67:3001`)` | `10.0.0.67` | `3001` | [Uptime Kuma](Uptime Kuma.md) Monitoring | Yes |
| `ansible.local.yourdomain.com (`10.0.0.67:3005`)` | `10.0.0.67` | `3005` | [Semaphore](Semaphore.md) Ansible UI | Yes |
| `supabase.local.yourdomain.com (`10.0.0.35:8000`)` | `10.0.0.35` | `8000` | [colmado-db](../Servers/colmado-db\.md) Supabase Dev Studio | Yes |
| `pihole.local.yourdomain.com` | `10.0.0.20` | `80` | [pihole-01](../Servers/pihole-01\.md) Pi-hole Web Console | Yes |
| `ai.local.yourdomain.com (`10.0.0.67:3080`)` | `10.0.0.67` | `3080` | [Open WebUI](Open WebUI.md) Local AI Interface | Yes |
| `portainer.local.yourdomain.com (`10.0.0.67:9443`)` | `10.0.0.67` | `9443` (HTTPS) | [Portainer](Portainer.md) Docker Manager | Yes |
| `dozzle.local.yourdomain.com (`10.0.0.33:8088`)` | `10.0.0.33` | `8088` | Dozzle Log Viewer | Yes |
| `cloud.local.yourdomain.com (`10.0.0.33:8081`)` | `10.0.0.33` | `8081` | [Nextcloud](Nextcloud.md) Cloud Storage (Local) | Yes |
| `netdata-auto.local.yourdomain.com` | `10.0.0.67` | `19999` | Netdata Metrics (automation-01) | Yes |
| `netdata-docker.local.yourdomain.com` | `10.0.0.33` | `19999` | Netdata Metrics (docker-01) | Yes |

---

## 💾 Backup & Recovery
- SQLite database resides in the mapped volume under `./data/database.sqlite`.
- Certificates and Let's Encrypt keys reside in `./letsencrypt`.
- Restoring the stack requires copying both `./data` and `./letsencrypt` directories.

---

## 🔗 Related
- [automation-01](../Servers/automation-01.md)
- [Homepage Config](../Runbooks/Homepage Config.md)
- [Uptime Kuma](Uptime Kuma.md)
- [Pi-hole](../Servers/pihole-01.md)
