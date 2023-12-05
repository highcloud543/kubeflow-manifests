module "patch" {
  source = "./patch"
  depends_on = [module.kubeflow_components]
}
