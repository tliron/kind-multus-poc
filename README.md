KIND Multus PoC
===============

Runs two [KIND](https://kind.sigs.k8s.io/) clusters on a single machine with a secondary
"data-plane" network set up via [Multus CNI](https://github.com/k8snetworkplumbingwg/multus-cni).
Pods on either cluster can then communicate with each over the data plane.

This PoC can work rootlessly, using KIND over [Podman](https://podman.io/). Tested on Fedora.

Usage
-----

Run `./cluster.sh` to create the two clusters. Each will be installed with Multus.

You can then switch `kubectl` between working with either cluster by running `./use.sh CLUSTER`,
where CLUSTER is the cluster number, 1 or 2.

To set up the demo workloads on both clusters run `./demo.sh`. This will install two
Deployments on both clusters (4 total). You can now get a shell to all four Deployments using
`./shell.sh CLUSTER DEPLOYMENT`, where CLUSTER is the cluster number and DEPLOYMENT is
the deployment number (1 or 2).

Demo
----

To see how it works, let's try to get a data plane address on cluster #1. Here's an example:

```
./shell.sh 1 1
Switched to context "kind-edge1".
/ # ip a
1: lo: <LOOPBACK,UP,LOWER_UP> mtu 65536 qdisc noqueue qlen 1000
    link/loopback 00:00:00:00:00:00 brd 00:00:00:00:00:00
    inet 127.0.0.1/8 scope host lo
       valid_lft forever preferred_lft forever
    inet6 ::1/128 scope host 
       valid_lft forever preferred_lft forever
2: eth0@if21422: <BROADCAST,MULTICAST,UP,LOWER_UP,M-DOWN> mtu 1500 qdisc noqueue 
    link/ether d6:a2:23:05:92:66 brd ff:ff:ff:ff:ff:ff
    inet 10.97.0.213/24 brd 10.97.0.255 scope global eth0
       valid_lft forever preferred_lft forever
    inet6 fe80::d4a2:23ff:fe05:9266/64 scope link 
       valid_lft forever preferred_lft forever
3: net1@if21424: <BROADCAST,MULTICAST,UP,LOWER_UP,M-DOWN> mtu 1500 qdisc noqueue 
    link/ether 96:32:2c:e4:3e:77 brd ff:ff:ff:ff:ff:ff
    inet 10.1.1.84/24 brd 10.1.1.255 scope global net1
       valid_lft forever preferred_lft forever
    inet6 fe80::9432:2cff:fee4:3e77/64 scope link 
       valid_lft forever preferred_lft forever
```

The secondary network created by Multus is on the third interface. Our address for it is
10.1.1.84.

Now let's try to reach this address from the second cluster:

```
./shell.sh 2 1
Switched to context "kind-edge2".
/ # ping 10.1.1.84
PING 10.1.1.84 (10.1.1.84): 56 data bytes
64 bytes from 10.1.1.84: seq=0 ttl=62 time=0.217 ms
64 bytes from 10.1.1.84: seq=1 ttl=62 time=0.147 ms
64 bytes from 10.1.1.84: seq=2 ttl=62 time=0.154 ms
```

It works! In fact, all four Deployments can reach each other.

How It Works
------------

We're relying on the fact that all KIND clusters on the same machine by default use
the same Podman/Docker network, which is by default a bridge. That means that they
all packets are already shared at L2. The challenge is getting L3 routing set up.

We do this in two steps:

1) The NetworkAttachmentDefinition for Multus uses the [ptp CNI plugin](https://www.cni.dev/plugins/current/main/ptp/).
   KIND comes with very little, but least we have ptp! This allows us to very straightforwardly map
   arbitrary IP addresses. We use a different CIDR for each cluster, while in IPAM we also set up
   a route to the other cluster's CIDR through the local gateway. Remember, everything is on the same
   L2 network.
2) But, the above is all done in container networking. The host doesn't know how to route those
   networks between each other. Thus we also login to the host and manually add the IP routes.

This method can be easily extended to support as many clusters and extra networks as
necessary.
