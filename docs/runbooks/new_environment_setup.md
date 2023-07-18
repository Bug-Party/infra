To set up a brand new environment in an otherwise empty gcp project ... 

1. run the following commands
```
make terraform-create-backend terraform-init terraform-apply
```

2. install argocd:
```
make install-argocd
```

3. sync argo deployments for istio
```
TODO -- add the commands to do this
```
