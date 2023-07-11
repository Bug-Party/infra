1. follow the instructions to get [gcloud cli](./docs/runbooks/gcloud_setup.md) installed

2. run this command to configure kubernetes context
```
gcloud container clusters \
  get-credentials \
  bug-server-dev \
  --zone us-east1-b \
  --project bug-party-dev
```
