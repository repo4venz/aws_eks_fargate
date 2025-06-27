
resource "aws_iam_role" "this" {
  name        = local.service_account_name
  description = "Permissions required by the Kubernetes Secret Store to do its job."
  path        = null
  tags = var.aws_tags
  force_detach_policies = true
  assume_role_policy = data.aws_iam_policy_document.eks_oidc_assume_role.json
}


resource "aws_iam_policy" "this" {
  name        = local.service_account_name
  description = format("Permissions that are required to retrieve scecrets from AWS Secrets Manager by Kubernetes Secret Store.")
 
    policy = jsonencode({
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "VisualEditor0",
            "Effect": "Allow",
            "Action": [
                "secretsmanager:GetSecretValue",
                "secretsmanager:DescribeSecret"
            ],
            # It will allow access to all the secrets in the AWS Secrets manager within the region.
            "Resource": "arn:aws:secretsmanager:${local.aws_region_name}:${data.aws_caller_identity.current.account_id}:secret:*"   
        }
      ]
    })
    tags = {
            Name  = "${var.k8s_cluster_name}-secrets-manager-iam"
        }
  }

resource "aws_iam_role_policy_attachment" "this" {
  policy_arn = aws_iam_policy.this.arn
  role       = aws_iam_role.this.name
}


# Creating service account and attatching role so that External Secret Pod can access AWS Resources

resource "kubernetes_service_account" "this" {
  automount_service_account_token = true
  metadata {
    name      =  local.service_account_name
    namespace =   var.app_namespace  
    annotations = {
      # This annotation is only used when running on EKS which can
      # use IAM roles for service accounts.
      "eks.amazonaws.com/role-arn" = aws_iam_role.this.arn
      "secretsmanager.amazonaws.com/role-arn" = aws_iam_role.this.arn
    }
    labels = {
      "app.kubernetes.io/name"       = local.service_account_name
      "app.kubernetes.io/component"  = "secret-store"
      "app.kubernetes.io/managed-by" =  "terraform"  
    }
  }
   depends_on = [ helm_release.external_secrets   ]

}

resource "kubernetes_cluster_role" "this" {
  metadata {
    name = local.service_account_name

    labels = {
      "app.kubernetes.io/name"       = local.service_account_name
      "app.kubernetes.io/component"  = "secret-store"
      "app.kubernetes.io/managed-by" = "terraform"  
    }
  }

  rule {
    api_groups = [
      "",
      "extensions"
    ]

    resources = [
      "secrets",
      "configmaps",
      "services"
    ]

    verbs = [
      "create",
      "get",
      "list",
      "update",
      "watch"
    ]
  }

  rule {
    api_groups = [
      "",
      "extensions"
    ]

    resources = [
      "nodes",
      "pods",
      "namespaces"
    ]

    verbs = [
      "get",
      "list",
      "watch"
    ]
  }
}

resource "kubernetes_cluster_role_binding" "this" {
  metadata {
    name = local.service_account_name

    labels = {
      "app.kubernetes.io/name"       = local.service_account_name
      "app.kubernetes.io/component"  = "secret-store"
      "app.kubernetes.io/managed-by" = "terraform" 
    }
  }

  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = kubernetes_cluster_role.this.metadata[0].name
  }

  subject {
    api_group = ""
    kind      = "ServiceAccount"
    name      = kubernetes_service_account.this.metadata[0].name
    namespace = kubernetes_service_account.this.metadata[0].namespace
  }

  depends_on = [  kubernetes_service_account.this , kubernetes_cluster_role.this ]

}

