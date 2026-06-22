#!/usr/bin/env bash
# harden-db.sh - Secure and clean colmado-db VM (10.0.0.35)
# This script must be run with sudo on colmado-db.

set -euo pipefail

echo "===================================================="
echo "Starting colmado-db Hardening and Maintenance Script"
echo "===================================================="

# 1. Truncate Docker logs
echo -n "1. Truncating current Docker container JSON logs... "
if [ -d /var/lib/docker/containers ]; then
    sudo sh -c 'truncate -s 0 /var/lib/docker/containers/*/*-json.log' 2>/dev/null || true
    echo "Done."
else
    echo "Docker container directory not found. Skipping."
fi

# 2. Configure Docker Daemon Log Rotation Limits
DAEMON_JSON="/etc/docker/daemon.json"
echo "2. Configuring Docker daemon log rotation limits at $DAEMON_JSON..."

# Backup daemon.json if it exists
if [ -f "$DAEMON_JSON" ]; then
    echo "   Backing up existing daemon.json..."
    sudo cp "$DAEMON_JSON" "${DAEMON_JSON}.bak"
fi

# Write new daemon.json
sudo tee "$DAEMON_JSON" > /dev/null << 'INNER_EOF'
{
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "10m",
    "max-file": "3"
  }
}
INNER_EOF
echo "   New daemon.json written."

# 3. Add UFW DOCKER-USER rules
UFW_AFTER_RULES="/etc/ufw/after.rules"
echo "3. Appending DOCKER-USER firewall rules to $UFW_AFTER_RULES..."

# Backup after.rules
sudo cp "$UFW_AFTER_RULES" "${UFW_AFTER_RULES}.bak"

# Remove any existing BEGIN/END UFW AND DOCKER HARDENING blocks to prevent duplication
sudo sed -i '/# BEGIN UFW AND DOCKER HARDENING/,/# END UFW AND DOCKER HARDENING/d' "$UFW_AFTER_RULES"

# Append the hardening rules at the end of the file
sudo tee -a "$UFW_AFTER_RULES" > /dev/null << 'INNER_EOF'

# BEGIN UFW AND DOCKER HARDENING
*filter
:DOCKER-USER - [0:0]
-A DOCKER-USER -m conntrack --ctstate RELATED,ESTABLISHED -j ACCEPT
-A DOCKER-USER -i ens18 -s 10.0.0.0/24 -p tcp -m conntrack --ctorigdstport 8000 --ctdir ORIGINAL -j RETURN
-A DOCKER-USER -i ens18 -s 10.0.0.0/24 -p tcp -m conntrack --ctorigdstport 5432 --ctdir ORIGINAL -j RETURN
-A DOCKER-USER -i ens18 -s 10.0.0.0/24 -p tcp -m conntrack --ctorigdstport 5434 --ctdir ORIGINAL -j RETURN
-A DOCKER-USER -i ens18 -p tcp -m conntrack --ctorigdstport 8000 --ctdir ORIGINAL -j DROP
-A DOCKER-USER -i ens18 -p tcp -m conntrack --ctorigdstport 5432 --ctdir ORIGINAL -j DROP
-A DOCKER-USER -i ens18 -p tcp -m conntrack --ctorigdstport 5434 --ctdir ORIGINAL -j DROP
COMMIT
# END UFW AND DOCKER HARDENING
INNER_EOF
echo "   Firewall rules appended."

# 4. Restart services
echo "4. Restarting Docker daemon..."
sudo systemctl restart docker

echo "5. Reloading UFW firewall..."
sudo ufw reload

echo "===================================================="
echo "colmado-db Hardening and Maintenance Complete!"
echo "===================================================="
