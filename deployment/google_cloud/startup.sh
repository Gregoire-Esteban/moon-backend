#!/bin/bash

## This script helps to set the deployment up entirely by :
# 1. Create the Google Cloud projects
# 2. Generate the variable files for the environments 
# 3. Initiate the developement environment & provision it
# 4. Initiate the production environment & provision it
# 5. (optional) Set up periodic state backups 

echo "Hello there !"

# ========== 1. Create the Google Cloud projects ==========
read -r -p "Please enter the development Google Cloud project ID : " dev_project_id
echo "Creating the project MoonDev with ID $dev_project_id"
gcloud projects create $dev_project_id --name="MoonDev"

read -r -p "Please enter the production Google Cloud project ID : " prod_project_id
echo "Creating the project MoonProd with ID $prod_project_id"
gcloud projects create $prod_project_id --name="MoonProd"

if [[ $(echo $REGION) = "" ]]; then read -r -p "The default region is not defined, please enter it here : " REGION; fi

# ========== # 2. Generate the variable files for the environments ==========
echo "Generating the environment variable files..."
mkdir environments

cat > environments/dev.tfvars << EOF
environment = "dev"
project_id = "$dev_project_id"
default_region = "$REGION"
EOF

cat > environments/prod.tfvars << EOF
environment = "prod"
project_id = "$prod_project_id"
default_region = "$REGION"
EOF

#prompt user : do you want to opt-in for the backup process ? (triggers backup/backup_script every day using cron) 


