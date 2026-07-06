---
tags:
  - homelab
  - service
  - n8n
  - automation
created: 2026-05-30
---

# n8n Service Documentation

## 1. Purpose of n8n in the Homelab

Within **YZEE Labs**, `n8n` serves as the central orchestration and workflow automation engine. It is situated on the control plane to decouple automation logic from application hosting workloads.

Its primary responsibilities include:
*   **Infrastructure Health & Status Checks:** Querying local endpoints and containers to compile status logs.
*   **Backup Verification:** Connecting to Proxmox and application servers to audit and verify successful daily backups.
*   **Discord Alerts & Logging:** Aggregating infrastructure notifications and outputting formatted reports to dedicated Discord channels.
*   **Business Integration Testing:** Interfacing with external APIs (such as Zoho Recruit) to simulate scheduled workflow data processing and template-based file generation.

---

## 2. Deployment & Server Details

*   **Host Server:** [automation-01](../Servers/automation-01.md) (Control Plane Host)
*   **Host IP Address:** `10.0.0.67`
*   **Service URL:** [http://10.0.0.67:5678](http://10.0.0.67:5678)
*   **Access Method:** Reachable internally on the home network or remotely via the **Tailscale VPN** mesh connection.

---

## 3. Container Configuration & Repository Settings

The n8n container is run via Docker Compose. The runtime configuration matches the definition in the repository at `docker/automation-01/n8n/docker-compose.yml`.

### Docker Configuration Summary
*   **Container Name:** `n8n`
*   **Docker Image:** `n8nio/n8n:latest`
*   **Restart Policy:** `unless-stopped`
*   **Ports:** `5678:5678` (mapped host port 5678 to container port 5678)
*   **Persistent Storage (Host Volume):** `/opt/stacks/n8n/n8n_data` mounted to `/home/node/.n8n` inside the container.
*   **External Dependencies:** No container dependencies are declared in its Docker Compose stack. However, the service depends on network-level access to the Proxmox Host (`10.0.0.167`) and [docker-01](../Servers/docker-01.md) (`10.0.0.33`) via SSH and HTTP.

### Environment Variables
*   `TZ=America/Santo_Domingo`: Sets timezone to match the user's local time.
*   `GENERIC_TIMEZONE=America/Santo_Domingo`: Sets timezone configuration for internal n8n nodes.
*   `N8N_SECURE_COOKIE=false`: Prevents cookie security issues on HTTP access.
*   `N8N_HOST=10.0.0.67`: Identifies the local host IP.
*   `N8N_PORT=5678`: Identifies the internal execution port.
*   `N8N_PROTOCOL=http`: Set to run over HTTP (internal access).
*   `N8N_RESTRICT_FILE_ACCESS_TO=/home/node/.n8n,/tmp`: Enhances container security by restricting node file read/write access.

---

## 4. Workflow Catalog

The following table summarizes the workflows present in the database, matching the exported JSON templates in the repository under `n8n-workflows/export-2026-05-30/`:

| ID / File | Workflow Name | Status | Schedule / Trigger | Major Integration |
|---|---|---|---|---|
| `1ObxEoPyLcitjDSg.json` | Nextcloud Backup Verification | *Inactive* | Daily at 4:00 AM | SSH, Nextcloud, Discord |
| `fMU6o4xZCxSRSoYK.json` | Homelab Disk Usage Report | **Active** | Daily at 8:05 AM | SSH, Discord |
| `H56zMRAdz8fbpQvz.json` | Homelab Container Status Report | **Active** | Daily at 8:02 AM | SSH, Docker CLI, Discord |
| `TGWSRgYDHDw2RzXZ.json` | Proxmox USB Backup Verification | *Inactive* | Daily at 3:45 AM | SSH, Proxmox, Discord |
| `wBVURdTLzGiSSiwk.json` | Daily Homelab Health Report | **Active** | Daily at 8:00 AM | HTTP Request, Discord |
| `8fW46qYRuluELXT3.json` | Zoho Weekly Recruitment Report | *Inactive* | Weekly on Thursday at 7:00 AM | Zoho Recruit API, Spreadsheet |
| `8mZV1Je37KbYriQI.json` | Zoho Weekly Recruitment Report - v2 Financials | *Inactive* | Weekly on Thursday at 7:00 AM | Zoho API, SSH, Python/Docker |
| `n8nBackupForgejo.json` | n8n Auto-Backup to GitHub | **Active** | Daily at 1:00 AM | SSH, Git, GitHub |
| `EAcHLCXJJFLwCnLM.json` | Global Error Handler | **Active** | Error Trigger | Discord Webhook |
| `uptime-kuma-remediation.json` | Semaphore Auto-Remediation | **Active** | Webhook (Uptime Kuma DOWN) | HTTP (Semaphore), Discord |
| `disk-space-remediation.json` | Automatic Disk Space Remediation | **Active** | Hourly | SSH, HTTP (Semaphore), Discord |

---

## 5. Detailed Workflow Configurations

### A. Nextcloud Backup Verification
*   **Status:** Inactive
*   **Purpose:** Verifies that Nextcloud data, database, and configuration directories were backed up successfully by `nextcloud-backup.sh` on `docker-01`. The verification workflow is currently disabled; one successful local backup set was observed on 2026-06-21.
*   **Trigger:** Schedule Trigger, running daily at **4:00 AM**.
*   **Systems Involved:** `automation-01` (n8n), `docker-01` (Nextcloud backups path `/opt/backups/nextcloud`).
*   **Major Processing Steps:**
    1.  Runs an SSH command on `docker-01` to list the latest backup files for database (`.sql.gz`), user data (`.tar.gz`), and HTML directories (`.tar.gz`), and queries `/var/log/nextcloud-backup.log` for the success confirmation string.
    2.  Executes `Build Backup Report` (JavaScript) to parse key-value lines, verify backups exist, ensure their file sizes are non-zero, and check the log match count.
    3.  Outputs status string formatting standard success (`✅`) or failure (`🚨`) alert markers.
    4.  Posts detailed status message to Discord Webhook.
*   **Discord Alerts:** Yes. Reports backup validation status, file names, backup sizes, log confirmation status, and root partition storage details.
*   **Expected Output:** Validation log structure with binary properties indicating backup integrity (`backupOk = true/false`).
*   **Failure Points & Validation:**
    *   *Failure:* SSH key/connection failure to `docker-01`.
    *   *Failure:* Nextcloud backup script failed to complete, leaving log files un-updated or missing.
    *   *Validation:* Inspect `/var/log/nextcloud-backup.log` on `docker-01` or manually run the script `/home/yzee/repos/homelab/scripts/docker-01/nextcloud-backup.sh`.

### B. Homelab Disk Usage Report
*   **Status:** Active
*   **Purpose:** Checks root filesystem capacity across all main homelab nodes (`automation-01`, `docker-01`, `colmado-db`) and evaluates against configured disk warnings.
*   **Trigger:** Schedule Trigger, running daily at **8:05 AM**.
*   **Systems Involved:** `automation-01` (n8n), remote target hosts (`docker-01` and `colmado-db` via passwordless SSH from `automation-01`).
*   **Major Processing Steps:**
    1.  Connects via SSH to `automation-01` and queries root filesystem details on all three hosts sequentially.
    2.  Executes JavaScript parsing block to split output fields per host (size, used, available, percentage) and check connection states.
    3.  Compares usage percentage against two internal levels: Warning (**80%**) and Critical (**90%**).
    4.  Prepares formatted message with status emojis (`✅`, `⚠️`, or `🚨`) for each server.
    5.  Posts unified report payload to Discord Webhook.
*   **Discord Alerts:** Yes. Sends disk metrics (used, total, available space) for all nodes and flags warning/critical levels.
*   **Expected Output:** Combined markdown status message ready for Discord webhook.
*   **Failure Points & Validation:**
    *   *Failure:* Host unreachable or target filesystem structure output deviates from expected format.
    *   *Validation:* SSH to `automation-01` and run `df -h /`.

### C. Homelab Container Status Report
*   **Status:** Active
*   **Purpose:** Validates that all expected containers on the control plane `automation-01`, app server `docker-01`, and database server `colmado-db` are active and running.
*   **Trigger:** Schedule Trigger, running daily at **8:02 AM**.
*   **Systems Involved:** `automation-01` (n8n), remote Docker engines on `docker-01` and `colmado-db` via SSH.
*   **Major Processing Steps:**
    1.  Connects to `automation-01` via SSH and executes Docker status check on `automation-01` (10 containers), `docker-01` (8 containers), and `colmado-db` (13 Supabase containers).
    2.  Processes stdout with JavaScript to check running container status values against a hardcoded list of expected containers for each server host.
    3.  Constructs a consolidated report markdown list showing container statuses or warning alerts.
    4.  Flashes warning alerts (`🚨 Container: Missing / Not running`) or normal online status lines (`✅ Container: Up X hours`). If all expected containers on a host are active, it outputs a single healthy summary line to keep the Discord message compact.
    5.  Sends output message to Discord Webhook.
*   **Discord Alerts:** Yes. Complete status overview of all app and control plane stacks.
*   **Expected Output:** Emojis list of container states per host.
*   **Failure Points & Validation:**
    *   *Failure:* SSH connection timeout or Docker daemon offline.
    *   *Validation:* Manually execute `docker ps` on the respective VM to trace container status.

### D. Proxmox USB Backup Verification
*   **Status:** Inactive
*   **Purpose:** Audits Proxmox backup logs and checks external backup storage. The workflow is currently disabled, and the Proxmox backup target remained unavailable at the 2026-06-21 review.
*   **Trigger:** Schedule Trigger, running daily at **3:45 AM**.
*   **Systems Involved:** `automation-01` (n8n), Proxmox Hypervisor Host (`10.0.0.167`).
*   **Major Processing Steps:**
    1.  Runs SSH script query on Proxmox host. Determines USB mount status (`findmnt -n /mnt/usb-drive`), latest backup timestamp, backup sizes, count in last 24h, and total backup archive counts under `/mnt/usb-drive/proxmox-backups/dump`.
    2.  Processes values inside JavaScript parsing block. Checks conditions: USB drive must be mounted, latest backup must be present, and backup count in last 24h must be greater than 0.
    3.  Prepares status indicator flags (`backupOk = true/false`).
    4.  Posts report summary to Discord Webhook.
*   **Discord Alerts:** Yes. Outputs mount status, disk usage metrics, backup logs, and flags missing backups.
*   **Expected Output:** Formatted report payload.
*   **Failure Points & Validation:**
    *   *Failure:* USB backup disk becomes unmounted on the hypervisor host.
    *   *Failure:* SSH key/access details rejected by Proxmox host.
    *   *Validation:* SSH into Proxmox and execute `df -h /mnt/usb-drive` and check backup logs in Proxmox UI.

### E. Daily Homelab Health Report
*   **Status:** Active
*   **Purpose:** Performs web service availability pings on local dashboard targets and reports offline states.
*   **Trigger:** Schedule Trigger, running daily at **8:00 AM**.
*   **Systems Involved:** `automation-01` (n8n), web interfaces on `automation-01`, `docker-01`, and `colmado-db`.
*   **Major Processing Steps:**
    1.  Iterates through a hardcoded service catalog inside `Service List` (JavaScript Node) defining local service endpoints including Homepage, Uptime Kuma, n8n, Portainer, Semaphore, NPM, Nextcloud, Dozzle, Proxmox, Pi-hole, Netdata, and Supabase Studio.
    2.  Dispatches `HTTP Request` nodes to perform GET checks. Configured with "On Error -> Continue" to handle failures without halting the workflow.
    3.  Evaluates status arrays in `Build Discord Report`. Compiles online statuses or collects query errors (`result.error` values).
    4.  Formats a Markdown dashboard list and pushes details to Discord.
*   **Discord Alerts:** Yes. Pushes complete health list showing Online/DOWN indicators and error descriptions.
*   **Expected Output:** Web health log and Discord content block.
*   **Failure Points & Validation:**
    *   *Failure:* n8n loses DNS or bridge routing, triggering false positive offline logs.
    *   *Validation:* Manually visit homepage or check container statuses in Portainer.

### F. Zoho Weekly Recruitment Report
*   **Status:** Inactive (Active: False)
*   **Purpose:** Gathers recruitment metrics from Zoho API and exports spreadsheet reports.
*   **Trigger:** Schedule Trigger, weekly on **Thursday at 7:00 AM**.
*   **Systems Involved:** `automation-01` (n8n), Zoho Recruit API endpoints.
*   **Major Processing Steps:**
    1.  Calculates report start date (previous Thursday) and end date (Wednesday).
    2.  Sends client parameters to `https://accounts.zoho.com/oauth/v2/token` to renew access credentials.
    3.  Queries Zoho Recruit API for Applications, Interviews, and Job Openings data.
    4.  Correlates records inside `Build Weekly Job Report Rows` JS node. Calculates weekly numbers for candidates worked, interviews conducted, and client-scheduled meetings.
    5.  Passes rows to `Spreadsheet File` node to convert arrays to binary Excel format.
*   **Discord Alerts:** No.
*   **Expected Output:** Binary Excel spreadsheet file containing job tables.
*   **Failure Points & Validation:**
    *   *Failure:* Zoho API credentials expire, OAuth secrets rotated, or API limits exceeded.

### G. Zoho Weekly Recruitment Report - v2 Financials
*   **Status:** Inactive (Active: False)
*   **Purpose:** Extracts weekly recruitment statistics, outputs a JSON payload, writes it to a file on `automation-01`, uses a python container to fill an Excel template, and downloads the file.
*   **Trigger:** Schedule Trigger, weekly on **Thursday at 7:00 AM**.
*   **Systems Involved:** `automation-01` (n8n), Zoho Recruit API, Docker runtime python execution container.
*   **Major Processing Steps:**
    1.  Calculates date window, refreshes Zoho credentials, and retrieves Interviews, Openings, and Applications.
    2.  Processes metrics rows, converting arrays to a single JSON payload block (`Convert Rows to JSON Payload`).
    3.  Writes JSON file data to `/opt/stacks/n8n/n8n_data/reports/weekly-recruitment-data.json` via SSH command.
    4.  Launches transient python environment via Docker to run helper template script:
        `docker run --rm -v /opt/stacks/n8n/n8n_data:/work python:3.12-alpine sh -lc "pip install openpyxl >/tmp/pip.log && python /work/scripts/fill_weekly_recruitment_template.py"`
    5.  Downloads Excel output file.
*   **Discord Alerts:** No.
*   **Expected Output:** Formatted Excel spreadsheet compiled using template script.
*   **Failure Points & Validation:**
    *   *Failure:* Python script execution error, `openpyxl` installation failure in container, or template missing from `/opt/stacks/n8n/n8n_data/templates/`.

### H. Semaphore Auto-Remediation
*   **Status:** Active
*   **Purpose:** Listens for Uptime Kuma offline webhooks and automatically triggers the Semaphore template "Upgrade Docker Stack" (Template ID `4`) to self-heal the container or service that crashed.
*   **Trigger:** Webhook, path: `/webhook/uptime-kuma-remediation`.
    > [!IMPORTANT]
    > **Webhook URL Path Structure:** Due to n8n's project-scoped workspace isolation, the external webhook URL path requires the project ID namespace (`B06E5kNH1VaAud21`) and a nested `/webhook/` routing structure.
    > - **Production URL:** `https://n8n.yourdomain.com/webhook/B06E5kNH1VaAud21/webhook/uptime-kuma-remediation`
    > - **Test URL:** `https://n8n.yourdomain.com/webhook-test/B06E5kNH1VaAud21/webhook/uptime-kuma-remediation`
    >
    > Using the clean endpoint path (without the workspace ID and double `/webhook/` prefix) will result in a `404 Webhook not registered` error.
*   **Systems Involved:** `automation-01` (n8n), Semaphore API (`ansible.local.yourdomain.com (`10.0.0.67:3005`)`), remote hosts (`docker-01`, `automation-01` via Semaphore).
*   **Major Processing Steps:**
    1.  Receives Uptime Kuma webhook alert payload.
    2.  Validates that status is DOWN (`heartbeat.status === 0`).
    3.  Maps the monitored service name to its Docker Compose stack name and target host group (e.g. `Nextcloud` -> stack `nextcloud` on host `docker-01`).
    4.  Sends a POST request to Semaphore's `/api/project/1/tasks` endpoint with the `stack_name` survey variable and `limit` parameter set to the target host.
    5.  Posts an auto-remediation trigger notice to Discord.
*   **Discord Alerts:** Yes. Reports when auto-remediation is kicked off, detailing the down service, mapped stack, and target host.
*   **Failure Points & Validation:**
    *   *Failure:* Invalid Semaphore API token, or Semaphore is offline.
    *   *Failure:* Monitored service is not mapped in the JavaScript switch statement.
    *   *Validation:* Send a test POST payload using curl or Postman to the n8n webhook.

### I. Automatic Disk Space Remediation
*   **Status:** Active
*   **Purpose:** Triggers the Docker Disk & Log Cleanup playbook (Template ID `3`) when any server's root partition disk usage matches or exceeds 90%.
*   **Trigger:** Schedule Trigger, running hourly (`0 * * * *`).
*   **Systems Involved:** `automation-01` (n8n), Semaphore API (`ansible.local.yourdomain.com (`10.0.0.67:3005`)`), all Linux hosts (`automation-01`, `docker-01`, `colmado-db` via Semaphore).
*   **Major Processing Steps:**
    1.  Runs `df -h /` on all nodes sequentially (similar to the daily health check).
    2.  Parses the output and checks if any host has root partition space `>= 90%`.
    3.  For each critical host, calls the Semaphore API to run Template ID `3` (Docker Disk & Log Cleanup) with the target host in the `limit` parameter.
    4.  Sends an emergency warning and remediation trigger message to Discord.
*   **Discord Alerts:** Yes. Sends warnings and triggers alerts only when critical space capacity is reached.
*   **Failure Points & Validation:**
    *   *Failure:* SSH command failure, preventing disk stats from being read.
    *   *Failure:* Semaphore API token expired.
    *   *Validation:* Manually adjust the threshold to a lower value (e.g. `10%`) in the JS code node and run the workflow to verify the cleanup triggers.



## 6. Credentials and Security Handling

n8n credentials (SSH keys, OAuth client secrets, API keys, and webhooks) are **never documented in plaintext** and are excluded from Git exports to prevent security compromises.

*   **Secrets Storage:** All credentials are encrypted and stored in the SQLite database in `/opt/stacks/n8n/n8n_data/database.sqlite` inside the container.
*   **Workflow Export Security:** The exported JSON workflow files under `n8n-workflows/` contain metadata and connection schemas but omit secret values, passwords, and private SSH key strings. Instead, they reference internal credential names and IDs (e.g. `bynhm7FCsOYKpzkI` for SSH connections).
*   **Discord Webhook Security:** Webhook URL details are masked using internal n8n credential objects (`discordWebhookApi` references).

---

## 7. Backup and Recovery Procedure

### A. SQLite Database Backup (Application State)
Since all workflows, settings, and credentials live in `/opt/stacks/n8n/n8n_data/database.sqlite`, backup of the application state requires backing up this directory.
1.  Verify the volume directory `/opt/stacks/n8n/n8n_data` is captured in server filesystem backup schedules.
2.  Stop the n8n container before copying the database to prevent write locks:
    ```bash
    cd /opt/stacks/n8n
    docker compose down
    tar -czf /opt/backups/n8n-data-$(date +%F).tar.gz n8n_data/
    docker compose up -d
    ```

### B. Recovery
To restore n8n on a fresh instance:
1.  Copy the backed-up `n8n_data` directory to `/opt/stacks/n8n/n8n_data`.
2.  Deploy using the compose definition at `docker/automation-01/n8n/docker-compose.yml`.
3.  Start containers: `docker compose up -d`.

---

## 8. Maintenance & Workflow Export Procedure

When editing or creating workflows in the n8n GUI, changes are exported to the Git repository to maintain version control for configuration files.

### Manual Workflow Export Command
Run the export command using the n8n CLI utility within the running container. This outputs pretty-printed, separate files for each workflow into a target folder:

1.  **Run the Export inside the Container:**
    ```bash
    docker exec -t n8n n8n export:workflow --backup --output=/home/node/.n8n/export-$(date +%F)/
    ```
2.  **Copy the Export to the Repository Path:**
    ```bash
    mkdir -p ~/repos/homelab/n8n-workflows/export-$(date +%F)
    cp -r /opt/stacks/n8n/n8n_data/export-$(date +%F)/*.json ~/repos/homelab/n8n-workflows/export-$(date +%F)/
    ```
3.  **Track in Git:**
    ```bash
    cd ~/repos/homelab
    git add n8n-workflows/
    git commit -m "Backup: Update n8n workflows export for $(date +%F)"
    ```

---

## 9. Current Limitations & Next Improvements

### Current Limitations
1.  **Workflow Definitions Only:** The automated Git export sanitizes and protects workflow definitions, but it is not a complete backup of n8n application state.
2.  **SQLite Database Backup:** There is no verified automated backup and restore process for the persistent `/opt/stacks/n8n/n8n_data/` directory.
3.  **Dangling Test Workflows:** Several unused test workflows (`My workflow 2`, `My workflow 3`, and the archived `My workflow`) are in the database and should be pruned.
4.  **Log File Size Monitoring:** The `n8n` container writes JSON stdout logs without default limits, which can eventually fill up `/var/lib/docker/containers` on `automation-01`.

### Next Improvements
*   [ ] **Application-State Recovery:** Back up the n8n data directory independently and complete a restore test.
*   [ ] **Clean Stale Workflows:** Clean up the inactive placeholder workflows in the database.
*   [ ] **Enable Docker Log Limits:** Add a log-driver limit configuration inside `docker-compose.yml` for the n8n service to prevent disk-bloat.

---
