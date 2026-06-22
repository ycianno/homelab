---
tags:
  - homelab
  - service
  - ansible
  - automation
created: 2026-05-30
---

# Semaphore

## 📋 Overview
- **Purpose:** Modern web UI for Ansible, allowing execution of playbooks via a browser interface.
- **Host:** [automation-01](../Servers/automation-01.md) (`10.0.0.67`)
- **Port:** `3005`
- **Internal URL:** [https://ansible.local.yourdomain.com](https://ansible.local.yourdomain.com) (Internal IP: `https://ansible.local.yourdomain.com (Internal IP: `http://ansible.local.yourdomain.com (`10.0.0.67:3005`)`)`)
- **Config / Stack Path:** `/opt/stacks/semaphore` (Docker Compose)

## 🔧 Configuration Details
- **Project:** `Homelab Automation`
- **Template:** `Server Health Check` (runs playbooks like `playbooks/server-health.yml`)
- **Git Repo Link:** Public GitHub repository: `https://github.com/ycianno/homelab.git`.
- **Database:** Currently runs BoltDB (a deprecation warning was noticed; migration to SQLite is planned for the future).

## 💾 Security & SSH Key Management
- SSH keys are configured in Semaphore to authenticate with `automation-01` and `docker-01` to run commands.
- *Milestone:* Successfully rotated and re-tested SSH key access after potential exposure.

## 📊 Monitoring
- Monitored by [Uptime Kuma](Uptime Kuma.md) on port `3005`.

## 🔗 Related
- [automation-01](../Servers/automation-01.md)
- [Ansible Playbooks Runbook](../Runbooks/Ansible Playbooks.md)
- [Uptime Kuma](Uptime Kuma.md)
