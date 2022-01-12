---
title: lvm-localpv - a good upgrade to local-path-provisioner
subtitle:  lvm-localpv is a good upgrade to local-path-provisioner
tags: [gitops, devops, distributed computing, nix, tooling]
---

# lvm-localpv is a good upgrade to local-path-provisioner


> A new tool that blends your everyday work apps into one. It's the all-in-one workspace for you and your team


In the Kubernetes world, the Container Storage Interface (CSI) is an interface that is called whenever a Persistent Volume is created, updated or destroyed. There is an associated "driver" that is responsible for allocating the underlying volume and making it available to the related pod. Typically on AWS, the CSI driver would reserve an EBS volume and then attach/detach it to the right EC2 instance where the pod is running. Being on bare metal, we used for a while and then switched to . The rest of the article will be explaining the differences and our thinking a bit more.

local-path-provisioner CSI driver

We started with local-path-provisioner mainly because it ships with K3S. It's a very simple driver that allocates a folder on the node where the pod gets allocated and mounts that folder into the pod. That's it. It's very simple and works on any Linux node that has enough disk space available.

We used it for a few months and then started hitting some limitations. Because of its design, it's not able to report quota or disk usage. After all, it's just a folder on a shared file system. We also hit which broke some of our deployments as is still kinda around these days. Another side factor is that we are using which recommends using XFS for performance and tuning reasons.

No volume usage reporting

Not relocatable between nodes

After a bit of searching, @Florian Klink found lvm-localpv. Logical Volume Manager (LVM) is a Linux partition management structure that sits on top of a disk. It's another interface that is part of the Linux kernel that allows to allocate, resize and remove system volumes. All the drive has to do is to translate the CSI interface calls to Linux kernel calls.

It's a tiny bit more difficult to install as it requires preparing the host with an LVM partition. We have allocated 40GB for the system partition, some swap, and then the rest formatted with LVM. In exchange, we can now allocate volumes with quotas, get volume usage metrics, and select which file system type to use on a per-volume basis. The most impressive part is that since last month when we installed it, it just works. We didn't have to do any maintenance on this.

No maintenance, works out of the box.

Per volume file system type

Have to prepare the host with an LVM disk.

Not relocatable between nodes

Keen readers might notice that I didn't talk about the volumes not being relocatable between machines. What this means is that, unlike EBS, if a node goes down, all the associated data is lost. It also means that the cluster is a bit less elastic since pods using volumes always get scheduled to the same node. To counter that, we replicate the data on the application level. Postgres and Redpanda are deployed in HA mode. If a node goes down, we can sleep through the night and repair the next day. This is enough for our current setup.

In the future, we might be looking at the umbrella OpenEBS project, which lvm-localpv belongs to. For now, it's not worth the extra complexity.
