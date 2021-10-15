# CDK Sample for EKS Cluster and Node Groups with Placement Group

The sample CDK code creates a new VPC and deploys an EKS cluster with two node groups. Both node groups contain two c5.large instances, one with placement group of `cluster` type and one without. [iperf3](https://hub.docker.com/r/networkstatic/iperf3) is deployed into both node groups for evaluating the network performance.

## Diagram

![EKS with Cluster Placement Group](/assets/images/EKS-MNG-PG.jpg "EKS with Cluster Placement Group")

## Deploy

* `npm ci`          install npm dependencies
* `npm run build`   compile typescript to js
* `cdk synth`       emits the synthesized CloudFormation template
* `cdk deploy`      deploy this stack to your default AWS account/region

Note: the sample is using CDK version 1.125.0 in `TypeScript`. To install CDK, please refer to the [CDK Official Document](https://docs.aws.amazon.com/cdk/latest/guide/getting_started.html)

## Performance Test

[iperf](https://iperf.fr) is used for throughput test and `ping` is used for latency test. Both of them are provided in [perfsonar](https://hub.docker.com/r/perfsonar/testpoint/) container image.

* Deploy `iperf` pods

```bash
$ kubectl apply -f ../yaml/deployment.yml
deployment.apps/cluster-placementgroup-enabled created
deployment.apps/cluster-placementgroup-disabled created
```

* return nodes with placement group configured

```bash
kubectl get nodes -l placementGroup=true
```

* return pods running in the placement group

```bash
kubectl get pods -o=wide -l app=cluster-placementgroup-enabled
```

* run throughput test with `iperf3` from one pod to the other

```bash
kubectl exec -i -t <one pod name> -- bash -c "iperf3 -c <ip of the other pod>"
```

* run latency test with `ping` from one pod to the other

```bash
kubectl exec -i -t <one pod name> -- bash -c "ping -c 30 <ip of the other pod>"
```

## Sample Output

* throughput result with placement group configured

```bash
$ kubectl exec -i -t cluster-placementgroup-enabled-868c59f745-qknl5 -- bash -c "iperf3 -c 10.0.37.71"
Connecting to host 10.0.37.71, port 5201
[  5] local 10.0.15.0 port 46464 connected to 10.0.37.71 port 5201
[ ID] Interval           Transfer     Bitrate         Retr  Cwnd
[  5]   0.00-1.00   sec  1.11 GBytes  9.55 Gbits/sec  107   1.66 MBytes       
[  5]   1.00-2.00   sec  1.11 GBytes  9.52 Gbits/sec  230   1.19 MBytes       
[  5]   2.00-3.00   sec  1.11 GBytes  9.50 Gbits/sec   70   1.17 MBytes       
[  5]   3.00-4.00   sec  1.10 GBytes  9.46 Gbits/sec  386   1.20 MBytes       
[  5]   4.00-5.00   sec  1.10 GBytes  9.47 Gbits/sec  111   1.64 MBytes       
[  5]   5.00-6.00   sec  1.10 GBytes  9.48 Gbits/sec  353   1.24 MBytes       
[  5]   6.00-7.00   sec  1.11 GBytes  9.53 Gbits/sec   76   1.66 MBytes       
[  5]   7.00-8.00   sec  1.11 GBytes  9.52 Gbits/sec  413   1.15 MBytes       
[  5]   8.00-9.00   sec  1.11 GBytes  9.53 Gbits/sec  176   1.53 MBytes       
[  5]   9.00-10.00  sec  1.10 GBytes  9.49 Gbits/sec  133   1.33 MBytes       
- - - - - - - - - - - - - - - - - - - - - - - - -
[ ID] Interval           Transfer     Bitrate         Retr
[  5]   0.00-10.00  sec  11.1 GBytes  9.50 Gbits/sec  2055             sender
[  5]   0.00-10.00  sec  11.1 GBytes  9.50 Gbits/sec                  receiver

iperf Done.
```

* throughput result **without** placement group

```bash
$ kubectl exec -i -t cluster-placementgroup-disabled-94c99786d-699fz -- bash -c "iperf3 -c 10.0.1.149"
Connecting to host 10.0.1.149, port 5201
[  5] local 10.0.22.48 port 34756 connected to 10.0.1.149 port 5201
[ ID] Interval           Transfer     Bitrate         Retr  Cwnd
[  5]   0.00-1.00   sec   584 MBytes  4.90 Gbits/sec   94   1.48 MBytes       
[  5]   1.00-2.00   sec   581 MBytes  4.88 Gbits/sec   24   1.31 MBytes       
[  5]   2.00-3.00   sec   591 MBytes  4.96 Gbits/sec    7   1.75 MBytes       
[  5]   3.00-4.00   sec   590 MBytes  4.95 Gbits/sec    4   2.52 MBytes       
[  5]   4.00-5.00   sec   592 MBytes  4.97 Gbits/sec    6   2.24 MBytes       
[  5]   5.00-6.00   sec   590 MBytes  4.95 Gbits/sec   19   1.78 MBytes       
[  5]   6.00-7.00   sec   591 MBytes  4.96 Gbits/sec    0   2.91 MBytes       
[  5]   7.00-8.00   sec   591 MBytes  4.96 Gbits/sec   73   1.90 MBytes       
[  5]   8.00-9.00   sec   591 MBytes  4.96 Gbits/sec    7   2.13 MBytes       
[  5]   9.00-10.00  sec   591 MBytes  4.96 Gbits/sec   41   1.83 MBytes       
- - - - - - - - - - - - - - - - - - - - - - - - -
[ ID] Interval           Transfer     Bitrate         Retr
[  5]   0.00-10.00  sec  5.76 GBytes  4.94 Gbits/sec  275             sender
[  5]   0.00-10.00  sec  5.75 GBytes  4.94 Gbits/sec                  receiver

iperf Done.
```

* latency result with placement group configured

```bash
$ kubectl exec -i -t cluster-placementgroup-enabled-868c59f745-qknl5 -- bash -c "ping -c 30 10.0.37.71"
PING 10.0.37.71 (10.0.37.71) 56(84) bytes of data.
64 bytes from 10.0.37.71: icmp_seq=1 ttl=253 time=0.213 ms
64 bytes from 10.0.37.71: icmp_seq=2 ttl=253 time=0.124 ms
64 bytes from 10.0.37.71: icmp_seq=3 ttl=253 time=0.151 ms
64 bytes from 10.0.37.71: icmp_seq=4 ttl=253 time=0.144 ms
64 bytes from 10.0.37.71: icmp_seq=5 ttl=253 time=0.182 ms
...
64 bytes from 10.0.37.71: icmp_seq=26 ttl=253 time=0.163 ms
64 bytes from 10.0.37.71: icmp_seq=27 ttl=253 time=0.150 ms
64 bytes from 10.0.37.71: icmp_seq=28 ttl=253 time=0.164 ms
64 bytes from 10.0.37.71: icmp_seq=29 ttl=253 time=0.155 ms
64 bytes from 10.0.37.71: icmp_seq=30 ttl=253 time=0.152 ms

--- 10.0.37.71 ping statistics ---
30 packets transmitted, 30 received, 0% packet loss, time 716ms
rtt min/avg/max/mdev = 0.118/0.155/0.213/0.022 ms
```

* latency result **without** placement group configured

```bash
$ kubectl exec -i -t cluster-placementgroup-disabled-94c99786d-699fz -- bash -c "ping -c 30 10.0.1.149"
PING 10.0.1.149 (10.0.1.149) 56(84) bytes of data.
64 bytes from 10.0.1.149: icmp_seq=1 ttl=253 time=0.603 ms
64 bytes from 10.0.1.149: icmp_seq=2 ttl=253 time=0.440 ms
64 bytes from 10.0.1.149: icmp_seq=3 ttl=253 time=0.465 ms
64 bytes from 10.0.1.149: icmp_seq=4 ttl=253 time=0.442 ms
64 bytes from 10.0.1.149: icmp_seq=5 ttl=253 time=0.441 ms
...
64 bytes from 10.0.1.149: icmp_seq=26 ttl=253 time=0.459 ms
64 bytes from 10.0.1.149: icmp_seq=27 ttl=253 time=0.466 ms
64 bytes from 10.0.1.149: icmp_seq=28 ttl=253 time=0.509 ms
64 bytes from 10.0.1.149: icmp_seq=29 ttl=253 time=0.454 ms
64 bytes from 10.0.1.149: icmp_seq=30 ttl=253 time=0.497 ms

--- 10.0.1.149 ping statistics ---
30 packets transmitted, 30 received, 0% packet loss, time 731ms
rtt min/avg/max/mdev = 0.418/0.457/0.603/0.039 ms
```

## Summary

From the sample performance test result shown above, we can see that the placement group inter-node pod to pod throughput is approximately double the one without the placement group (9.50 Gbits/sec vs 4.94 Gbit/sec), and the latency is around 66% lower (0.155ms vs 0.457ms). This shows better performance in both Throughput and Latency with `cluster` placement group.

* Note: There are chances that the inter-node pod to pod without placement group enabled can achieve to the same level of performance as the one with placement group enabled, as it is possible that the two underlying EC2 nodes can sit in the close rack in the same Availability Zone, but this cannot be guaranteed. In order to achieve consistent inter-node pod to pod performance, placement group is recommended to be enabled for the underlying nodes in the Kubernetes cluster.

## Clean Up

* `cdk destroy`      destroy this stack from your default AWS account/region
