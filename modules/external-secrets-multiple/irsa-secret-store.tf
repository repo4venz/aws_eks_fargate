

 
resource "aws_iam_role" "this" {
  count = length(var.aws_sm_secrets)  

  name        = "${local.service_account_name}-${count.index}"
  description = "Permissions required by the Kubernetes Secret Store to do its job."
  path        = null
  tags = var.aws_tags
  force_detach_policies = true
  assume_role_policy = data.aws_iam_policy_document.eks_oidc_assume_role[count.index].json
}


resource "aws_iam_policy" "this" {
  count = length(var.aws_sm_secrets) 

  name        = "${local.service_account_name}-${count.index}"
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
            # It will allow access to a sepecfic secret (defined by user) in the AWS Secrets manager within the region.
            "Resource": "arn:aws:secretsmanager:${local.aws_region_name}:${data.aws_caller_identity.current.account_id}:secret:${var.aws_sm_secrets[count.index].secret_name}*"  
        }
      ]
    })
    tags = {
            Name  = "${var.k8s_cluster_name}-secrets-manager-iam"
            Secrets_Manager_Ref = "${var.aws_sm_secrets[count.index].secret_name}"
        }
  }

resource "aws_iam_role_policy_attachment" "this" {
  count = length(var.aws_sm_secrets) 

  policy_arn = aws_iam_policy.this[count.index].arn
  role       = aws_iam_role.this[count.index].name
}


# Creating service account and attatching role so that External Secret Pod can access AWS Resources

resource "kubernetes_service_account" "this" {
  count = length(var.aws_sm_secrets)  

  automount_service_account_token = true
  metadata {
    name      =  "${local.service_account_name}-${count.index}"
    namespace =   var.aws_sm_secrets[count.index].application_namespace
    annotations = {
      # This annotation is only used when running on EKS which can
      # use IAM roles for service accounts.
      "eks.amazonaws.com/role-arn" = aws_iam_role.this[count.index].arn
    }
    labels = {
      "app.kubernetes.io/name"       = "${local.service_account_name}-${count.index}"
      "app.kubernetes.io/component"  = "secret-store"
      "app.kubernetes.io/managed-by" =  "terraform"  
    }
  }
   depends_on = [ helm_release.external_secrets ]

}

resource "kubernetes_cluster_role" "this" {
  count = length(var.aws_sm_secrets) 

  metadata {
    name = "${local.service_account_name}-${count.index}"

    labels = {
      "app.kubernetes.io/name"       = "${local.service_account_name}-${count.index}"
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
  count = length(var.aws_sm_secrets) 

  metadata {
    name = "${local.service_account_name}-${count.index}"

    labels = {
      "app.kubernetes.io/name"       = "${local.service_account_name}-${count.index}"
      "app.kubernetes.io/component"  = "secret-store"
      "app.kubernetes.io/managed-by" = "terraform" 
    }
  }

  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = kubernetes_cluster_role.this[count.index].metadata[0].name
  }

  subject {
    api_group = ""
    kind      = "ServiceAccount"
    name      = kubernetes_service_account.this[count.index].metadata[0].name
    namespace = kubernetes_service_account.this[count.index].metadata[0].namespace
  }

  depends_on = [ kubernetes_service_account.this , kubernetes_cluster_role.this ]

}

