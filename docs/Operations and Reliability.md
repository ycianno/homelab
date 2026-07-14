# Operations and Reliability

**State:** Observed unless explicitly marked otherwise
**Last reviewed:** 2026-07-14

## Source of truth and change flow

The public GitHub repository is canonical for sanitized infrastructure code and public documentation. Runtime secrets remain in local configuration and the private Obsidian vault. Plain-text local secrets are accepted for this lab, but they must not enter Git history.

The operating flow is:

1. Infrastructure definitions and playbooks are maintained in GitHub.
2. `automation-01` pulls the repository for Ansible/Semaphore execution.
3. Runtime changes are compared back to version-controlled definitions so drift can be identified.
4. Workflow examples are published only after deliberate review and sanitization; runtime exports never push automatically to the public repository.

## Automation

| System | Current use |
| --- | --- |
| Ansible | Updates, health checks, Docker maintenance, Wazuh/CrowdSec deployment, SSH alerts, and targeted stack operations |
| Semaphore | Operator interface and scheduler for Ansible tasks |
| n8n | Daily health/capacity reports, remediation hooks, and application/business integrations |
| Watchtower | Label-gated updates for selected containers; stateful services are not broadly auto-updated |
| Terraform | Proxmox provisioning definitions are present; the repository does not claim the full current estate is reproducible from Terraform |

## Monitoring and security

- Uptime Kuma monitors eleven service endpoints.
- Netdata runs on both Docker hosts for host and container metrics.
- Wazuh collects endpoint and host security telemetry centrally on `security-01`.
- CrowdSec combines a central decision API with distributed agents and firewall bouncers.
- n8n publishes scheduled health, container, and disk-capacity reports.
- Nginx Proxy Manager centralizes internal TLS and application routing.

OpenVAS and scheduled Trivy scanning are not treated as deployed capabilities in this documentation. They remain possible future additions unless current runtime evidence shows otherwise.

## Backup and recovery status

Backups are described by what is recoverable today, not by the existence of a script or schedule.

| Scope | Observed state | Confidence and limitation |
| --- | --- | --- |
| Nextcloud database, data, and HTML/config | One successful local backup set was present on `docker-01` | Stored on the same VM/storage failure domain; not sufficient as disaster recovery |
| Supabase DB and service configurations | Included in the Mac-initiated application backup flow | Partial application-level protection; retention enumeration needs repair |
| Docker and control-plane configurations | Included in the Mac/iCloud flow | Configuration coverage only; does not replace VM images or full application data |
| Proxmox VM/LXC backups | Nightly job configured, but target storage disabled and recent jobs failed | No usable hypervisor dumps were present at review time |
| Restore testing | No current evidence of an end-to-end restore exercise | Recovery objectives and actual restore time are unknown |

The July 14 live audit also found and repaired a non-executable The Forge
database backup script. A same-day SQLite snapshot was produced successfully. This
does not change the disaster-recovery rating because the snapshot remains on the
same host and no restore exercise has been completed.

## Repairs completed on 2026-07-14

- Semaphore's on-LAN inventory now uses stable LAN addresses instead of
  Tailscale/MagicDNS names that the container could not resolve.
- Docker maintenance targets only hosts that actually run Docker.
- The n8n Threat Feed workflow uses the supported `cronExpression` schedule
  field and activates without the former timezone-alias error.
- Hermes schedules are preserved but disabled until its private configuration
  is installed.

The current backup posture is a known engineering gap. A successful command, scheduled job, or copied archive is not considered a verified recovery capability until a restore has been tested.

## Known limitations and active work

| Priority | Gap | Planned outcome |
| --- | --- | --- |
| Critical | Proxmox backup target is disabled; recent scheduled jobs failed | Restore a separate backup destination, produce fresh guest dumps, and test recovery |
| High | Hermes was scheduled without its private `config.json` and failed every two hours | Keep its cron entries disabled until the private Discord and Ollama configuration is installed and tested |
| High | Backups share local failure domains and Mac/iCloud retention handling is incomplete | Add independent storage, fix retention verification, and document recovery procedures |
| High | Supavisor uses a sample tenant ID and its `pgbouncer` database credential is mismatched | Configure a real tenant, synchronize the database role password, and verify session and transaction pool ports |
| High | `security-01` did not have Proxmox autostart enabled at review time | Enable startup ordering and verify the security plane returns after host reboot |
| Medium | Pi-hole is used by selected systems rather than the full network | Decide whether to make it authoritative for the LAN or document the intentionally mixed DNS model |
| Medium | Open WebUI depends on a workstation-hosted Ollama endpoint | Add a continuously available model host or accept/document intermittent availability |
| Medium | GitHub Actions currently reports pre-existing YAML lint failures | Correct lint findings and return the public validation workflow to green |
| Medium | The `10.16.30.0/24` Proxmox bridge is under-documented | Define its intended isolation policy and attach workloads only after that policy is explicit |

## Definition of “current”

Architecture and catalog pages include a review date. A configuration file proves intent; live host inspection proves deployment; a successful functional check proves service. Where those disagree, this documentation reports the discrepancy instead of presenting the intended design as current fact.
