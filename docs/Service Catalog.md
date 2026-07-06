# Service Catalog

**State:** Observed
**Last reviewed:** 2026-06-21

This catalog describes what is running and why it exists. Container definitions in the repository are supporting implementation records, not a promise of one-command reproduction.

## Control plane — `automation-01`

Eleven containers were running at the latest review.

| Service | Function | Operating role |
| --- | --- | --- |
| Life Control Center | Custom personal operations application | Internal application |
| Gotenberg | Document rendering API | Supports PDF/document generation workflows |
| n8n 2.22.5 | Workflow engine | Scheduled reports, remediation, integrations, and sanitized Git exports |
| Semaphore | Ansible web control plane | Runs version-controlled playbooks against the server fleet |
| Nginx Proxy Manager | Reverse proxy and TLS termination | Internal HTTPS entry point |
| Uptime Kuma | Availability monitoring | Checks eleven service endpoints at the latest review |
| Homepage | Service and infrastructure dashboard | Operator landing page |
| Portainer | Docker management | Manages the local engine and the remote agent on `docker-01` |
| Open WebUI | Local AI interface | Connects to Ollama on the admin workstation when available |
| Netdata | Metrics collection | Host and container telemetry |
| Watchtower | Container update watcher | Opt-in updates for selected non-stateful workloads |

## Application plane — `docker-01`

Eight containers were running at the latest review.

| Service or component | Function | Operating role |
| --- | --- | --- |
| Nextcloud 33.0.5 | Private file and collaboration platform | Primary self-hosted application |
| PostgreSQL | Nextcloud database | Stateful Nextcloud component |
| Redis | Nextcloud cache and locking | Stateful supporting component |
| Cloudflared | Cloudflare Tunnel connector | Selected external ingress |
| Dozzle | Container log viewer | Lightweight troubleshooting interface |
| Portainer Agent | Remote Docker API | Managed from the control plane |
| Netdata | Metrics collection | Host and container telemetry |
| Watchtower | Container update watcher | Opt-in update monitoring |

## Data plane — `colmado-db`

The self-hosted Supabase development platform currently runs thirteen containers.

| Capability | Supabase components |
| --- | --- |
| Database and pooling | PostgreSQL; Supavisor is deployed but pooled connections are currently degraded |
| API gateway and REST | Kong, PostgREST |
| Identity | GoTrue Auth |
| Object storage and images | Storage API, imgproxy |
| Realtime | Realtime server |
| Server-side logic | Deno Edge Functions |
| Administration | Studio, Postgres Meta |
| Observability | Analytics/Logflare, Vector |

This stack supports application development; it is not represented as a general-purpose production database service.

## Security plane — `security-01` and agents

| Capability | Placement | Current implementation |
| --- | --- | --- |
| Security event management | `security-01` | Wazuh manager, indexer, dashboard, and Filebeat |
| Endpoint telemetry | Linux hosts and admin Mac | Wazuh agents; agent version observed as 4.11.2 |
| Threat decisions | `security-01` | CrowdSec Local API with SQLite backend |
| Detection and enforcement | Proxmox and selected Linux guests | CrowdSec agents and firewall bouncers; version observed as 1.7.8 |
| SSH notifications | Managed Linux hosts | PAM-triggered event notifications distributed with Ansible |

The latest Wazuh review showed active agents for Proxmox, `automation-01`, `docker-01`, `colmado-db`, the administrative Mac, and the manager itself.

## Network and platform services

| Service | Placement | Function |
| --- | --- | --- |
| Proxmox VE | Bare metal | VM/LXC lifecycle, virtual networking, and storage |
| Pi-hole FTL 6.6.2 | `pihole-01` LXC | Filtering and selected local DNS records |
| Tailscale Subnet Router | `proxmox` Host | Private remote administration & exit node |
| GitHub | External | Public source of truth for sanitized infrastructure and documentation |
| Ollama | Admin workstation | Local model runtime used by Open WebUI and selected automation |

## Repository implementation map

| Path | Evidence contained |
| --- | --- |
| [`docker/`](../docker) | Compose definitions grouped by host |
| [`ansible/`](../ansible) | Inventory and operational playbooks |
| [`n8n-workflows/`](../n8n-workflows) | Sanitized active and remediation workflow exports |
| [`security/`](../security) | Wazuh, CrowdSec, and SSH-alert implementation notes |
| [`hypervisor/`](../hypervisor) | Proxmox and Terraform configuration |
| [`scripts/`](../scripts) | Backup, export, sanitization, and maintenance utilities |
