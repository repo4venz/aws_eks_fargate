
variable "k8s_cluster_name" {
  description = "Name of the Kubernetes cluster. This string is used to contruct the AWS IAM permissions and roles. If targeting EKS, the corresponsing managed cluster name must match as well."
  type        = string
}

variable "k8s_namespace" {
  description = "Kubernetes namespace to deploy the AWS Load Balancer Controller into."
  type        = string
  default     = "default"
}

 variable "aws_tags" {
  description = "Common AWS tags to be applied to all AWS objects being created."
  type        = map(string)
  default     = {}
}

variable "appmesh_controller_chart_version" {
  description = "The AWS AppMesh Controller version to use. See https://github.com/aws/eks-charts/releases/ and https://github.com/aws/aws-app-mesh-controller-for-k8s/releases for available versions"
  type        = string
  default     = "1.5.0"
}
 
variable "chart_env_overrides" {
  description = "env values passed to the load balancer controller helm chart."
  type        = map(any)
  default     = {}
}

variable "service_account_name" {
  description = "Service Account Name of the AWS AppMesh Controller"
  type        = string
  default     = "appmesh-controller"
}

