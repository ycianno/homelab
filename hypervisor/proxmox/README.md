# Proxmox VE Hypervisor — proxmox

This directory documents the virtualization host settings, VM/LXC allocations, and bare-metal backup configurations for the homelab core hypervisor.

## Host Details
- **Hostname:** `proxmox`
- **IP Address:** `10.0.0.167`
- **OS:** Proxmox VE (Debian base)
- **Web UI:** `https://10.0.0.167:8006`

## VM & Container Inventory

| VM/CT ID | Hostname | Type | RAM | OS | Role / Services |
|----------|----------|------|-----|----|-----------------|
| `999` | `automation-01` | VM | 4 GB | Debian 13 | Control plane (n8n, Uptime Kuma, Semaphore) |
| `102` | `docker-01` | VM | 4 GB | Ubuntu | Main Docker App server (Nextcloud, Dozzle, Tunnels) |
| `105` | `pihole-01` | LXC | 1 GB | Ubuntu | Local DNS Resolver & Ad Filtering |
| `104` | `twingate-connector` | LXC | 1 GB | Debian | Secure remote access gateway |
| `101` | `colmado-db` | VM | 8 GB | Ubuntu | Vitrina dev DB (Supabase full stack) |
| `100` | `WIN-SERVER` | VM | 8 GB | Windows Server | AD Active Directory DC & Hardening lab (Planned) |
| `107` | `WIN-CLIENT` | VM | 4 GB | Windows 10/11 | Active Directory Client Workstation (Planned) |
| `108` | `roki` | VM | — | Linux | Lab system (Inactive/Archive) |
| `106` | `server1` | VM | — | Linux | Lab system (Inactive/Archive) |

## Backup & Storage Policies

### Hypervisor Backups
- The former `usb-backups` target has been retired because no dedicated USB
  disk is part of the current design.
- The old 02:00 `vzdump` job is preserved but disabled as of 2026-07-14 so it
  does not generate guaranteed failures against nonexistent storage.
- Application/configuration backups currently travel from the servers through
  the Mac and iCloud to local iPhone storage. These are useful recovery
  artifacts, but they are not full Proxmox guest archives.
- A replacement full-guest design must account for the Mac having about 4 GiB
  free while the guests currently occupy about 140 GiB on Proxmox.

### Virtual Machine Disk Storage
- Standard virtual disks are allocated on the local Proxmox LVM-thin storage pool (`local-lvm`).
- For database systems (`colmado-db`), prune docker images regularly to avoid overprovisioning local-lvm boundaries.
