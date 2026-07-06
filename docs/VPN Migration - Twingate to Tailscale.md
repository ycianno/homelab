# VPN Migration: Ditching Twingate for Tailscale

This document details the architectural migration from Twingate to Tailscale, explaining the technical rationale, setup steps, and operational advantages of our keyless administrative VPN configuration.

---

## 🎯 Strategic Goals

1. **Eliminate SSH Key Management Overhead**: Replace traditional static SSH public/private key pairs with identity-based authentication for server administration.
2. **Reduce Resource Overhead**: Delete the dedicated Twingate LXC container to free up CPU, memory, and storage on the hypervisor.
3. **Consolidate VPN Services**: Standardize on a single, secure mesh VPN provider (Tailscale) for remote connectivity, subnet routing, and secure internet exit node capabilities.
4. **Maintain Auditing & Visibility**: Preserve our real-time Discord notification system for all SSH logins, including Tailscale SSH sessions.

---

## ⚖️ Twingate vs. Tailscale: Comparative Rationale

| Architectural Area | Legacy Twingate Setup | Modern Tailscale Setup | Technical Advantage |
| :--- | :--- | :--- | :--- |
| **Authentication** | Local SSH Keys + Cloud-managed Twingate Portal | Tailscale Identity (GitHub Auth) + ACL policies | **Keyless Security**: Eliminates static SSH private keys on the client and `authorized_keys` files on servers. Auth is tied directly to active GitHub sessions. |
| **VPN Architecture** | Dedicated LXC Container (`104`) routing LAN traffic | Hypervisor-level (`proxmox` host) Subnet Router | **Reduced Latency & Maintenance**: Directly leverages the Proxmox host's kernel WireGuard implementation. Recovers `512 MB RAM` and `3 GB NVMe disk` by deleting container 104. |
| **DNS Resolution** | Twingate client intercepts specific DNS resources | MagicDNS + Split DNS (100.100.100.100 resolver) | **Standardized DNS**: Tailscale natively forwards private domain queries (`*.local.ycianno.uk`) to Pi-hole (`10.0.0.20`) via the Subnet Router. |
| **SSH Alerts** | PAM hook on `/etc/pam.d/sshd` triggers Discord notifications | PAM hooks on both `/etc/pam.d/sshd` and `/etc/pam.d/tailscale` | **Full Visibility**: Tailscale SSH sessions bypass standard sshd, so we built a custom Tailscale PAM service to log sessions explicitly as `MacBook Pro (via Tailscale SSH)`. |

---

## 🏗️ Detailed Migration Steps Completed

### 1. Activating Tailscale SSH Server
Tailscale SSH allows Tailscale to take over port 22 on the tailnet interface.
* **Nodes Configured**: `automation-01`, `docker` (local VM `docker-01`), `yzee` (local VM `colmado-db`), `security-01`, and `proxmox`.
* **Verification**: Ran SSH diagnostics from the Mac Mini to confirm all 5 servers accepted keyless/passwordless handshakes based purely on GitHub Tailscale identity.
* **macOS Tagging Gotcha**: The admin workstation (`yzees-mac-mini`) must remain **untagged** (registered directly under the owner `ycianno@github`). Tagging the Mac with a resource tag removes its user identity context, which prevents it from matching the `autogroup:member` source rule in Tailscale SSH ACLs and breaks connectivity.


### 2. Setting Up Proxmox as Subnet Router & Exit Node
Rather than running routing software inside a virtualized guest (like Twingate did), we configured the bare-metal hypervisor directly:
* **IP Forwarding**: Configured `/etc/sysctl.d/99-tailscale.conf` to enable IPv4/IPv6 forwarding persistently.
* **Route Advertisement**: Instructed `tailscaled` on Proxmox to advertise the physical LAN (`10.0.0.0/24`) and act as a secure exit node for public/untrusted Wi-Fi.

### 3. Decommissioning Twingate
* **Purged Package**: Stopped and purged the `twingate-connector` packages from LXC 104.
* **Destroyed Guest**: Stopped and destroyed the `twingate-connector` LXC in Proxmox to clean up host resources.

### 4. Updating Ansible & Mac SSH Configurations
* **Inventory Update**: Switched `inventory.ini` from local static IPs (`10.0.0.x`) to Tailscale MagicDNS names (`automation-01`, `docker`, `yzee`, `security-01`, `proxmox`).
* **Ansible Configuration**: Created `ansible.cfg` with `host_key_checking = False` to prevent verification warnings when connecting to new Tailscale MagicDNS hostnames.
* **Mac SSH Config**: Updated Mac config to use clean Tailscale MagicDNS aliases without requiring any local key declarations.

### 5. Tailscale SSH Login Alerts Integrations
Standard SSH login alerts run via PAM inside `sshd`. Tailscale SSH bypasses this and manages logins directly via `tailscaled`.
* **Ansible Playbook Update**: Updated `ssh-alerts.yml` to deploy a custom `/etc/pam.d/tailscale` PAM file.
* **Tailscale User Extraction**: Updated the alert script `/usr/local/bin/ssh-login-alert.sh` to parse `$TAILSCALE_SSH_USER` and pass the Tailscale identity to n8n.
* **n8n Workflow Update**: Updated the `sshLoginAlerts` workflow script to classify Tailscale connections, outputting them in Discord as green trusted logs (e.g. `MacBook Pro (via Tailscale SSH)`) while flagging unexpected key-based logins as suspicious.

---

## 🔒 Security Best Practices for Public Git Repository

Since the homelab configuration files are committed to a public, educational repository, we sanitized all sensitive entries before staging:
* **Webhook Sanitization**: Replaced the active Discord webhook URL in `n8n-workflows/active/sshLoginAlerts.json` with a secure placeholder: `https://discord.com/api/webhooks/YOUR_DISCORD_WEBHOOK_ID/YOUR_DISCORD_WEBHOOK_TOKEN`.
* **No IP Leaks**: Switched all Ansible inventory addresses to generic hostname aliases.
* **No Key Leaks**: Switched host-level connections to SSH keyless configuration blocks.
