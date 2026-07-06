---
tags:
  - homelab
  - server
  - proxmox
  - hypervisor
created: 2026-05-30
ip: 10.0.0.167
---

# Proxmox VE

| Property | Value |
| -------- | ----- |
| IP       | `10.0.0.167` |
| Role     | Virtualization host |
| Web UI   | `https://10.0.0.167:8006` |
| Version  | Proxmox VE 8.4.19 |
| CPU      | Intel Core i7-6600U, 4 logical CPUs |
| RAM      | 20.8 GiB |
| Storage  | 238.5 GB NVMe |
| Last verified | 2026-06-21 |

## VMs / Containers

| ID | Name | Type | Purpose |
| -- | ---- | ---- | ------- |
| 999 | [automation-01](automation-01.md) | VM | Automation / control plane |
| 102 | [docker-01](docker-01.md) | VM | Main Docker app server |
| 105 | [pihole-01](pihole-01.md) | LXC | DNS filtering |
| 101 | [colmado-db](colmado-db.md) | VM | Vitrina dev database |
| 109 | [security-01](security-01.md) | VM | Security monitoring (Wazuh) |
