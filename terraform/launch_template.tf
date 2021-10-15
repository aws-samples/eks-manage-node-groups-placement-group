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
resource "aws_placement_group" "eks" {
  name     = "eks-placement-group"
  strategy = "cluster"
  tags = {
    placementGroup = "true",
    applicationType = "eks"
  }
}


resource "aws_launch_template" "default" {
  name_prefix            = "eks-example-placementgroup-"
  description            = "Default Launch-Template for Placement Group"
  update_default_version = true

  block_device_mappings {
    device_name = "/dev/sda1"

    ebs {
      volume_size = 20
      encrypted = true
    }
  }

  placement {
    availability_zone = data.aws_availability_zones.available.names[0]
    group_name = aws_placement_group.eks.name
  }

  vpc_security_group_ids = [
    aws_security_group.all_worker_mgmt.id,
    module.eks.worker_security_group_id
  ]

  tag_specifications {
    resource_type = "instance"

    tags = {
      placementGroup = "true"
    }
  }
  
  # Tag the LT itself
  tags = {
    placementGroup = "true"
  }

  lifecycle {
    create_before_destroy = true
  }
  
}