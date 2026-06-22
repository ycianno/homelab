---
tags:
  - homelab
  - server
  - docker
  - apps
created: 2026-05-30
ip: 10.0.0.33
vmid: 102
os: Debian 12
---

# docker-01

| Property | Value |
| -------- | ----- |
| IP       | `10.0.0.33` |
| VM ID    | 102 |
| Role     | Main Docker app server |
| CPU      | 4 vCPU |
| RAM      | 4 GB maximum (2 GB balloon minimum) |
| Disk     | 150 GB |
| OS       | Debian 12 |
| Last verified | 2026-06-21 |

## Services (Docker)

| Container | Image | Port | Purpose |
| --------- | ----- | ---- | ------- |
| nextcloud-app | nextcloud | 8081 | Private cloud (`https://cloud.yourdomain.com`) |
| nextcloud-redis | redis | 6379 (internal) | Nextcloud cache |
| nextcloud-db | postgres | 5432 (internal) | Nextcloud database |
| cloudflared | cloudflared | — | Cloudflare tunnel |
| dozzle | dozzle | 8088 | Docker log viewer |
| portainer_agent | portainer/agent | 9001 | Remote Docker mgmt |
| netdata | netdata/netdata:stable | 19999 | Monitoring |
| watchtower | containrrr/watchtower | — | Monitor updates |

## Important Paths

| Path | Purpose |
| ---- | ------- |
| `/opt/stacks` | Docker Compose stacks |

## Operational Rules

> [!IMPORTANT]
> - docker-01 should focus on **app containers**, not control-plane tools.
> - **n8n** was previously here and has been moved to [automation-01](automation-01.md). Do not move it back.

## Security

- **fail2ban** — active, sshd jail (needed `systemd` backend config for journal/SSH logs)
- **unattended-upgrades** — enabled

See [Security Baseline](../Security/Security Baseline.md) for full details.

## Related

- [automation-01](automation-01.md)
