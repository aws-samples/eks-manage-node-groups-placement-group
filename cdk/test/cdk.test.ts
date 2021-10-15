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
import { expect as expectCDK, haveResource } from '@aws-cdk/assert';
import * as cdk from '@aws-cdk/core';
import { CdkStack } from '../lib/cdk-stack';

let app: cdk.App;
let stack: CdkStack;

beforeEach(() => {
  app = new cdk.App();
  stack = new CdkStack(app, 'TestStack', { env: { account: '1234', region: 'us-bla-5' } });
});

test('EKS cluster is created', () => {
  expectCDK(stack).to(haveResource('Custom::AWSCDK-EKS-Cluster'))
});

test('EKS node group with placement group is created', () => {
  expectCDK(stack).to(haveResource('AWS::EKS::Nodegroup', {
    Labels: {
      placementGroup: "true",
    },
  }))
});

test('EKS node group without placement group is created', () => {
  expectCDK(stack).to(haveResource('AWS::EKS::Nodegroup', {
    Labels: {
      placementGroup: "false",
    },
  }))
});

test('Placement group is created with cluster strategy', () => {
  expectCDK(stack).to(haveResource('AWS::EC2::PlacementGroup', {
    Strategy: "cluster",
  }))
});
