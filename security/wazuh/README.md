# Wazuh SIEM & EDR Blueprint — security-01

This directory covers the deployment roadmap and configuration files for the **Wazuh SIEM & EDR** security stack, which is planned for deployment on a new Proxmox VM.

## Deployment Architecture

```mermaid
graph TD
    subgraph Clients ["Endpoints & Agents"]
        AUTO["automation-01 (Wazuh Agent)"]
        DOCK["docker-01 (Wazuh Agent)"]
        COLM["colmado-db (Wazuh Agent)"]
        PVE["Proxmox Host (Wazuh Agent)"]
        WINDC["WIN-SERVER (Wazuh Agent + Sysmon)"]
    end

    subgraph SecurityServer ["Security Control Plane (10.0.0.9)"]
        WAZUH["Wazuh Manager (security-01)"]
        DASH["Wazuh Dashboard"]
        IDX["Wazuh Indexer"]
    end

    AUTO -->|Port 1514 (Syslog/Agent)| WAZUH
    DOCK -->|Port 1514 (Syslog/Agent)| WAZUH
    COLM -->|Port 1514 (Syslog/Agent)| WAZUH
    PVE -->|Port 1514 (Syslog/Agent)| WAZUH
    WINDC -->|Port 1514 (Syslog/Agent)| WAZUH

    WAZUH --> IDX
    DASH -->|Read/Query| IDX
```

## Host Allocation (Planned)
- **VM Name:** `security-01`
- **IP Address:** `10.0.0.9` (Planned)
- **Role:** Security logging, alerting, and vulnerability assessment
- **Specifications:** 4 vCPUs, 8 GB RAM, 80 GB SSD Storage
- **OS:** Ubuntu Server 22.04 LTS

## Phase 1: Ansible Agent Deployment
Once the Wazuh Manager is active, agents will be rolled out using Ansible. An Ansible role will automate:
1. Importing the Wazuh repository GPG keys.
2. Installing `wazuh-agent`.
3. Configuring `/var/ossec/etc/ossec.conf` to declare `10.0.0.9` as the primary manager endpoint.
4. Starting and enabling the `wazuh-agent` system daemon.

## Phase 2: Auditing & Active Response Targets
- **SSH Auditing:** Monitor successful and failed SSH log attempts across Linux hosts.
- **UFW Integration:** Enable Wazuh Active Response to trigger temporary firewall blocks via `ufw` on nodes encountering SSH brute-force patterns.
- **Docker Monitoring:** Ingest daemon logs (`/var/log/docker.log` or socket telemetry) to detect unauthorized container creation or permission shifts.
- **Windows Integration:** Pair the Wazuh agent on `WIN-SERVER` and `WIN-CLIENT` with Microsoft Sysmon to track domain controller logins and process creation logs.
