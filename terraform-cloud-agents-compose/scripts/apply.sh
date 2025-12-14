#!/usr/bin/env bash
set -euo pipefail
docker compose exec terraform terraform apply -auto-approve
