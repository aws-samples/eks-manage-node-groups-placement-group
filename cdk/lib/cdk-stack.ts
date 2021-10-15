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
import * as cdk from '@aws-cdk/core';
import * as eks from '@aws-cdk/aws-eks';
import * as ec2 from '@aws-cdk/aws-ec2';

/**
 * Launch the number of instances per group at once to ensure the availability of landing in one `cluster` placement group 
 */
const NUMBER_OF_INSTANCES_PER_GROUP = 2;

export class CdkStack extends cdk.Stack {
  constructor(scope: cdk.Construct, id: string, props?: cdk.StackProps) {
    super(scope, id, props);

    // Add EKS cluster
    const cluster = new eks.Cluster(this, 'PlacementGroupDemoEKS', {
      version: eks.KubernetesVersion.V1_21,
      defaultCapacity: 0,
    });

    // Shared node group configuration
    const sharedNgConfig = {
      instanceTypes: [
        ec2.InstanceType.of(ec2.InstanceClass.C5, ec2.InstanceSize.LARGE),
      ],
      maxSize: NUMBER_OF_INSTANCES_PER_GROUP,
      minSize: NUMBER_OF_INSTANCES_PER_GROUP,
      desiredSize: NUMBER_OF_INSTANCES_PER_GROUP,
      subnets: {
        subnets: [
          cluster.vpc.publicSubnets[0], // Force all worker nodes to be in same AZ for fair performance comparison.
        ],
      },
    };

    /**
     * Add a node group with all instances in the same placement group of `cluster` type
     */
    const pg = new ec2.CfnPlacementGroup(this, 'PlacementGroup', {
      strategy: 'cluster',
    });
    const lt = new ec2.LaunchTemplate(this, 'PlacementGroupLaunchTemplate');
    const cfnLt = lt.node.defaultChild as ec2.CfnLaunchTemplate;
    cfnLt.addOverride('Properties.LaunchTemplateData.Placement.GroupName', pg.ref);

    cluster.addNodegroupCapacity('NgTruePlacementGroup', {
      ...sharedNgConfig,
      labels: {
        placementGroup: 'true',
      },
      launchTemplateSpec: {
        id: lt.launchTemplateId!,
        version: lt.latestVersionNumber,
      },
    });

    /**
     * Add another node group with same configurations except not in a placement group but in same AZ
     */
    cluster.addNodegroupCapacity('NgFalsePlacementGroup', {
      ...sharedNgConfig,
      labels: {
        placementGroup: 'false',
      },
    });
  }
}
