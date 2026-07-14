# Live Infrastructure Audit — 2026-07-14

## Scope

Read-only discovery covered Proxmox, `automation-01`, `docker-01`,
`colmado-db`, `security-01`, `pihole-01`, n8n, Semaphore, Docker workloads,
systemd timers, user cron jobs, backup history, and Tailscale reachability.
Low-risk repairs made during the audit are listed explicitly below.

## Host state

| Host | Root use | Failed units at discovery | Result |
| --- | ---: | ---: | --- |
| `automation-01` | 49% | 0 | Healthy; n8n returned HTTP 200 after restart |
| `docker-01` | 20% | 0 | Healthy |
| `colmado-db` | 64% | 0 | Healthy; all 13 Supabase containers running |
| `security-01` | 31% | 1 | Wazuh Manager restarted and verified active |
| `proxmox` | 68% | 0 | Guests running; backup storage unavailable |
| `pihole-01` | 49% | 1 | MOTD executable permission repaired; Pi-hole DNS/blocking healthy |

The Windows lab server was offline in Tailscale and last seen six days before
the audit. It remains outside the Linux automation scope.

## Automation findings

### Semaphore

- One project contains 13 templates and four active schedules.
- The daily backup schedule failed every day inspected from June 25 through
  July 14 because the Semaphore container could not resolve the Tailscale names
  in `ansible/inventory.ini`.
- The July 12 OS update failed for the same DNS reason.
- The July 1 Docker cleanup did useful work on three Docker hosts but was marked
  failed because it also targeted `security-01`, which is not a Docker host.
- A June 28 OS update remains incorrectly recorded as `running` even though its
  runner is no longer active.

Repository corrections in this audit use stable LAN addresses for Semaphore,
add a `docker_hosts` group, restrict Docker maintenance to that group, and use
Ansible's `script` module for the backup script.

Post-change validation succeeded in the live Semaphore service. The Server
Health Check reached all four Linux hosts with no failures, and the Unified
Homelab Backups template completed successfully, producing fresh Supabase and
Nextcloud database dumps plus Docker/control-plane configuration archives.

### n8n

- After cleanup, 14 workflows remain: 10 published/active and four inactive.
- The published Threat Feed workflow cannot activate because its old Schedule
  Trigger uses `field: cron`; n8n 2.22.5 expects `field: cronExpression`.
- Five inactive per-service infrastructure reports superseded by the consolidated
  daily report were deleted after a verified SQLite backup.
- The inactive v1 Zoho weekly report was deleted because v3 is active.
- The scheduled n8n-to-public-GitHub export was unpublished. Public workflow
  examples are now curated deliberately instead of serving as runtime backups.
- The inactive Local AI template and BudgetNote Twitter workflow were not
  classified as legacy because they may still be intentional drafts.

### Host cron

- The Forge backup script lacked execute permission. It was
  repaired and successfully wrote `db-2026-07-14.sqlite`.
- Hermes had no private `config.json`, causing repeated failures. Its two cron
  entries were preserved but disabled until configuration is supplied.
- Nextcloud application cron remains active every five minutes on `docker-01`.

### Watchtower notifications

Watchtower updated Portainer successfully on July 14, but Shoutrrr sent a bare
report string while declaring an JSON content type. n8n rejected the request
with HTTP 422 before the workflow could parse it. The Compose definition now
uses Shoutrrr's full generic URL plus `template=json`, which supplies the
`title` and `message` object expected by the workflow.

### Service rationalization finding

Uptime Kuma 1.23.17 continuously consumed roughly 66–82% of one CPU after a
restart despite having only 11 monitors and about 695,000 heartbeat rows. A
checksum-verified full data backup was created, the deployment was pinned to
the v2 major release line, and Uptime Kuma 2.4.0 completed its aggregate-table
migration for all 11 monitors. Five post-migration samples measured 0.57–0.62%
CPU with zero container restarts. Kuma is now a healthy long-term monitoring
component. The preserved `Twingate` monitor currently reports `10.0.0.34` as
unreachable and should be reconciled with the intended network inventory.

## Critical unresolved risk

The Proxmox `usb-backups` storage is disabled and no USB backup device is part
of the intended design. The obsolete 02:00 job was preserved but disabled on
July 14 so it no longer generates guaranteed failures. No usable guest dump was
found. Building the replacement phone-backed full-guest flow and completing a
test restore is the highest-priority remaining reliability task.

Semaphore environment records contain operational credentials in retrievable
plaintext for authenticated administrators. Credentials handled during this
audit should be rotated, then moved toward narrower service-specific secrets
with documented ownership and expiry.
