---
tags:
  - homelab
  - server
  - automation
  - control-plane
created: 2026-05-30
ip: 10.0.0.67
vmid: 999
os: Debian 13
---

# automation-01

| Property | Value |
| -------- | ----- |
| IP       | `10.0.0.67` |
| VM ID    | 999 |
| Role     | Control plane |
| CPU      | 2 vCPU |
| RAM      | 4 GB maximum (ballooning enabled) |
| Disk     | 60 GB |
| OS       | Debian 13 |
| Last verified | 2026-06-21 |

## Services (Docker)

| Container | Image | Port | Purpose |
| --------- | ----- | ---- | ------- |
| life-control-center | custom | 3007 | Personal org panel |
| gotenberg | gotenberg | 3000 (internal) | Document rendering API |
| n8n | n8n | 5678 | Workflow automation |
| semaphore | semaphore | 3005 | Ansible UI |
| watchtower | containrrr/watchtower | — | Monitor updates |
| netdata | netdata/netdata:stable | 19999 | Monitoring |
| homepage | gethomepage/homepage | 3000 | Dashboard |
| portainer | portainer-ce | 9443 (https), 9000 | Docker mgmt |
| uptime-kuma | uptime-kuma | 3001 | Service monitoring |
| nginx-proxy-manager | jc21/nginx-proxy-manager | 81 (web), 80 (http), 443 (https) | Reverse proxy & SSL |
| open-webui | open-webui | 3080 | Local AI interface |

## Important Paths

| Path | Purpose |
| ---- | ------- |
| `/opt/stacks` | Docker Compose stacks |
| `/opt/stacks/homepage/config` | Homepage configuration |
| `/opt/stacks/nginx-proxy-manager` | Nginx Proxy Manager configuration |
| `~/repos/homelab` | Git repo |
| `~/repos/homelab/ansible` | Ansible playbooks |

## Operational Rules

> [!IMPORTANT]
> - automation-01 must remain **separate** from [docker-01](docker-01.md). This server should keep working even if docker-01 has issues.
> - **n8n**, **Uptime Kuma**, **Semaphore**, and **Homepage** belong here — do not move them.
> - **Ansible** is installed and run from this server.

## Security

- **fail2ban** — active, sshd jail
- **unattended-upgrades** — enabled
- **ufw** — configured

See [Security Baseline](../Security/Security Baseline.md) for full details.

## Related

- [Homepage Config](../Runbooks/Homepage Config.md)
- [Ansible Playbooks](../Runbooks/Ansible Playbooks.md)
