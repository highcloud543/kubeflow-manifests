output "loadbalancer" {
  #value = resource.kubernetes_service.service_istio_system_istio_ingressgateway.status.0.load_balancer.0.ingress.0.hostname
  value = data.kubernetes_resource.istio_ingress_lb.object.status.loadBalancer.ingress[0].hostname
}
