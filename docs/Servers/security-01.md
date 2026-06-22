---
tags:
  - homelab
  - server
  - security
  - wazuh
  - siem
created: 2026-06-13
ip: 10.0.0.40
vmid: 109
os: Ubuntu 22.04
---

# security-01

| Property | Value |
| -------- | ----- |
| IP       | `10.0.0.40` |
| VM ID    | 109 |
| Role     | Security monitoring (Wazuh SIEM/XDR) |
| RAM      | 4 GB (+2 GB swap) |
| Disk     | 60 GB |
| OS       | Ubuntu 22.04 LTS |
| Proxmox autostart | Disabled at last review |
| Last verified | 2026-06-21 |

> [!WARNING]
> Proxmox autostart was disabled at the latest review. Enable and test startup ordering so monitoring returns after a hypervisor reboot.

## Services

| Service | Port | Purpose |
| ------- | ---- | ------- |
| Wazuh Manager | 1514/TCP | Agent data reception |
| Wazuh Agent Enrollment | 1515/TCP | Agent auto-enrollment |
| Wazuh API | 55000/TCP | REST API |
| Wazuh Dashboard | 443/TCP | Web UI (HTTPS) |
| CrowdSec LAPI | 8080/TCP | Centralized IPS API |

## Access

| Method | URL / Command |
| ------ | ------------- |
| SSH | `ssh security-01` |
| Dashboard | `https://10.0.0.40` (eventually `https://wazuh.local.yourdomain.com`) |
| API | `https://10.0.0.40:55000` |

## Credentials

- **Username**: `admin`
- **Password**: `[REDACTED]`
- *Note: Default passwords can be changed using `/usr/share/wazuh-indexer/plugins/opensearch-security/tools/wazuh-passwords-tool.sh --change-all`*

## Enrolled Agents

| Agent | IP | Status |
| ----- | -- | ------ |
| automation-01 | 10.0.0.67 | Active |
| docker-01 | 10.0.0.33 | Active |
| colmado-db | 10.0.0.35 | Active |
| Proxmox host | 10.0.0.167 | Active |
| MacBook (yzee) | 10.0.0.72 | Active |

## Security

- **fail2ban** — active, sshd jail
- **unattended-upgrades** — enabled
- **ufw** — configured (SSH, 443, 1514, 1515, 55000, 8080 from LAN only)

See [Security Baseline](../Security/Security Baseline.md) for full details.

## Resource Tuning

> [!WARNING]
> This VM has only **4 GB RAM**. Running Wazuh (Manager + Indexer + Dashboard) alongside CrowdSec LAPI requires limiting the Wazuh Indexer JVM heap.

| Parameter | File | Value |
| --------- | ---- | ----- |
| `-Xms` / `-Xmx` | `/etc/wazuh-indexer/jvm.options` | `1g` |

After changing, restart the indexer: `sudo systemctl restart wazuh-indexer`.

## Related

- [automation-01](automation-01.md) — Ansible control plane (deploys agents)
