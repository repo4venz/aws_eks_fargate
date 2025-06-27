locals {
  appmesh_controller_helm_repo     = "https://aws.github.io/eks-charts"
  appmesh_controller_chart_name    = "appmesh-controller"
  appmesh_controller_chart_version = var.appmesh_controller_chart_version
  service_account_name         = substr("${var.k8s_cluster_name}-appmesh-controller",0,64)
}

 
resource "aws_iam_role" "this" {
  name        = local.service_account_name
  description = "Permissions required by the Kubernetes AWS Appmesh controller to do its job."
  path        = null
  tags = var.aws_tags
  force_detach_policies = true
  assume_role_policy = data.aws_iam_policy_document.eks_oidc_assume_role.json
}


resource "aws_iam_policy" "this" {
  name        = local.service_account_name
  description = format("Permissions that are required to manage AWS Appmesh.")
  path        = "/"
  # We use a heredoc for the policy JSON so that we can more easily diff and
  # copy/paste from upstream. Ignore whitespace when you diff to more easily see the changes!
  # Source: `curl -o controller-iam-policy.json https://raw.githubusercontent.com/aws/aws-app-mesh-controller-for-k8s/master/config/iam/controller-iam-policy.json`
  policy = file("${path.module}/aws_appmesh_iam_policy.json")
        tags = {
                 Name = "${var.k8s_cluster_name}-appmesh-controller-iam"
                }
  }

resource "aws_iam_role_policy_attachment" "this" {
  policy_arn = aws_iam_policy.this.arn
  role       = aws_iam_role.this.name
}

resource "aws_iam_role_policy_attachment" "this1" {
  policy_arn = "arn:aws:iam::aws:policy/AWSCloudMapFullAccess"
  role       = aws_iam_role.this.name
}

resource "aws_iam_role_policy_attachment" "this2" {
  policy_arn = "arn:aws:iam::aws:policy/AWSAppMeshFullAccess"
  role       = aws_iam_role.this.name
}
 
resource "helm_release" "appmesh-controller" {

  name       = "appmesh-controller"
  repository = local.appmesh_controller_helm_repo
  chart      = local.appmesh_controller_chart_name
  version    = local.appmesh_controller_chart_version
  namespace  = var.k8s_namespace
  create_namespace = true
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

  depends_on = [aws_iam_role.this]  
}


