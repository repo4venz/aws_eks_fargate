
variable "k8s_cluster_name" {
  description = "Name of the Kubernetes cluster. This string is used to contruct the AWS IAM permissions and roles. If targeting EKS, the corresponsing managed cluster name must match as well."
  type        = string
}

variable "k8s_namespace" {
  description = "Kubernetes namespace to deploy the AWS Load Balancer Controller into."
  type        = string
  default     = "default"
}

variable "aws_vpc_id" {
  description = "ID of the Virtual Private Network to utilize. Can be ommited if targeting EKS."
  type        = string
  default     = null
}

variable "aws_region_name" {
  description = "ID of the AWS Region to utilize. Can be ommited if targeting EKS."
  type        = string
  default     = null
}

variable "aws_tags" {
  description = "Common AWS tags to be applied to all AWS objects being created."
  type        = map(string)
  default     = {}
}

variable "external_dns_chart_version" {
  description = "The ExternalDNS version to use. See https://kubernetes-sigs.github.io/external-dns/ and github.com/kubernetes-sigs/external-dns/releases for available versions of external-dns-helm-chart"
  type        = string
  default     = "1.10.1"
}

 
variable "chart_env_overrides" {
  description = "env values passed to the ExternalDNS helm chart."
  type        = map(any)
  default     = {}
}

variable "service_account_name" {
  description = "Service Account Name of the ExternalDNS"
  type        = string
  default     = "external-dns"
}

