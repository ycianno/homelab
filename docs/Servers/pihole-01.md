---
tags:
  - homelab
  - server
  - dns
  - pihole
created: 2026-05-30
ip: 10.0.0.20
vmid: 105
type: LXC
aliases:
  - ubuntu-01
---

# pihole-01

| Property | Value |
| -------- | ----- |
| IP       | `10.0.0.20` |
| VM/CT ID | 105 |
| Type     | LXC container |
| Role     | DNS filtering |
| OS       | Ubuntu 24.04 |
| RAM      | 512 MB |
| Disk     | 6 GB |
| Pi-hole FTL | 6.6.2 |
| Former name | ubuntu-01 |
| Last verified | 2026-06-21 |

## Access

| Method | URL / Command |
| ------ | ------------- |
| Web UI | `https://pihole.local.yourdomain.com/admin` (internal: `http://10.0.0.20/admin`) |
| DNS test | `dig google.com @10.0.0.20` |

## Status

- ✅ Pi-hole installed and working
- ✅ Admin password set
- ✅ DNS resolution tested
- ✅ Web UI reachable through Twingate
- ✅ Monitored by Uptime Kuma (Web + DNS checks)
- ✅ Added to Homepage dashboard

> [!CAUTION]
> **Router DNS has NOT been changed yet.** Pi-hole is **NOT** network-wide. Do not change router DNS until Pi-hole is confirmed stable over time.

## Related

- [automation-01](automation-01.md) — runs Uptime Kuma monitoring and Homepage dashboard
