
PROJECT_ID:="bug-party-dev"

TF_COMMAND := docker run -i -t -v $(shell pwd)/terraform/:/workspace \
  -w /workspace -v ~/.config/gcloud:/root/.config/gcloud \
  -e TF_VAR_project="$PROJECT_ID" \
  hashicorp/terraform:1.5.0

.PHONY: install-argocd
install-argocd:
	helm repo add argo https://argoproj.github.io/argo-helm
	helm upgrade --install -n argocd argocd argo/argo-cd --version 5.38.1

.PHONY: bootstrap-argocd
bootstrap-argocd:
	kubectl apply -f k8s/bootstrap/argo-bootstrap.yaml

.PHONY: terraform-create-backend
terraform-create-backend:
	gcloud storage buckets create gs://bug-party-tfstate --project ${PROJECT_ID}

.PHONY: terraform-init
terraform-init:
	$(TF_COMMAND) init

.PHONY: terraform-apply
terraform-apply:
	$(TF_COMMAND) apply

.PHONY: terraform-output
terraform-output:
	$(TF_COMMAND) output