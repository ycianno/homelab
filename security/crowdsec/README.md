# CrowdSec IPS Blueprint — security-01

This directory covers the deployment roadmap and architecture for **CrowdSec**, a modern Intrusion Prevention System (IPS) that leverages community-driven threat intelligence.

## CrowdSec Architecture

```mermaid
graph TD
    subgraph Exposed ["Exposed / Web Services"]
        NPM["Nginx Proxy Manager (automation-01/security-01)"]
        CFT["Cloudflared Tunnel (docker-01)"]
    end

    subgraph Defense ["Security Stack"]
        CS_LAPI["CrowdSec Local API (security-01)"]
        CS_AGENT1["CrowdSec Agent (automation-01)"]
        CS_AGENT2["CrowdSec Agent (docker-01)"]
    end

    subgraph Action ["Remediation (Bouncers)"]
        BOUNCER_NPM["NPM Web Firewall Bouncer"]
        BOUNCER_FW["UFW Firewall Bouncer"]
    end

    NPM -->|Logs| CS_AGENT1
    CFT -->|Logs| CS_AGENT2

    CS_AGENT1 -->|Report Alerts| CS_LAPI
    CS_AGENT2 -->|Report Alerts| CS_LAPI

    CS_LAPI -->|Decisions / Block Rules| BOUNCER_NPM
    CS_LAPI -->|Decisions / Block Rules| BOUNCER_FW
```

## Setup Plan

### 1. Central Local API (LAPI)
- Deploy CrowdSec central engine on `security-01` (`10.0.0.9`) to host the Local API database.
- Centralize alert logs and coordinate block decisions across the network.

### 2. Distributed CrowdSec Agents
- Install CrowdSec agent services on `automation-01` and `docker-01`.
- Configure agents to monitor specific service logs:
  - **Nginx Proxy Manager access logs** (detect HTTP brute-force, web scrapers, path traversal attempts).
  - **SSH secure logs** (detect system credential brute forcing).
  - **Nextcloud security logs** (detect application login brute forcing).

### 3. Remediation Bouncers
- **Nginx Bouncer:** Deploy an OpenResty/Nginx Lua bouncer inside Nginx Proxy Manager to intercept malicious HTTP requests immediately and present captcha/block pages.
- **Firewall Bouncer:** Deploy the `crowdsec-firewall-bouncer` on Linux hosts to drop traffic at the UFW level using iptables/ipset tables.
