/*
 * Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 * SPDX-License-Identifier: MIT-0
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy of this
 * software and associated documentation files (the "Software"), to deal in the Software
 * without restriction, including without limitation the rights to use, copy, modify,
 * merge, publish, distribute, sublicense, and/or sell copies of the Software, and to
 * permit persons to whom the Software is furnished to do so.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED,
 * INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A
 * PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
 * HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
 * OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
 * SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
 */

locals {
  cluster_name = "PlacementGroupDemoEKS-${random_string.suffix.result}"
}

resource "random_string" "suffix" {
  length  = 4
  special = false
}

// Select the Subnet from an AZ in the VPC being created.

data "aws_subnet" "selected" {
  availability_zone = data.aws_availability_zones.available.names[0]

  filter {
    name   = "tag:Name"
    values = ["terraform-eks-demo-public"]
  }
}

module "eks" {
  source                          = "terraform-aws-modules/eks/aws"
  cluster_name                    = local.cluster_name
  cluster_version                 = var.cluster_version
  cluster_endpoint_private_access = true
  cluster_endpoint_public_access  = true
  subnet_ids                      = module.vpc.public_subnets

  cluster_enabled_log_types = ["api", "audit", "authenticator", "controllerManager", "scheduler"]

  tags = {
    Environment = "testing"
    GithubRepo  = "terraform-aws-eks"
    GithubOrg   = "terraform-aws-modules"
  }

  vpc_id = module.vpc.vpc_id

  eks_managed_node_group_defaults = {
    ami_type  = "AL2_x86_64"
    disk_size = 50
  }

  eks_managed_node_groups = {
    placementgroup01 = {
      name_prefix  = "placementgroup"
      desired_size = 2
      max_size     = 2
      min_size     = 2

      create_launch_template     = false
      use_custom_launch_template = true

      launch_template_id      = aws_launch_template.default.id
      launch_template_name    = aws_launch_template.default.name
      launch_template_version = aws_launch_template.default.default_version
      // This is to get the subnet id from the subnet ARN, as the data.aws_subnet does not have attribute of subnet id.
      subnets = [split("/", data.aws_subnet.selected.arn)[1]]

      instance_types = [var.instance_type]

      labels = {
        placementGroup = "true"
      }

      tags = {
        placementgroup = "true"
        GithubRepo     = "terraform-aws-eks"
      }
    },
    nonplacementgroup02 = {
      name_prefix  = "non-placementgroup"
      desired_size = 2
      max_size     = 2
      min_size     = 2

      instance_types = [var.instance_type]
      // This is to get the subnet id from the subnet ARN, as the data.aws_subnet does not have attribute of subnet id.
      subnets = [split("/", data.aws_subnet.selected.arn)[1]]

      labels = {
        placementGroup = "false"
      }

      tags = {
        placementGroup = "false"
        GithubRepo     = "terraform-aws-eks"
      }
    }
  }
}

