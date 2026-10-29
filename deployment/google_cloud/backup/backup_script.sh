#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")"
source .env # ensures this script can be run during prepare_backups scripts
echo "Backup initiated"

tofu -chdir="../registry" state pull -var-file="../environments/dev.tfvars" > registry_state_backup.json

tofu -chdir="../infra" init -reconfigure -var-file ../environments/dev.tfvars
tofu -chdir="../infra" state pull -var-file="../environments/dev.tfvars" > dev_state_backup.json

tofu -chdir="../infra" init -reconfigure -var-file ../environments/prod.tfvars
tofu -chdir="../infra" state pull -var-file="../environments/prod.tfvars" > prod_state_backup.json

gcloud storage mv *_state_backup.json "gs://${BACKUP_BUCKET_NAME}" --preserve-posix