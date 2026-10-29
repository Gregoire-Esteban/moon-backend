#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")"

# ========== 0. Prompt user for confirmation with an uppercase warning ==========

echo "=========================================="
echo "  WARNING: THIS WILL DESTROY EVERYTHING"
echo "=========================================="
echo ""
echo "This script will:"
echo "  - Delete both GCP projects (dev & prod)"
echo "  - Remove all Terraform state files and .terraform folders"
echo "  - Delete the environments folder"
echo "  - Remove the local moon-backend Docker image"
echo "  - Remove the backup crontab entry"
echo "  - Delete log files"
echo ""
read -rp "Are you absolutely sure? Type 'ANNIHILATE' to confirm: " confirmation
if [[ "$confirmation" != "ANNIHILATE" ]]; then
    echo "Aborted. Nothing was destroyed."
    exit 1
fi

# ========== 1. Extract prod & dev projects ids from individual tfvars files in environments ==========

dev_project_id=$(grep '^project_id' environments/dev.tfvars | cut -d'"' -f2)
prod_project_id=$(grep '^project_id' environments/prod.tfvars | cut -d'"' -f2)
echo "Dev project:  $dev_project_id"
echo "Prod project: $prod_project_id"

# ========== 2. Use these vars to delete the projects (gcloud project delete $dev_project_id -q) ==========

echo "Deleting dev project $dev_project_id..."
gcloud projects delete "$dev_project_id" --quiet

echo "Deleting prod project $prod_project_id..."
gcloud projects delete "$prod_project_id" --quiet

# ========== 3. Cleanup state files and .terraform folders in infra and registry folders ==========

echo "Cleaning up Terraform state files and .terraform folders..."
rm -f infra/terraform.tfstate infra/terraform.tfstate.backup
rm -rf infra/.terraform
rm -rf infra/states
rm -f registry/terraform.tfstate registry/terraform.tfstate.backup
rm -rf registry/.terraform

# ========== 4. Delete environments folder ==========

echo "Deleting environments folder..."
rm -rf environments

# ========== 5. Delete moon-backend image ==========

echo "Deleting local moon-backend Docker image..."
docker rmi -f $(docker images -q moon-backend) 2>/dev/null || true

# ========== 6. Remove backup crontab entry ==========

echo "Removing backup crontab entry..."
(crontab -l 2>/dev/null || true) | grep -v "backup_script.sh >> /var/log/moon-backup.log" | crontab -

# ========== 7. Delete log files ==========
echo "Deleting log files..."
rm -f /var/log/moon-backup.log

echo "Annihilation completed"
