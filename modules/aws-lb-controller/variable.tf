 

variable "k8s_cluster_name" {
  description = "Name of the Kubernetes cluster. This string is used to contruct the AWS IAM permissions and roles. If targeting EKS, the corresponsing managed cluster name must match as well."
  type        = string
}

variable "k8s_namespace" {
  description = "Kubernetes namespace to deploy the AWS Load Balancer Controller into."
  type        = string
  default     = "kube-system"
}

variable "k8s_replicas" {
  description = "Number of replicas to be created."
  type        = number
  default     = 1
}


variable "k8s_pod_annotations" {
  description = "Additional annotations to be added to the Pods."
  type        = map(string)
  default     = {}
}

variable "k8s_pod_labels" {
  description = "Additional labels to be added to the Pods."
  type        = map(string)
  default     = {}
}

variable "aws_iam_path_prefix" {
  description = "Prefix to be used for all AWS IAM objects."
  type        = string
  default     = ""
}

variable "aws_vpc_id" {
  description = "ID of the Virtual Private Network to utilize. Can be ommited if targeting EKS."
  type        = string
  default     = null
}

variable "aws_region_name" {
  description = "ID of the Virtual Private Network to utilize. Can be ommited if targeting EKS."
  type        = string
  default     = null
}

variable "aws_resource_name_prefix" {
  description = "A string to prefix any AWS resources created. This does not apply to K8s resources"
  type        = string
  default     = "k8s-"
}

variable "aws_tags" {
  description = "Common AWS tags to be applied to all AWS objects being created."
  type        = map(string)
  default     = {}
}

variable "aws_load_balancer_controller_chart_version" {
  description = "The AWS Load Balancer Controller version to use. See https://github.com/aws/eks-charts/releases/ and https://github.com/kubernetes-sigs/aws-load-balancer-controller/releases for available versions"
  type        = string
  default     = "1.4.2"
}

variable "target_groups" {
  description = "Group Binding details for TargetGroupBindings. Expected object fields: name, backend_port, target_group_arn, target_type See https://kubernetes-sigs.github.io/aws-load-balancer-controller/v2.1/guide/targetgroupbinding/targetgroupbinding/ for details."
  type        = any
  default     = []
}

variable "enable_host_networking" {
  description = "If true enable host networking. See https://github.com/aws/eks-charts/tree/master/stable/aws-load-balancer-controller#configuration for details."
  type        = bool
  default     = false
}


variable "service_account_name" {
  description = "Service Account Name of the AWS Load Balancer Controller"
  type        = string
  default     = "aws-load-balancer-controller"
}

