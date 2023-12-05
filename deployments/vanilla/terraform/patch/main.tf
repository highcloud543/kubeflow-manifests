resource "null_resource" "service_istio_system_istio_ingressgateway" {
  provisioner "local-exec" {
    interpreter = ["/bin/bash", "-c"]
    environment = {
      KUBECONFIG = "/root/.kube/config"
    }
    command = <<EOT
      kubectl -n istio-system patch service istio-ingressgateway -p '{"spec":{"type":"LoadBalancer"}}'
    EOT
  }
}

resource "null_resource" "wait_for_istio_ingress_lb" {
  provisioner "local-exec" {
    interpreter = ["/bin/bash", "-c"]
    environment = {
      KUBECONFIG = "/root/.kube/config"
    }
    command = <<EOT
      kubectl -n istio-system wait --for=jsonpath='{.status.loadBalancer.ingress[0].hostname}' service/istio-ingressgateway --timeout=300s
    EOT
  }
  depends_on = [null_resource.service_istio_system_istio_ingressgateway]
}

data "kubernetes_resource" "istio_ingress_lb" {
  api_version = "v1"
  kind        = "Service"

  metadata {
    name = "istio-ingressgateway"
    namespace = "istio-system"
  }

  depends_on = [null_resource.wait_for_istio_ingress_lb]
}
resource "null_resource" "certificate_istio_system_kubeflow_ingressgateway_certs" {
  provisioner "local-exec" {
    interpreter = ["/bin/bash", "-c"]
    environment = {
      KUBECONFIG = "/root/.kube/config"
    }
    command = <<EOT
cat <<EOM | kubectl apply -f -
apiVersion: cert-manager.io/v1
kind: Certificate
metadata:
  creationTimestamp: "2023-09-04T14:59:09Z"
  generation: 1
  name: kubeflow-ingressgateway-certs
  namespace: istio-system
spec:
  commonName: istio-ingressgateway.istio-system.svc
  issuerRef:
    kind: ClusterIssuer
    name: kubeflow-self-signing-issuer
  secretName: kubeflow-ingressgateway-certs
EOM
    EOT
  }
}
#resource "kubernetes_manifest" "certificate_istio_system_kubeflow_ingressgateway_certs" {
#  manifest = {
#    "apiVersion" = "cert-manager.io/v1"
#    "kind" = "Certificate"
#    "metadata" = {
#      "name" = "kubeflow-ingressgateway-certs"
#      "namespace" = "istio-system"
#    }
#    "spec" = {
#      "commonName" = "istio-ingressgateway.istio-system.svc"
#      "issuerRef" = {
#        "kind" = "ClusterIssuer"
#        "name" = "kubeflow-self-signing-issuer"
#      }
#      "secretName" = "kubeflow-ingressgateway-certs"
#    }
#  }
#}

resource "null_resource" "gateway_kubeflow_kubeflow_gateway" {
  provisioner "local-exec" {
    interpreter = ["/bin/bash", "-c"]
    environment = {
      KUBECONFIG = "/root/.kube/config"
    }
    command = <<EOT
      kubectl -n kubeflow patch gateway kubeflow-gateway --type=merge -p '{"spec":{"selector":{"istio":"ingressgateway"},"servers":[{"hosts":["*"],"port":{"name":"http","number":80,"protocol":"HTTP"},"tls":{"httpsRedirect":true}},{"hosts":["*"],"port":{"name":"https","number":443,"protocol":"HTTPS"},"tls":{"credentialName":"kubeflow-ingressgateway-certs","mode":"SIMPLE"}}]}}'
    EOT
  }
  depends_on = [resource.null_resource.certificate_istio_system_kubeflow_ingressgateway_certs]
}
