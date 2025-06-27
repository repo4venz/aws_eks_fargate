data "aws_caller_identity" "current" {}


data "aws_region" "current" {
  name = var.aws_region_name
}

data "aws_eks_cluster" "selected" {
  name       = var.k8s_cluster_name
}

# Authentication data for that cluster
data "aws_eks_cluster_auth" "selected" {
  name       = var.k8s_cluster_name
}