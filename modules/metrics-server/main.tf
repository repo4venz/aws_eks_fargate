locals {
  metrics_server_helm_repo     = "https://kubernetes-sigs.github.io/metrics-server/"
  metrics_server_chart_name    = "metrics-server"
}
 
  
resource "helm_release" "metrics-server" {

  name       = "external-dns"
  repository = local.metrics_server_helm_repo
  chart      = local.metrics_server_chart_name
  create_namespace = false
  atomic     = true
  timeout    = 900
  cleanup_on_fail = true

}


