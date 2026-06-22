---
tags:
  - homelab
  - service
  - dashboard
created: 2026-05-30
---

# Homepage

## 📋 Overview
- **Purpose:** Central homelab dashboard and application launcher.
- **Host:** [automation-01](../Servers/automation-01.md) (`10.0.0.67`)
- **Port:** `3000`
- **Internal URL:** [https://dashboard.local.yourdomain.com](https://dashboard.local.yourdomain.com) (Internal IP: `https://dashboard.local.yourdomain.com (Internal IP: `http://dashboard.local.yourdomain.com (`10.0.0.67:3000`)`)`)
- **Config Path:** `/opt/stacks/homepage/config`
- **Git Backup Path:** `~/repos/homelab/docker/automation-01/homepage/config/`

## 🔧 Dashboard Configuration & Layout
The dashboard layout is designed to provide a clean visualization of the homelab infrastructure and active service pools:
- **Professional Profile** (GitHub, LinkedIn) is fixed at the top for visibility.
- **Homelab stacks** (Core Automation, App Server, Infrastructure, Tools) occupy the middle sections.
- **SaaS Ecosystems** (Vitrina & BudgetNote) are displayed side-by-side at the bottom just before the bookmarks.
- **Bookmarks** are structured to place professional certification tracks (such as PL-900, AZ-900, and ITIL 4/5) at the top of the resource list.

## 💾 Operational Runbook
For full instructions on updating services, bookmarks, or settings, refer to the [Homepage Config Runbook](../Runbooks/Homepage Config.md). Always edit configurations directly in `/opt/stacks/homepage/config` and back up to Git afterwards.

## 📊 Monitoring
- Uptime Kuma monitors Homepage port `3000` to verify availability.

## 🔗 Related
- [automation-01](../Servers/automation-01.md)
- [Homepage Config Runbook](../Runbooks/Homepage Config.md)
- [Uptime Kuma](Uptime Kuma.md)
