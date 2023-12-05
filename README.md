cd kubeflow-manifests/deployments/vanilla/terraform

### Initialize
terraform init

### Genarate Plan
terraform plan -var cluster_name=eks-1 -var cluster_region=us-east-1 -out=plan.binary
