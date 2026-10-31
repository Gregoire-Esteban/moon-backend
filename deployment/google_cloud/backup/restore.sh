#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")"
source .env

restore_infra() {
    local env_name="$1"
    local tfvars="../environments/${env_name}.tfvars"
    local backup_file="${env_name}_state_backup.json"

    echo "Restoring ${env_name} environment state..."
    gcloud storage cp "gs://${BACKUP_BUCKET_NAME}/${env_name}_state_backup.json" "$backup_file"
    read -rp "Enter the commit short SHA used to tag the image deployed : " tag_short_sha
    images_repository_uri=$(tofu -chdir="../registry" output -raw registry_uri)
    images_repository_id=$(tofu -chdir="../registry" output -raw repository_id)
    tofu -chdir="../infra" init -reconfigure -var-file "$tfvars" -var="image_to_deploy=$images_repository_uri/moon-backend:$tag_short_sha" -var="repository_id=$images_repository_id"
    # Check downloaded backup file to be able to target the infra terraform project
    if [[ $(tofu -chdir="../infra" state pull -var-file "$tfvars" | jq -r .lineage) != $(jq -r .lineage "$backup_file") ]]
    then
        echo "Lineage of backup and current state do not match, aborting."
        exit 1
    fi
    # Apply state restoration
    tofu -chdir="../infra" state push -force -var-file="$tfvars" -var="image_to_deploy=$images_repository_uri/moon-backend:$tag_short_sha" -var="repository_id=$images_repository_id" "../backup/$backup_file"
    # Ensure state has converged
    tofu -chdir="../infra" plan -detailed-exitcode -var-file="$tfvars" -var="image_to_deploy=$images_repository_uri/moon-backend:$tag_short_sha" -var="repository_id=$images_repository_id"
    rm -f "$backup_file"
    echo "${env_name^} environment state restored."
}

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
        if [[ $(tofu -chdir="../registry" state pull -var-file ../environments/dev.tfvars | jq -r .lineage) != $(jq -r .lineage ./registry_state_backup.json) ]]
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
        restore_infra dev
        ;;
    3)
        restore_infra prod
        ;;
    *)
        echo "Invalid choice. Aborting."
        exit 1
        ;;
esac

echo "Restoration completed."
