# Supabase Stack — colmado-db

This directory contains the self-hosted **Supabase** development stack configurations for the **Vitrina** project.

## Host Details
- **VM Name:** `colmado-db`
- **IP Address:** `10.0.0.35`
- **VM ID:** `101`
- **RAM:** 8 GB
- **OS:** Ubuntu

## Supabase Services

| Container | Image | Port | Description |
|-----------|-------|------|-------------|
| `supabase-kong` | `kong:2.8.1` | `8000`, `8443` | Reverse proxy and API Gateway |
| `supabase-studio` | `supabase/studio` | Internal | Dashboard web interface (via Kong on 8000) |
| `supabase-auth` | `supabase/gotrue` | Internal | GoTrue auth server |
| `supabase-storage` | `supabase/storage-api` | Internal | S3-compatible file storage |
| `supabase-rest` | `postgrest/postgrest` | Internal | PostgREST API service |
| `supabase-db` | `supabase/postgres` | `5434` (host) | PostgreSQL 15 Database engine |
| `supabase-pooler` | `supabase/supavisor` | `5432` (host) | Supavisor database connection pooler |
| `supabase-analytics` | `supabase/logflare` | `4000` | Logflare log management |
| `supabase-vector` | `timberio/vector` | Internal | Docker log ingestion |

## Access Methods
- **Supabase Studio UI:** `http://10.0.0.35:8000`
- **Database Connection (Direct):** `postgresql://postgres:[password]@10.0.0.35:5434/postgres`
- **Database Connection (Pooler):** `postgresql://postgres:[password]@10.0.0.35:5432/postgres`

## Security & Firewalls
- **UFW Config:** Access to port `8000` and postgres ports is restricted to `localhost` and `automation-01` (`10.0.0.67`).
- **Secrets Management:** Do **NOT** commit the `.env` file to version control. Maintain database secrets inside the local `.env` on `colmado-db`. A sanitized template is available at `.env.example`.

## Disk Maintenance
- Disk usage on `colmado-db` should be monitored. Prune dangling docker volumes/images regularly:
  ```bash
  docker system prune -a --volumes
  ```
- Docker container log rotation is configured on the host to avoid disk depletion.
