---
tags:
  - homelab
  - server
  - supabase
  - vitrina
  - colmado
created: 2026-05-30
ip: 10.0.0.35
vmid: 101
os: Ubuntu 24.04
aliases:
  - TUMANDAO
---

# colmado-db

| Property | Value |
| -------- | ----- |
| IP       | `10.0.0.35` |
| VM ID    | 101 |
| Role     | Vitrina dev database (Supabase) |
| CPU      | 2 vCPU |
| RAM      | 8 GB |
| Disk     | 50 GB |
| OS       | Ubuntu 24.04 |
| Former name | TUMANDAO |
| Last verified | 2026-06-21 |

## Access

| Method | URL / Command |
| ------ | ------------- |
| Supabase Studio | `https://supabase.local.yourdomain.com (Internal IP: `http://supabase.local.yourdomain.com (`10.0.0.35:8000`)`)` |
| SSH | `ssh colmado-db` |

## Services (Docker — Full Supabase Stack)

| Container | Port | Purpose |
| --------- | ---- | ------- |
| supabase-kong | 8000, 8443 | API Gateway |
| supabase-studio | 3000 (internal) | Studio UI (via Kong on 8000) |
| supabase-auth | internal | GoTrue auth |
| supabase-storage | internal | S3-compatible storage |
| supabase-rest | internal | PostgREST |
| supabase-db | 5434 (host), 5432 (internal) | PostgreSQL 15 |
| supabase-pooler | 5432 (host), 6543 | Supavisor connection pooler |
| supabase-analytics | 4000 | Logflare analytics |
| supabase-meta | internal | Postgres meta |
| supabase-realtime | internal | Realtime subscriptions |
| supabase-edge-functions | internal | Deno edge functions |
| supabase-vector | internal | Log collection |
| supabase-imgproxy | internal | Image processing |

## Related

- [automation-01](automation-01.md)
