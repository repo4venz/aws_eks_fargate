locals {
  external_dns_helm_repo     = "https://kubernetes-sigs.github.io/external-dns/"
  external_dns_chart_name    = "external-dns"
  external_dns_chart_version = var.external_dns_chart_version
  service_account_name         = substr("${var.k8s_cluster_name}-external-dns",0,64)
}
 

resource "aws_iam_role" "this" {
  name        = local.service_account_name
  description = "Permissions required by the Kubernetes External DNS to do its job."
  path        = null
  tags = var.aws_tags
  force_detach_policies = true
  assume_role_policy = data.aws_iam_policy_document.eks_oidc_assume_role.json
}


resource "aws_iam_policy" "this" {
  name        = local.service_account_name
  description = format("Permissions that are required to manage AWS Route53.")
  path        = "/"
  policy = file("${path.module}/external_dns_iam_policy.json")
        tags = {
                 Name        = "${var.k8s_cluster_name}-external-dns-iam"
                }
  }

resource "aws_iam_role_policy_attachment" "this" {
  policy_arn = aws_iam_policy.this.arn
  role       = aws_iam_role.this.name
}

 
resource "helm_release" "external-dns" {

  name       = "external-dns"
  repository = local.external_dns_helm_repo
  chart      = local.external_dns_chart_name
  version    = local.external_dns_chart_version
  namespace  = var.k8s_namespace
  create_namespace = false
  atomic     = true
  timeout    = 900
  cleanup_on_fail = true

 
  set {
      name = "serviceAccount.create"
      value = "true"
      type = "auto"
  }
  set {
      name = "serviceAccount.name"
      value = local.service_account_name
      type = "string"
  }
  set {
      name = "serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"
      value = "${aws_iam_role.this.arn}"
      type = "string"
  }
  set {
      name = "rbac.create"
      value = "true"
      type = "auto"
  }
  set {
      name = "policy"
      value = "sync"
      type = "string"
  }
  depends_on = [aws_iam_role.this]  
}


