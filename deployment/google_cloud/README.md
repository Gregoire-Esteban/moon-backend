## Google Cloud Deployment

Rely on Google Cloud resources to deploy the moon app.

*STATUS*: ⚠️ STILL IN DEVELOPMENT

### Prerequisites

#### Main deployments
1. Setup The [Google Cloud CLI](https://docs.cloud.google.com/sdk/gcloud) (don't forget to run `gcloud init` & `gcloud auth application-default login` for the authentication steps)
2. Execute the *startup.sh* script

> ***NOTE***: You can also update the environment variable set in this folder's *mise.toml* file or provide and configure the CLI as you see fit.

#### Backups (optional)
Execute *backup/prepare_backups.sh* script. It will help you create a **bucket** and schedule recurring backups using **cron**.

The restoration script is *backup/restore.sh*.

### Cleanup ( ⚠️ Destroys everything related to the deployment ! )

Simply execute the *annihilate.sh* script.