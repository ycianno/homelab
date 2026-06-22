---
tags:
  - homelab
  - runbook
  - ansible
  - automation
created: 2026-05-30
---

# Ansible Playbooks

| Property | Value |
| -------- | ----- |
| Installed on | [automation-01](../Servers/automation-01.md) |
| Repo | `~/repos/homelab/ansible` |
| Inventory | `~/repos/homelab/ansible/inventory.ini` |
| Semaphore UI | `https://ansible.local.yourdomain.com (Internal IP: `http://ansible.local.yourdomain.com (`10.0.0.67:3005`)`)` |

## Inventory Groups

| Group | Description |
| ----- | ----------- |
| `automation` | automation-01 |
| `docker_servers` | docker-01 |
| `linux_servers` | All Linux servers |

## Quick Commands

All commands run from [automation-01](../Servers/automation-01.md):

```bash
cd ~/repos/homelab/ansible
```

### Ping all servers

```bash
ansible linux_servers -i inventory.ini -m ping
```

### Check disk usage

```bash
ansible linux_servers -i inventory.ini -m shell -a 'df -h /'
```

### Check uptime

```bash
ansible linux_servers -i inventory.ini -m shell -a 'uptime'
```

### List Docker containers

```bash
ansible linux_servers -i inventory.ini -m shell -a 'docker container ls'
```

## Playbooks

### server-health.yml

- **Path**: `ansible/playbooks/server-health.yml`
- **Purpose**: Check hostname, disk usage, uptime, Docker containers

```bash
ansible-playbook -i inventory.ini playbooks/server-health.yml
```

### system-update.yml

- **Path**: `ansible/playbooks/system-update.yml`
- **Purpose**: Run system updates (`apt update` & `apt upgrade`) and check if reboots are required. Used for automated weekly server updates.
- **Reference**: See [System & Container Update Strategy](System Updates.md)

### docker-stack-upgrade.yml

- **Path**: `ansible/playbooks/docker-stack-upgrade.yml`
- **Purpose**: Pull and upgrade a specific Docker Compose stack (e.g. `n8n`, `nextcloud`) on demand with a user-specified stack name variable.
- **Reference**: See [System & Container Update Strategy](System Updates.md#Ansible Docker Upgrade Playbook: docker-stack-upgrade.yml)

### docker-maintenance.yml

- **Path**: `ansible/playbooks/docker-maintenance.yml`
- **Purpose**: Prune unused Docker objects and truncate JSON container log files larger than 50MB. Run monthly.
- **Reference**: See [System & Container Update Strategy](System Updates.md#Bonus: Docker Disk & Log Maintenance)

## Semaphore

Web UI for running Ansible playbooks: `https://ansible.local.yourdomain.com (Internal IP: `http://ansible.local.yourdomain.com (`10.0.0.67:3005`)`)`

- Connected to the public **GitHub** homelab repository.
- Connected to Ansible **inventory**.
- Runs playbooks from browser instead of CLI.

### Semaphore Task Templates Configuration

| Template Name | Playbook Path | Trigger / Schedule | Inputs / Survey Variables | Purpose |
| :--- | :--- | :--- | :--- | :--- |
| **Server Health Check** | `ansible/playbooks/server-health.yml` | Manual | None | Basic server CPU, disk, memory, and container status check. |
| **System OS Updates** | `ansible/playbooks/system-update.yml` | Weekly (Sunday 1:00 AM) | None | Runs system updates and checks if reboot is required. |
| **Docker Disk & Log Cleanup** | `ansible/playbooks/docker-maintenance.yml` | Monthly (1st at 3:00 AM) | None | Prunes unused Docker objects and truncates large container JSON logs. |
| **Upgrade Docker Stack** | `ansible/playbooks/docker-stack-upgrade.yml` | Manual (On-Demand) | `stack_name` *(String, Required)* | Pulls latest Docker image and redeploys a specific compose stack. |
| **Terraform Deploy** | `ansible/playbooks/run-terraform.yml` | Manual | None | Deploys/provisions Proxmox VMs and LXC containers via Terraform. |
| **Database Hardening** | `ansible/playbooks/harden-db.yml` | Monthly (1st at 4:00 AM) | None | Secures colmado-db VM, truncates Docker container logs, sets rotation policy. |
| **Zoho API Extraction** | `ansible/playbooks/update-zoho.yml` | Manual | None | Triggers n8n extraction and commits the updated API reference to GitHub. |
| **Unified Homelab Backups** | `ansible/playbooks/backup-homelab.yml` | Defined; schedule not currently verified | None | Runs the application-level DB/config backup script; this is not a Proxmox guest backup. |
| **Deploy Wazuh Agent** | `ansible/playbooks/deploy-wazuh-agent.yml` | Manual | None | Installs, holds, and configures the Wazuh EDR agent on all Linux servers. |

## Related

- [automation-01](../Servers/automation-01.md)
