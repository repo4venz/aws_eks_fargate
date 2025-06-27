locals {
  aws_region_name              = data.aws_region.current.name
  service_account_name         = "aws-node"
}


resource "aws_iam_role" "vpc-cni-role" {
  name        = substr("${var.k8s_cluster_name}-vpc-cni-addon-role", 0, 64)
  description = "Permissions required by the Kubernetes VPC CNI controller to do its job."
  force_detach_policies = true 
  assume_role_policy =  data.aws_iam_policy_document.eks_oidc_assume_role.json
}

resource "aws_iam_role_policy_attachment" "vpc-cni-addon" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       =  aws_iam_role.vpc-cni-role.name
}



resource "aws_eks_addon" "vpc_cni" {
  cluster_name             = var.k8s_cluster_name
  addon_name               = "vpc-cni"
  addon_version            = "v1.11.2-eksbuild.1"
  resolve_conflicts        = "OVERWRITE"
  service_account_role_arn = aws_iam_role.vpc-cni-role.arn
  preserve                 = true
 depends_on = [aws_iam_role.vpc-cni-role]
}


