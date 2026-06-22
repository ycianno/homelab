---
tags:
  - homelab
  - service
  - ai
created: 2026-06-02
---

# Open WebUI

## 📋 Overview
- **Purpose:** ChatGPT-style web interface for local LLMs.
- **Host:** [automation-01](../Servers/automation-01.md) (`10.0.0.67`)
- **Port:** `3080` (mapped to container `8080` to avoid conflict with Homepage)
- **Local URL:** [https://ai.local.yourdomain.com](https://ai.local.yourdomain.com) (Internal IP: `https://ai.local.yourdomain.com (Internal IP: `http://ai.local.yourdomain.com (`10.0.0.67:3080`)`)`) (Internal IP: `https://ai.local.yourdomain.com (Internal IP: `http://ai.local.yourdomain.com (`10.0.0.67:3080`)`)`)
- **Ollama Backend URL:** `http://10.0.0.72:11434` (Mac M4 Host)
- **Config Path:** `/opt/stacks/open-webui`
- **Git Backup Path:** `/home/yzee/repos/homelab/docker/automation-01/open-webui/`

## 🔧 Service Configuration
Open WebUI is deployed as a docker container on `automation-01` and connects to the Ollama service running natively on the macOS workstation host (utilizing Unified Memory and GPU acceleration).

Key Environment variables:
- `OLLAMA_BASE_URL=http://10.0.0.72:11434`

## 💾 Operational Runbook
To restart or manage the stack:
```bash
cd /opt/stacks/open-webui
docker compose restart
```

To view logs:
```bash
docker logs -f open-webui
```

## 📊 Available Models
Currently active models pulled on the Ollama host:
- **`qwen2.5:3b`** (General assistant, coding)
- **`deepseek-r1:8b`** (Advanced reasoning)

## 🔗 Related
- [automation-01](../Servers/automation-01.md)
- [n8n](n8n.md)
