# DNS Infrastructure — pihole-01

This directory covers the DNS filtering, ad blocking, and local name resolution configuration for the homelab.

## Host Details
- **Container Name:** `pihole-01`
- **IP Address:** `10.0.0.20`
- **VM/CT ID:** `105`
- **Type:** Proxmox LXC Container
- **OS:** Ubuntu

## Services

| Service | Port | Description |
|---------|------|-------------|
| DNS Resolver | `53` (TCP/UDP) | Handles all local and upstream DNS queries |
| Web Admin Console | `80` (HTTP) | Pi-hole management dashboard |

## DNS Configuration

### Upstream DNS Servers
- **Primary:** `1.1.1.1` (Cloudflare)
- **Secondary:** `9.9.9.9` (Quad9)

### Local DNS Records (`/etc/hosts` or Local DNS setting)

To enable easy browser access within the homelab network, route the following local domains:

| Domain | Target IP | Description |
|--------|-----------|-------------|
| `n8n.local` | `10.0.0.67` | Local n8n Automation Console |
| `kuma.local` | `10.0.0.67` | Uptime Kuma Monitoring |
| `semaphore.local` | `10.0.0.67` | Ansible Semaphore Dashboard |
| `homepage.local` | `10.0.0.67` | Main Homelab Landing Page |
| `cloud.yourdomain.com` | `10.0.0.33` | Nextcloud Storage (Internal Split-Brain) |

## Monitoring & Alerts
- **Uptime Kuma:** Checks the Web UI on `http://10.0.0.20/admin/` and validates the DNS resolver using a `dig` query template against `google.com`.
- **Homepage:** Shows the active status and query stats on the control dashboard using the Pi-hole API key widget.

> [!CAUTION]
> **Router DHCP DNS Sync:** Router DHCP settings should NOT be updated to point to `10.0.0.20` as the primary DNS server until the LXC container has demonstrated a 99.9% uptime baseline over two weeks. Keep clients on gateway resolver `10.0.0.1` or manually configure specific testing devices first.
