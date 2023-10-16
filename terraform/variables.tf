################################################################################
# Cluster
################################################################################

variable "cluster_version" {
  description = "Kubernetes `<major>.<minor>` version to use for the EKS cluster (i.e.: `1.28`)"
  type        = string
  default     = "1.28"
}
