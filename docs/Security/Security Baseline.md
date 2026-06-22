---
tags:
  - homelab
  - security
  - hardening
created: 2026-05-30
---

# Security Baseline

Security hardening applied to [automation-01](../Servers/automation-01.md) and [docker-01](../Servers/docker-01.md).

## Packages Installed (Both Servers)

| Category | Packages |
| -------- | -------- |
| Security | fail2ban, unattended-upgrades, ufw, ca-certificates, gnupg |
| Monitoring | htop, btop, lsof, net-tools |
| Networking | curl, wget, dnsutils |
| File tools | rsync, rclone, ncdu, tree, unzip |
| Dev tools | git, jq |

Full list: `fail2ban`, `unattended-upgrades`, `ufw`, `htop`, `btop`, `curl`, `wget`, `git`, `rsync`, `rclone`, `ncdu`, `tree`, `jq`, `lsof`, `net-tools`, `dnsutils`, `unzip`, `ca-certificates`, `gnupg`

## Fail2ban

- **Status**: Active on both servers
- **Active jail**: `sshd`

> [!NOTE]
> On [docker-01](../Servers/docker-01.md), fail2ban needed `systemd` backend and journal configuration to properly read SSH logs. Default `auto` backend didn't work.

Check status:

```bash
sudo fail2ban-client status
sudo fail2ban-client status sshd
```

## Unattended Upgrades

- **Status**: Enabled on both servers
- **Scope**: Security updates

Check status:

```bash
sudo systemctl status unattended-upgrades
cat /var/log/unattended-upgrades/unattended-upgrades.log
```

## Related

- [automation-01](../Servers/automation-01.md)
- [docker-01](../Servers/docker-01.md)
