#!/usr/bin/env bash

## This script helps to set the deployment up entirely by :
# 0. Build the image and check for known vulnerabilities
# 1. Create the Google Cloud projects
# 2. Generate the variable files for the environments 
# 3. Create the registry in the dev project
# 4. Build and push a first image to it
# 5. Initiate the developement environment & provision it
# 6. Initiate the production environment & provision it
# 7. (optional) Set up periodic state backups 

set -euo pipefail

echo "Hello there !"

# ========== 0. Build the image and check for known vulnerabilities ==========

echo "Let me check if the image is in good shape to be launched"
cd ../../
cat standalone.Dockerfile | docker build --network=host -t moon-backend -f- .
grype moon-backend --from docker --fail-on critical
echo "Image check passed"
cd deployment/google_cloud

# ========== 1. Create the Google Cloud projects ==========

read -rp "Please enter the development Google Cloud project ID : " dev_project_id
echo "Creating the project MoonDev with ID $dev_project_id"
gcloud projects create $dev_project_id --name="MoonDev"

read -rp "Please enter the production Google Cloud project ID : " prod_project_id
echo "Creating the project MoonProd with ID $prod_project_id"
gcloud projects create $prod_project_id --name="MoonProd"

# Display current Google Cloud billing accounts and ask which one to use
mapfile -t rows < <(gcloud billing accounts list)
header="${rows[0]}"
echo "# $header"
for i in "${!rows[@]}"; do
    (( i > 0)) && echo "$i ${rows[$i]}"
done

while true; do
    read -rp "Choose the billing account you'd like to use in the MoonDev & MoonProd projects [1-$((${#rows[@]}-1))]: " choice
    [[ "$choice" =~ ^[0-9]+$ ]] && (( choice >= 1 && choice <= ${#rows[@]}-1 )) && break
    echo "Invalid number, try again." >&2
done

selected_billing_account_id=$(echo "${rows[$((choice))]}" | awk '{print $1}')

gcloud billing projects link $dev_project_id --billing-account="$selected_billing_account_id"
gcloud billing projects link $prod_project_id --billing-account="$selected_billing_account_id"

# ========== # 2. Generate the variable files for the environments ==========

if [[ $(echo $REGION) = "" ]]; then read -rp "The default region is not defined, please enter it here : " REGION; fi

echo "Generating the environment variable files..."
current_gcloud_account=$(gcloud config get account)
mkdir environments || true # tolerate an existing folder (generated files inside will be overwritten)

cat > environments/dev.tfvars << EOF
environment = "dev"
project_id = "$dev_project_id"
default_region = "$REGION"
moon_service_members = ["user:$current_gcloud_account"]
EOF

cat > environments/prod.tfvars << EOF
environment = "prod"
project_id = "$prod_project_id"
default_region = "$REGION"
moon_service_members = ["allUsers"]
EOF

# ========== # 3. Create the registry in the dev project ==========

echo "Creating the registry..."
cd registry
tofu init -var-file ../environments/dev.tfvars
tofu apply -var-file ../environments/dev.tfvars
images_repository_uri=$(tofu output -raw registry_uri)
images_repository_id=$(tofu output -raw repository_id)

# ========== # 4. Build and push a first image to it ==========

echo "Build and push a first image to the repository..."
gcloud auth configure-docker $REGION-docker.pkg.dev
moon_backend_version=$(uv version --short)
last_commit_sha=$(git rev-parse --short HEAD)
docker tag "moon-backend" "$images_repository_uri/moon-backend:$moon_backend_version"
docker tag "moon-backend" "$images_repository_uri/moon-backend:$last_commit_sha"
docker push "$images_repository_uri/moon-backend" --all-tags

# ========== 5. Initiate the developement environment & provision it ==========

cd ../infra
echo "Preparing the development environment..."
tofu init -var-file ../environments/dev.tfvars -var="image_to_deploy=$images_repository_uri/moon-backend:$last_commit_sha" -var="repository_id=$images_repository_id"
tofu apply -var-file ../environments/dev.tfvars -var="image_to_deploy=$images_repository_uri/moon-backend:$last_commit_sha" -var="repository_id=$images_repository_id"
echo "You can now test the service at $(tofu output -raw service_url) (the google cloud run proxy is recommended)"

# ========== 6. Initiate the production environment & provision it ==========

echo "Preparing the production environment..."
tofu init -reconfigure -var-file ../environments/prod.tfvars -var="image_to_deploy=$images_repository_uri/moon-backend:$last_commit_sha" -var="repository_id=$images_repository_id"
tofu apply -var-file ../environments/prod.tfvars -var="image_to_deploy=$images_repository_uri/moon-backend:$last_commit_sha" -var="repository_id=$images_repository_id"
echo "The service is now publicly available at $(tofu output -raw service_url)"

# prompt user : do you want to opt-in for the backup process ? (triggers backup/backup_script every day using cron)
