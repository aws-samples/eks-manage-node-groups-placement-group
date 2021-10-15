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
variable "region" {}

provider "aws" {
  region = var.region
}

data "aws_availability_zones" "available" {}

// Select the Subnet from an AZ in the VPC being created.
data "aws_subnet" "selected" {
  availability_zone = data.aws_availability_zones.available.names[0]
  vpc_id = module.vpc.vpc_id
}

locals {
  cluster_name = "PlacementGroupDemoEKS-${random_string.suffix.result}"
}

resource "random_string" "suffix" {
  length  = 4
  special = false
}

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "3.7.0"

  name                 = "terraform-demo-vpc"
  cidr                 = "10.128.0.0/16"
  azs                  = [ data.aws_availability_zones.available.names[0], data.aws_availability_zones.available.names[1] ] // In this example only provision two public subnets
  //private_subnets      = ["10.128.1.0/24", "10.128.2.0/24", "10.128.3.0/24"]
  public_subnets       = ["10.128.4.0/24", "10.128.5.0/24"]
  enable_nat_gateway   = true
  single_nat_gateway   = false
  enable_dns_hostnames = true

  tags = {
    "kubernetes.io/cluster/${local.cluster_name}" = "shared"
  }

  public_subnet_tags = {
    "kubernetes.io/cluster/${local.cluster_name}" = "shared"
    "kubernetes.io/role/elb"                      = "1"
  }

  private_subnet_tags = {
    "kubernetes.io/cluster/${local.cluster_name}" = "shared"
    "kubernetes.io/role/internal-elb"             = "1"
  }
}
