#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")"

# Necessary default region
if [[ $(echo $REGION) = "" ]]; then read -rp "The default region is not defined, please enter it here : " REGION; fi

# Ask for bucket name and attempt to create it
BUCKET_CREATED=false
while [ "$BUCKET_CREATED" = false ]; do
    read -rp "Enter a name for the backup bucket: " BUCKET_NAME
    if gcloud storage buckets create "gs://${BUCKET_NAME}" --location="$REGION" --project="$(gcloud config get project)" --uniform-bucket-level-access --pap; then
        BUCKET_CREATED=true
    else
        echo "Bucket creation failed (the name may already be taken). Please try another name."
    fi
done

# Save bucket name into .env file
echo "BACKUP_BUCKET_NAME=${BUCKET_NAME}" > .env

# Execute a first save
chmod +x ./backup_script.sh
./backup_script.sh

# Add backup_script to crontab, daily execution at 5 a.m.
(crontab -l 2>/dev/null || true; echo "0 5 * * * $(pwd)/backup_script.sh >> /var/log/moon-backup.log 2>&1") | crontab -