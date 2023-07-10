
PROJECT_ID:="bug-party-dev"

terraform-init:
	gcloud storage buckets create gs://bug-party-tfstate --project ${PROJECT_ID}
	terraform init

terraform-apply:
	echo "TODO"