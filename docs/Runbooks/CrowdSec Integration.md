# 📓 Runbook: CrowdSec IPS Integration

This runbook guides you through the step-by-step installation, configuration, and integration of CrowdSec (IPS) with your Wazuh SIEM on `security-01` and workload servers (`docker-01`, `automation-01`, `colmado-db`).

---

## 🛠️ Step 1: Pre-requisite Wazuh JVM Tuning on `security-01`

Because `security-01` has only 4GB of RAM, we must limit the Wazuh Indexer (OpenSearch) memory footprint before deploying any additional services to prevent Out-Of-Memory (OOM) crashing.

1. SSH into `security-01`:
   ```bash
   ssh security-01
   ```
2. Open the indexer JVM configuration file:
   ```bash
   sudo nano /etc/wazuh-indexer/jvm.options
   ```
3. Locate the `-Xms` and `-Xmx` lines. Set them to `1g` (or `1.2g` if resource permits):
   ```properties
   -Xms1g
   -Xmx1g
   ```
4. Save and close the file.
5. Restart the Wazuh Indexer:
   ```bash
   sudo systemctl restart wazuh-indexer
   ```
6. Check memory usage to verify stability:
   ```bash
   free -h
   ```

---

## 🛡️ Step 2: Install CrowdSec LAPI on `security-01`

1. Add the official CrowdSec repository and install the security engine:
   ```bash
   curl -s https://install.crowdsec.net | sudo sh
   sudo apt-get install crowdsec -y
   ```
2. Configure CrowdSec LAPI to listen on all interfaces (so workload nodes can connect):
   * Open `/etc/crowdsec/config.yaml`.
   * Locate the `api.server.listen_uri` setting and change it to:
     ```yaml
     api:
       server:
         listen_uri: 0.0.0.0:8080
     ```
3. Configure the local agent on `security-01` to connect to LAPI:
   * Open `/etc/crowdsec/local_api_credentials.yaml`.
   * Update the `url` to point to `http://10.0.0.40:8080`.
4. Restart the CrowdSec service:
   ```bash
   sudo systemctl restart crowdsec
   ```
5. Configure UFW firewall on `security-01` to allow agents to connect:
   ```bash
   sudo ufw allow from 10.0.0.0/24 to any port 8080 proto tcp comment 'CrowdSec LAPI'
   ```

---

## 💻 Step 3: Install CrowdSec Agents on Workload Nodes

Repeat the following on **`docker-01`**, **`automation-01`**, and **`colmado-db`**:

1. Add the repository and install CrowdSec:
   ```bash
   curl -s https://install.crowdsec.net | sudo sh
   sudo apt-get install crowdsec -y
   ```
2. Register the agent with the central LAPI server on `security-01` (specifying a unique machine name):
   ```bash
   sudo cscli lapi register -u http://10.0.0.40:8080 --machine <unique_machine_name>
   ```
3. **On `security-01` (LAPI Server):** Accept the new machine:
   ```bash
   sudo cscli machines list
   sudo cscli machines validate <machine_name>
   ```
4. **On the workload node:** Disable the local LAPI service (since it only acts as an agent):
   * Open `/etc/crowdsec/config.yaml`.
   * Set `api.server.enable` to `false`:
     ```yaml
     api:
       server:
         enable: false
     ```
5. Restart the CrowdSec service:
   ```bash
   sudo systemctl restart crowdsec
   ```

---

## 🛡️ Step 4: Install Firewall Bouncers on Workload Nodes

Install the firewall bouncer on **`docker-01`**, **`automation-01`**, and **`colmado-db`** to drop malicious traffic at the host level:

1. **On `security-01` (LAPI Server):** Generate an API key for the bouncer:
   ```bash
   sudo cscli bouncers add <HOSTNAME>-bouncer
   ```
   *Copy the generated API key.*
2. **On the workload node:** Install the firewall bouncer package:
   ```bash
   sudo apt-get install crowdsec-firewall-bouncer-iptables -y
   ```
3. Configure the bouncer to connect to LAPI:
   * Open `/etc/crowdsec/bouncers/crowdsec-firewall-bouncer.yaml`.
   * Update the configuration details:
     ```yaml
     api_url: http://10.0.0.40:8080
     api_key: <COPIED_API_KEY>
     ```
4. Restart the bouncer service:
   ```bash
   sudo systemctl restart crowdsec-firewall-bouncer
   ```
5. Verify registration **on `security-01`**:
   ```bash
   sudo cscli bouncers list
   ```

---

## 📊 Step 5: Integrate CrowdSec Alerts with Wazuh

This configures CrowdSec LAPI to export alerts to a JSON file and configures the Wazuh agent to monitor and ingest it.

### 1. Configure JSON Notification in CrowdSec on `security-01`
1. Open `/etc/crowdsec/notifications/file.yaml` (create it if it doesn't exist).
2. Configure it to write alerts in NDJSON format:
   ```yaml
   type: file
   name: wazuh
   log_level: info
   format: |
     {{range . -}}
     { "crowdsec": { "time": "{{.CreatedAt}}", "program": "crowdsec", "alert": {{. | toJson }} }}
     {{ end -}}
   log_path: "/var/log/crowdsec_alerts.json"
   ```
3. Edit `/etc/crowdsec/profiles.yaml` to include this notification plugin in your default profile:
   ```yaml
   name: default_ip_remediation
   filters:
    - Alert.Remediation == true
   decisions:
    - type: ban
      duration: 4h
   notifications:
     - wazuh
   on_success: break
   ```
4. Create the log file and set proper permissions so the notification plugin (running as `nobody:nogroup`) can write to it, and Wazuh (which runs as group `ossec` or `wazuh`) can read it:
   ```bash
   sudo touch /var/log/crowdsec_alerts.json
   sudo chown nobody:nogroup /var/log/crowdsec_alerts.json
   sudo chmod 664 /var/log/crowdsec_alerts.json

   # Add the wazuh/ossec user to the nogroup group so it can read the file
   sudo usermod -a -G nogroup wazuh 2>/dev/null || sudo usermod -a -G nogroup ossec
   ```
5. Restart CrowdSec:
   ```bash
   sudo systemctl restart crowdsec
   ```

### 2. Configure Wazuh Agent on `security-01` to Monitor JSON Alerts
1. Open `/var/ossec/etc/ossec.conf` on `security-01`.
2. Add the log ingestion configuration:
   ```xml
   <localfile>
     <log_format>json</log_format>
     <location>/var/log/crowdsec_alerts.json</location>
   </localfile>
   ```
3. Restart the Wazuh agent:
   ```bash
   sudo systemctl restart wazuh-agent
   ```

### 3. Add Custom Rules on Wazuh Manager
1. Open the rules configuration file:
   ```bash
   sudo nano /var/ossec/etc/rules/local_rules.xml
   ```
2. Add the custom rules for CrowdSec:
   ```xml
   <group name="crowdsec,">
     <!-- Base Rule -->
     <rule id="100005" level="3">
       <decoded_as>json</decoded_as>
       <field name="crowdsec.program">crowdsec</field>
       <description>CrowdSec alert group</description>
     </rule>

     <!-- Alert Rule for IP Ban Decisions -->
     <rule id="100006" level="10">
       <if_sid>100005</if_sid>
       <field name="crowdsec.alert.decisions.0.type">ban</field>
       <description>CrowdSec banned $(crowdsec.alert.decisions.0.value) for $(crowdsec.alert.decisions.0.duration) due to $(crowdsec.alert.decisions.0.scenario)</description>
     </rule>
   </group>
   ```
3. Restart the Wazuh manager:
   ```bash
   sudo systemctl restart wazuh-manager
   ```

---

## 🔍 Step 6: Verification

1. **Verify Alert Ingestion:** Use `wazuh-logtest` to test parser functionality.
   ```bash
   sudo /var/ossec/bin/wazuh-logtest
   ```
   Paste a mock log message:
   ```json
   {"crowdsec": {"time": "2026-06-14T20:00:00Z", "program": "crowdsec", "alert": {"decisions": [{"type": "ban", "value": "1.2.3.4", "duration": "4h", "scenario": "crowdsecurity/ssh-bf"}]}}}
   ```
   Verify that it matches **Rule ID 100006** and outputs `level 10`.

2. **Trigger Mock Ban:** Simulate a ban to confirm the bouncer blocks traffic and the alert surfaces in the SIEM:
   ```bash
   sudo cscli decisions add --ip 1.2.3.4 --duration 10m --reason "manual test"
   ```
   Verify:
   * The ban is in effect: `sudo cscli decisions list`
   * The alert is logged: `sudo cat /var/log/crowdsec_alerts.json`
   * The rule is applied by checking active firewall tables on remote nodes: `sudo iptables -L -n -v` (look for `crowdsec` chains).
   * Delete the test decision: `sudo cscli decisions delete --ip 1.2.3.4`

---

## 🚀 Step 7: Advanced Integrations

### 1. 🌐 Nginx Proxy Manager Protection (on `automation-01`)
To protect your self-hosted web applications from HTTP brute-force, directory traversal, web scanning, and vulnerability probing:

1. **Install Nginx Collection:**
   ```bash
   sudo cscli collections install crowdsecurity/nginx
   ```
2. **Configure Log Acquisition:** Create `/etc/crowdsec/acquis.d/nginx-proxy-manager.yaml` to tail the NPM container bind-mounted logs on the host:
   ```yaml
   filenames:
     - /opt/stacks/nginx-proxy-manager/data/logs/proxy-host-*_access.log
     - /opt/stacks/nginx-proxy-manager/data/logs/proxy-host-*_error.log
     - /opt/stacks/nginx-proxy-manager/data/logs/fallback_http_access.log
     - /opt/stacks/nginx-proxy-manager/data/logs/fallback_error.log
   labels:
     type: nginx
   ```
3. **Restart Agent:**
   ```bash
   sudo systemctl restart crowdsec
   ```

### 2. 💬 Real-Time SIEM Alerts in Discord (on `security-01`)
Configure Wazuh Manager to automatically format and push critical alerts (Level 10+) to your Discord channel using Slack-webhook compatibility:

1. **Configure Webhook Integration:** Open `/var/ossec/etc/ossec.conf` and append:
   ```xml
   <ossec_config>
     <integration>
       <name>slack</name>
       <!-- Appending /slack to the Discord webhook maps the payloads automatically -->
       <hook_url>https://discord.com/api/webhooks/YOUR_WEBHOOK_ID/YOUR_WEBHOOK_TOKEN/slack</hook_url>
       <level>10</level>
       <alert_format>json</alert_format>
     </integration>
   </ossec_config>
   ```
2. **Restart Wazuh Manager:**
   ```bash
   sudo systemctl restart wazuh-manager
   ```

