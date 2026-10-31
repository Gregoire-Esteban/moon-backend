#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")"
source .env

echo "=========================================="
echo "  STATE RESTORATION"
echo "=========================================="
echo ""
echo "Which state would you like to restore?"
echo "  1) Registry"
echo "  2) Dev environment"
echo "  3) Prod environment"
echo ""
read -rp "Enter your choice (1-3): " choice

case "$choice" in
    1)
        echo "Restoring registry state..."
        gcloud storage cp "gs://${BACKUP_BUCKET_NAME}/registry_state_backup.json" ./registry_state_backup.json
        tofu -chdir="../registry" init -var-file ../environments/dev.tfvars
        # Check downloaded backup file to be able to target the registry terraform project
        if [[ $(tofu -chdir="../registry" state pull -var-file ../environments/dev.tfvars | jq -r .lineage) != $(jq -r .lineage ../backup/dev_state_backup.json) ]]
        then
            echo "Lineage of backup and current state do not match, aborting."
            exit 1
        fi
        # Apply registry state restoration
        tofu -chdir="../registry" state push -force ../registry_state_backup.json -var-file ../environments/dev.tfvars
        # Ensure state has converged
        tofu -chdir="../registry" plan -detailed-exitcode -var-file="../environments/dev.tfvars"
        rm -f ./registry_state_backup.json
        echo "Registry state restored."
        ;;
    2)
        echo "Restoring dev environment state..."
        gcloud storage cp "gs://${BACKUP_BUCKET_NAME}/dev_state_backup.json" ./dev_state_backup.json 
        read -rp "Enter the commit short SHA used to tag the image deployed : " tag_short_sha
        images_repository_uri=$(tofu -chdir="../registry" output -raw registry_uri)
        images_repository_id=$(tofu -chdir="../registry" output -raw repository_id)
        tofu -chdir="../infra" init -reconfigure -var-file ../environments/dev.tfvars -var="image_to_deploy=$images_repository_uri/moon-backend:$tag_short_sha" -var="repository_id=$images_repository_id"
        # Check downloaded backup file to be able to target the registry terraform project
        if [[ $(tofu -chdir="../infra" state pull -var-file ../environments/dev.tfvars | jq -r .lineage) != $(jq -r .lineage ./dev_state_backup.json) ]]
        then
            echo "Lineage of backup and current state do not match, aborting."
            exit 1
        fi
        # Apply dev env state restoration
        tofu -chdir="../infra" state push -force -var-file="../environments/dev.tfvars" -var="image_to_deploy=$images_repository_uri/moon-backend:$tag_short_sha" -var="repository_id=$images_repository_id" ../backup/dev_state_backup.json
        # Ensure state has converged
        tofu -chdir="../infra" plan -detailed-exitcode -var-file="../environments/dev.tfvars" -var="image_to_deploy=$images_repository_uri/moon-backend:$tag_short_sha" -var="repository_id=$images_repository_id"
        rm -f ./dev_state_backup.json
        echo "Dev environment state restored."
        ;;
    3)
        echo "Restoring prod environment state..."
        gcloud storage cp "gs://${BACKUP_BUCKET_NAME}/prod_state_backup.json" ./prod_state_backup.json
        read -rp "Enter the commit short SHA used to tag the image deployed : " tag_short_sha
        images_repository_uri=$(tofu -chdir="../registry" output -raw registry_uri)
        images_repository_id=$(tofu -chdir="../registry" output -raw repository_id)
        tofu -chdir="../infra" init -reconfigure -var-file ../environments/prod.tfvars
        # Check downloaded backup file to be able to target the registry terraform project
        if [[ $(tofu -chdir="../infra" state pull -var-file ../environments/prod.tfvars | jq -r .lineage) != $(jq -r .lineage ./prod_state_backup.json) ]]
        then
            echo "Lineage of backup and current state do not match, aborting."
            exit 1
        fi
        # Apply prod env state restoration
        tofu -chdir="../infra" state push -var-file="../environments/prod.tfvars" -var="image_to_deploy=$images_repository_uri/moon-backend:$tag_short_sha" -var="repository_id=$images_repository_id" ../prod_state_backup.json
        # Ensure state has converged
        tofu -chdir="../infra" plan -detailed-exitcode -var-file="../environments/prod.tfvars" -var="image_to_deploy=$images_repository_uri/moon-backend:$tag_short_sha" -var="repository_id=$images_repository_id"
        rm -f ./prod_state_backup.json
        echo "Prod environment state restored."
        ;;
    *)
        echo "Invalid choice. Aborting."
        exit 1
        ;;
esac

echo "Restoration completed."
