---
tags:
  - homelab
  - runbook
  - ansible
  - maintenance
  - docker
created: 2026-05-31
---

# System & Container Update Strategy

To maintain homelab system stability, security, and availability, updates are managed using a tiered patch management strategy. This strategy automates security patches for operating system packages and stateless containers while maintaining administrative control over stateful workloads (such as Supabase, Nextcloud, and n8n) via Ansible playbooks.

---

## 📋 The Update Strategy Matrix

| Tier | Services / Hosts | Strategy | Automation Level | Tools |
| :--- | :--- | :--- | :--- | :--- |
| **Tier 1: OS** | `automation-01`, `docker-01`, `pihole-01`, `colmado-db` | System & Security Updates | Automated Weekly Scheduled | Ansible + Semaphore + `unattended-upgrades` |
| **Tier 2: Stateless Apps** | Homepage, Dozzle, Netdata, Portainer Agent | Opt-In Auto-Updates | Fully Automated | Watchtower (Label-based) |
| **Tier 3: Stateful Apps** | Supabase (`colmado-db`), Nextcloud, n8n | Manual Checks + Automation Playbooks | Semi-Automated (One-click) | Watchtower Alerts + Ansible Stack Playbook |

---

## 🛠️ Tier 1: Host OS Updates (Ansible)

OS packages are updated weekly using the `system-update.yml` playbook, managed centrally via the Semaphore UI.

### 1. The Playbook: `system-update.yml`
Save this playbook to `~/repos/homelab/ansible/playbooks/system-update.yml`:

```yaml
---
- name: System Update and Upgrade Playbook
  hosts: linux_servers
  become: yes
  tasks:
    - name: Run apt update
      apt:
        update_cache: yes
        force_apt_get: yes

    - name: Upgrade all packages to the latest version
      apt:
        upgrade: dist
        force_apt_get: yes

    - name: Remove unused dependency packages
      apt:
        autoremove: yes
        purge: yes

    - name: Clean apt cache
      apt:
        autoclean: yes

    - name: Check if a reboot is required
      stat:
        path: /var/run/reboot-required
      register: reboot_required_file

    - name: Report reboot required
      debug:
        msg: "Server {{ inventory_hostname }} requires a reboot to complete updates."
      when: reboot_required_file.stat.exists
```

### 2. Scheduling in Semaphore
1. Commit and push the playbook to the local git repository.
2. In the Semaphore UI, configure a Task Template:
   - **Name:** `System updates and upgrades`
   - **Playbook:** `playbooks/system-update.yml`
   - **Inventory:** `inventory.ini`
3. Configure a Cron Schedule to execute the template automatically:
   - **Schedule:** Weekly on Sunday at 2:00 AM (`0 2 * * 0`).
   - Note: While security updates run daily via `unattended-upgrades`, this weekly playbook ensures host system packages, kernel patches, and system dependencies remain updated.

---

## 🐳 Tier 2: Stateless Container Updates (Watchtower Label-Based)

Auto-updating everything automatically can break databases. However, stateless containers like **Homepage**, **Dozzle**, or **Netdata** can be safely auto-updated.

Watchtower is configured to only update containers that explicitly **opt-in** via labels.

### 1. Reconfigure Watchtower
On both `automation-01` and `docker-01`, the Watchtower `docker-compose.yml` configuration (located at `/opt/stacks/watchtower/docker-compose.yml`) is modified as follows:

```yaml
version: "3"
services:
  watchtower:
    image: containrrr/watchtower
    container_name: watchtower
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock
    environment:
      # Enable label-only mode: Watchtower will ONLY update containers with the enable=true label
      - WATCHTOWER_LABEL_ENABLE=true
      # Watchtower will still monitor and send alerts for ALL containers
      - WATCHTOWER_MONITOR_ONLY=false
      # Poll for updates every 24 hours (86400 seconds)
      - WATCHTOWER_POLL_INTERVAL=86400
      # Discord Notification Settings (Preserve active configurations)
      - WATCHTOWER_NOTIFICATIONS=shoutrrr
      - WATCHTOWER_NOTIFICATION_URL=discord://token@webhook...
    restart: unless-stopped
```

### 2. Labeling Containers for Auto-Update
For services that are safe to auto-update, add the `com.centurylinklabs.watchtower.enable=true` label to their `docker-compose.yml` config.

#### Example: Stateless Container (Safe to Auto-Update)
```yaml
services:
  dozzle:
    image: amir20/dozzle:latest
    container_name: dozzle
    ports:
      - 8088:8080
    labels:
      - "com.centurylinklabs.watchtower.enable=true"  # Watchtower will auto-update this container!
    restart: unless-stopped
```

#### Example: Stateful/Critical Container (Alert Only, No Auto-Update)
If a container does not have the label, or has it set to `false`, Watchtower will send a notification to Discord but will **not** attempt to update it.

```yaml
services:
  nextcloud-db:
    image: postgres:15
    container_name: nextcloud-db
    labels:
      - "com.centurylinklabs.watchtower.enable=false" # Watchtower will NEVER auto-update this!
    # ...
```

---

## 🔒 Tier 3: Semi-Automated Updates for Stateful Stacks

To prevent data corruption or service interruption, stateful stacks (Supabase, Nextcloud, n8n) are updated semi-automatically after manual verification of changelogs.

### The Workflow:
1. **Watchtower Alerts:** Watchtower issues a Discord webhook notification indicating a new image release.
2. **Review Changelog:** The administrator verifies upstream changes for breaking updates.
3. **Re-deployment Playbook:** The administrator triggers a Semaphore task to back up and pull updates.

### The Ansible Docker Upgrade Playbook: `docker-stack-upgrade.yml`
Save this playbook to `~/repos/homelab/ansible/playbooks/docker-stack-upgrade.yml`:

```yaml
---
- name: Docker Stack Upgrade Playbook
  hosts: docker_servers, automation
  become: yes
  vars:
    # Set this in Semaphore at runtime via "extra_vars" or prompts
    stack_name: ""
    stack_path: "/opt/stacks/{{ stack_name }}"

  tasks:
    - name: Fail if stack_name is not defined
      fail:
        msg: "Please specify a stack_name to update (e.g. n8n, nextcloud, supabase)."
      when: stack_name == ""

    - name: Verify stack path exists
      stat:
        path: "{{ stack_path }}"
      register: dir_status

    - name: Fail if stack path does not exist
      fail:
        msg: "Stack path {{ stack_path }} does not exist on target host."
      when: not dir_status.stat.exists

    - name: Pull latest Docker images for the stack
      command: docker compose pull
      args:
        chdir: "{{ stack_path }}"

    - name: Redeploy Docker containers
      command: docker compose up -d
      args:
        chdir: "{{ stack_path }}"

    - name: Prune dangling images
      command: docker image prune -f
```

### Running the Stack Upgrade in Semaphore:
1. In Semaphore, create a Task Template named `Upgrade Docker Stack`.
2. Link it to `playbooks/docker-stack-upgrade.yml`.
3. Add a **Prompt Parameter** or **Survey** for `stack_name`.
4. Upon receiving a Discord alert, the administrator initiates the Semaphore task, specifies the target stack name (e.g. `n8n`), executing the remote image pull, container recreation, and image pruning sequence.

---

## 🧹 Docker Disk & Log Maintenance

To prevent host storage exhaustion due to untruncated Docker container logs or orphaned image layers, a monthly maintenance playbook is configured.

Save this playbook to `~/repos/homelab/ansible/playbooks/docker-maintenance.yml`:

```yaml
---
- name: Docker Maintenance Playbook
  hosts: linux_servers
  become: yes
  tasks:
    - name: Prune unused Docker images, containers, and networks
      command: docker system prune -a --volumes -f
      register: prune_output

    - name: Output prune results
      debug:
        var: prune_output.stdout_lines

    - name: Truncate Docker container log files larger than 50MB
      shell: |
        find /var/lib/docker/containers/ -name "*-json.log" -type f -size +50M -exec truncate -s 0 {} \;
      args:
        executable: /bin/bash
      register: log_truncate_output
```

*Schedule this in Semaphore to run monthly.*

---

## 🔗 Related Notes
- [Ansible Playbooks Runbook](Ansible Playbooks.md)
- [automation-01 Details](../Servers/automation-01.md)
- [docker-01 Details](../Servers/docker-01.md)
- [Watchtower Service Details](../services/Watchtower.md)
