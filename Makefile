
PROJECT_ID:="bug-party-dev"

TF_COMMAND := docker run -i -t -v $(shell pwd)/terraform/:/workspace \
  -w /workspace -v ~/.config/gcloud:/root/.config/gcloud \
  -e TF_VAR_project="$PROJECT_ID" \
  hashicorp/terraform:1.5.0

.PHONY: install-argocd
install-argocd:
	helm repo add argo https://argoproj.github.io/argo-helm
	helm upgrade --install -n argocd argocd argo/argo-cd --version 5.38.1

.PHONY: rebuild-dashboards
rebuild-dashboards:
	rm -r ./k8s/apps/grafana/dashboards/generated/
	mkdir -p ./k8s/apps/grafana/dashboards/generated/
	kustomize build ./k8s/apps/grafana/dashboards/ --output ./k8s/apps/grafana/dashboards/generated/dashboards.yaml

.PHONY: bootstrap-argocd
bootstrap-argocd: rebuild-dashboards
	kubectl apply -f k8s/argo

.PHONY: uninstall-argocd
uninstall-argocd:
	helm uninstall -n argocd argocd

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

.PHONY: get-grafana-password
get-grafana-creds:
	echo username:
	kubectl get secret --namespace observability grafana -o jsonpath="{.data.admin-user}" | base64 --decode ; echo
	echo password:
	kubectl get secret --namespace observability grafana -o jsonpath="{.data.admin-password}" | base64 --decode ; echo


.PHONY: get-argocd-creds
get-argocd-creds:
	argocd -n argocd admin initial-password

.PHONY: port-fwd-argo
port-fwd-argo: get-argocd-creds
	kubectl -n argocd port-forward service/argocd-server 18080:80