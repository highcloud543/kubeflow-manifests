cd kubeflow-manifests/deployments/vanilla/terraform

terraform init
terraform plan -var cluster_name=eks-1 -var cluster_region=us-east-1 -out=plan.binary
