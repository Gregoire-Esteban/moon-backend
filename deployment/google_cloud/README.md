## Google Cloud Deployment

Rely on Google Cloud resources to deploy the moon app.

*STATUS*: ⚠️ STILL IN DEVELOPMENT

### Prerequisites

1. Setup The [Google Cloud CLI](https://docs.cloud.google.com/sdk/gcloud) (don't forget to run `gcloud init` & `gcloud auth application-default login` for the authentication steps)
2. Execute the *startup.sh* script
3. (optional) Create a bucket to hold the state backups : `gcloud storage buckets create gs://unique-named-bucket --location="EU" --project="targeted-project-id"`


> ***NOTE***: You can also update the environment variable set in this folder's *mise.toml* file or provide and configure the CLI as you see fit.

### Cleanup ( ⚠️ Destroys everything related to the deployment ! )

Simply execute the *annihilate.sh* script