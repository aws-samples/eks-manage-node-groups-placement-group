################################################################################
# Cluster
################################################################################

variable "cluster_version" {
  description = "Kubernetes `<major>.<minor>` version to use for the EKS cluster (i.e.: `1.28`)"
  type        = string
  default     = "1.28"
}

variable "instance_type" {
  description = "Instance type for EC2 node"
  type        = string
  default     = "c5.large"
}
