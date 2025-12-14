#!/usr/bin/env bash
set -euo pipefail
docker compose exec terraform terraform init -upgrade
docker compose exec terraform terraform plan
