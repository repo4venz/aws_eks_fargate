
module "vpc" {
    source                              = "./modules/vpc"
    environment                         =  var.environment
    vpc_cidr                            =  var.vpc_cidr
    vpc_name                            =  var.vpc_name
    cluster_name                        =  var.cluster_name
    cluster_group                       =  var.cluster_group
    public_subnets_cidr                 =  var.public_subnets_cidr
    availability_zones_public           =  var.availability_zones_public
    private_subnets_cidr                =  var.private_subnets_cidr
    availability_zones_private          =  var.availability_zones_private
    cidr_block_nat_gw                   =  var.cidr_block_nat_gw
    cidr_block_internet_gw              =  var.cidr_block_internet_gw
}


module kms_aws {
    source                              =  "./modules/kms-aws"
    cluster_name                        =  var.cluster_name
    environment                         =  var.environment

    depends_on = [module.vpc]
}


module "eks" {
    source                                        =  "./modules/eks"
    cluster_name                                  =  var.cluster_name
    cluster_version                               =  var.cluster_version
    environment                                   =  var.environment
    private_subnets                               =  module.vpc.aws_subnets_private
    public_subnets                                =  module.vpc.aws_subnets_public
    fargate_app_namespace                         =  var.fargate_app_namespace
    eks_kms_secret_encryption_key_arn             =  module.kms_aws.eks_kms_secret_encryption_key_arn  # KMS Key ID
    eks_kms_secret_encryption_alias_arn           =  module.kms_aws.eks_kms_secret_encryption_alias_arn  
	  eks_kms_cloudwatch_logs_encryption_key_arn    =  module.kms_aws.eks_kms_cloudwatch_logs_encryption_key_arn # KMS Key ID
    eks_kms_cloudwatch_logs_encryption_alias_arn  =  module.kms_aws.eks_kms_cloudwatch_logs_encryption_alias_arn 

    depends_on = [module.vpc, module.kms_aws]
}



module "fargate_fluentbit" {
  count = var.include_fluentbit_module ? 1 : 0
  source        = "./modules/fargate-fluentbit"
  addon_config  = var.fargate_fluentbit_addon_config
  addon_context = local.addon_context

  depends_on =  [module.eks ]
}

module "coredns_patching" {
  count = var.include_coredns_patching_module ? 1 : 0
  source  = "./modules/coredns-patch"

  k8s_namespace    = "kube-system"
  k8s_cluster_name = module.eks.eks_cluster_name
  user_profile =   var.user_profile
  user_os = var.user_os

  depends_on = [module.eks, module.fargate_fluentbit]
}



module "aws_alb_controller" {
  count = var.include_alb_controller_module ? 1 : 0
  source  = "./modules/aws-lb-controller"
  k8s_namespace    = "kube-system"
  k8s_cluster_name = module.eks.eks_cluster_name

  depends_on = [module.eks, module.coredns_patching]
}

module "eks_kubernetes_addons" {
  count = var.include_kubernetes_addons_module ? 1 : 0
  source         = "./modules/kubernetes-addons"
  enable_amazon_eks_vpc_cni    = true
  k8s_namespace    = "kube-system"
  k8s_cluster_name = module.eks.eks_cluster_name

  depends_on = [module.eks, module.coredns_patching]
}



module "aws_appmesh_controller" {
  count = var.include_appmesh_controller_module ? 1 : 0
  source  = "./modules/aws-appmesh-controller"
  k8s_namespace    = "appmesh-system"
  k8s_cluster_name = module.eks.eks_cluster_name

  depends_on =  [module.eks]  
}

 module "metrics_server" {
  count = var.include_metrics_server_module ? 1 : 0
 
  source  = "./modules/metrics-server"

  depends_on = [module.eks]
}


############## Creating Application Namespace(s) ad per the User input ##############
resource "kubernetes_namespace"  "application_namespace" {
    for_each =  toset(var.fargate_app_namespace)    
    metadata {
    labels = {
      "app.kubernetes.io/component"  = "business_application"
      "app.kubernetes.io/managed-by" = "terraform" 
    }
    name = each.value
  }
  depends_on = [module.eks]
}
 

module "external_secrets" {
  count = var.include_external_secrets_module ? 1 : 0
  source  = "./modules/external-secrets"
  k8s_namespace    =  "external-secrets"
  app_namespace  =  var.fargate_app_namespace[0]
  k8s_cluster_name = module.eks.eks_cluster_name

  depends_on =  [ kubernetes_namespace.application_namespace]  
}

 module "external_secrets_multiple" {
  count = var.include_external_secrets_multiple_module ? 1 : 0
 
  source  = "./modules/external-secrets-multiple"
  k8s_namespace    =  "external-secrets"
  aws_sm_secrets   =  var.aws_sm_secrets
  k8s_cluster_name =  module.eks.eks_cluster_name


  depends_on =  [ kubernetes_namespace.application_namespace]  
}


module "external-dns" {
  count = var.include_external_dns_module ? 1 : 0
  source  = "./modules/external-dns"
  k8s_namespace    = "kube-system"
  k8s_cluster_name = module.eks.eks_cluster_name

  depends_on =  [module.eks, module.coredns_patching]  
}




module "kubernetes_app_helm" {
    count = var.include_k8s_app_helm_module ? 1 : 0
    source                      =  "./modules/kubernetes-app-helm"
    app_namespace               =  var.fargate_app_namespace[0]

  depends_on = [module.eks, module.aws_alb_controller, kubernetes_namespace.application_namespace]
}
 

module "kubernetes_app" {
    count = var.include_k8s_app_module ? 1 : 0
    source                      =  "./modules/kubernetes-app"
    app_namespace               =  var.fargate_app_namespace[0]

  depends_on = [module.eks, module.aws_alb_controller, kubernetes_namespace.application_namespace]
}

 