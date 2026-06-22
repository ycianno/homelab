---
tags:
  - homelab
  - runbook
  - homepage
  - dashboard
created: 2026-05-30
---

# Homepage Config

| Property | Value |
| -------- | ----- |
| URL | `https://dashboard.local.yourdomain.com (Internal IP: `http://dashboard.local.yourdomain.com (`10.0.0.67:3000`)`)` |
| Server | [automation-01](../Servers/automation-01.md) |
| Config path | `/opt/stacks/homepage/config` |
| Git backup | `~/repos/homelab/docker/automation-01/homepage/config/` |

## Config Files

| File | Purpose |
| ---- | ------- |
| `services.yaml` | Service widgets |
| `bookmarks.yaml` | Bookmark links |
| `settings.yaml` | General settings |
| `widgets.yaml` | Info widgets |
| `custom.css` | Custom styling |

> [!CAUTION]
> Always edit from `/opt/stacks/homepage/config`, **NOT** from `~/repos/homelab`. The live config is in `/opt/stacks`.

## Save Config to Git

```bash
cd ~/repos/homelab
cp /opt/stacks/homepage/config/*.yaml docker/automation-01/homepage/config/
git add . && git commit -m 'Update Homepage' && git push
```

## Restore Config from Git

```bash
cp ~/repos/homelab/docker/automation-01/homepage/config/*.yaml /opt/stacks/homepage/config/
docker restart homepage
```

## Related

- [automation-01](../Servers/automation-01.md)
