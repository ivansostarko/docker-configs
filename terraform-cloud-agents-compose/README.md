# Terraform + HCP Terraform (Terraform Cloud) Agents (Docker Compose)

This repository provides:
- A **local Terraform CLI runner** container (for reproducible local runs).
- **Three HCP Terraform / Terraform Cloud Agents** (`tfc-agent-1..3`) for running Terraform Cloud workloads inside your private network.
- Optional container/host **metrics** via Prometheus + Grafana (Compose profile `metrics`).

## Key operational points (do not skip)

- You can run **multiple agents**; each agent handles **one run at a time**.  
- Agents are long-running and should be restarted automatically on failure (Compose `restart: unless-stopped` handles this).  
- Auto-update behavior is configurable via `TFC_AGENT_AUTO_UPDATE` (`minor`, `patch`, `disabled`).  
- The only required variable to start an agent is `TFC_AGENT_TOKEN`.  

Authoritative docs:
- Agent overview + Docker usage: https://developer.hashicorp.com/terraform/cloud-docs/agents/agents
- Agents tutorial (includes Docker socket example): https://developer.hashicorp.com/terraform/tutorials/cloud/cloud-agents

## Prerequisites

- Docker + Docker Compose plugin
- HCP Terraform (Terraform Cloud) organization with:
  - An **Agent Pool**
  - Agent **tokens** (one per agent recommended)

## Quick start

### 1) Configure environment

```bash
cp .env.example .env
```

Edit `.env`:
- Set agent names (optional).
- Optionally set `TFE_AGENT_ACCEPT=query` if you need agent “search queries” capability.

### 2) Add secrets (DO NOT COMMIT)

Fill these files:

```bash
printf "%s" "YOUR_CLOUDFLARE_TOKEN" > secrets/cloudflare_api_token.txt

printf "%s" "YOUR_TFC_AGENT_TOKEN_1" > secrets/tfc_agent_token_1.txt
printf "%s" "YOUR_TFC_AGENT_TOKEN_2" > secrets/tfc_agent_token_2.txt
printf "%s" "YOUR_TFC_AGENT_TOKEN_3" > secrets/tfc_agent_token_3.txt
```

### 3) Start agents

```bash
docker compose up -d tfc-agent-1 tfc-agent-2 tfc-agent-3
docker compose logs -f tfc-agent-1
```

Verify registration in the HCP Terraform UI (Organization Settings → Agents).

## Optional: allow agents to manage local Docker (Docker provider)

Only enable this if your Terraform Cloud runs will manage Docker resources on the **same host**.

In `docker-compose.yml`, uncomment:

```yaml
- /var/run/docker.sock:/var/run/docker.sock
```

Security reality: this is effectively host-level access. Treat it as such.

## Local Terraform runner (optional)

This is separate from Terraform Cloud agents.

```bash
docker compose up -d terraform
docker compose exec terraform terraform init
docker compose exec terraform terraform plan
docker compose exec terraform terraform apply
```

Or:

```bash
./scripts/plan.sh
./scripts/apply.sh
./scripts/destroy.sh
```

## Metrics (optional profile)

```bash
docker compose --profile metrics up -d
```

- Prometheus: http://localhost:9090
- Grafana: http://localhost:3001 (credentials from `.env`)

These are **host/container** metrics (node-exporter/cAdvisor). Terraform Cloud agents do not expose first-class Prometheus metrics by default.

## File layout

- `docker-compose.yml` — services, networks, volumes, secrets
- `docker/tfc-agent/agent-entrypoint.sh` — reads token from Docker secret and starts `tfc-agent`
- `terraform/` — Cloudflare sample configuration (local runner)
- `secrets/` — local-only secret files (ignored by Git)
