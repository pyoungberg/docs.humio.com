---
title: "Installation"
weight: 90
category_title: Installation Overview
---

Humio is available for [download](https://www.humio.com/download) or as [SaaS](https://cloud.humio.com/).
If you choose to host your own Humio instance, there are two primary ways of installing it:

- Running it in a Docker container
- or running as a Jar file

If you are just getting started with Humio, we recommend running Humio as a Docker container since
it contains the external dependencies needed, i.e. Kafka and Zookeeper. If you plan on
running Humio on bare metal please refer to our [Bare Metal Installation Guide]({{< ref "bare-metal.md" >}}).

## Scaling out

Humio was made to scale and scales very well with the number of nodes in the cluster.
Running a cluster of 3 or more humio nodes provides
higher capacity in terms of both ingest and search performance and also allows high availability by replicating data to more than one node.
If you want to run a clustered mode please refer to [cluster setup]({{< ref "cluster_setup/_index.md" >}}).


## Guides

<!-- - Running Humio on Kubernetes -->
- [Running in Docker]({{< ref "docker.md" >}})
- [Running on Bare Metal]({{< ref "bare-metal.md" >}})
- [Provisioning with Ansible]({{< ref "ansible.md" >}})
- [Running on AWS]({{< ref "aws.md" >}})
- [Running on Nomad]({{< ref "nomad.md" >}})

## Hardware Requirements

Hardware requirements depend on how Humio will be used, both how much data you will be
ingesting and how many concurrent searches you will be running.


### Estimating Resources

Here is a list of *rules of thumb* to help you get an idea of how much hardware is needed.

1. Assume data compresses 9x on ingest (test your setup and see, better compression means better performance).
1. You need to be able to hold 48hrs of compressed data in 80% of you RAM.
1. You want enough hyper-threads/vCPUs (each giving you 1GB/s search) to be able
   to search 24hrs of data in less than 10 seconds.
1. You need disk space to hold your compressed data. Never fill your disk more than 80%.

**Example Setup**  
Your machine has 64G of ram, 8 hyper threads (4 cores) and 1TB of storage.
Your machine can hold 460GB of ingest data compressed in ram and process 8GB/s.  In this case
it means 10 seconds worth of query time will run through 80GB of data.  So this machine
fits an 80GB/day ingest, with +5 days data available for fast querying.  
You can store 7.2TB of data before your disk is 80% full, corresponding to 90 days at 80GB/day ingest

This example assumes all data has the same [Retention settings]({{<
ref "/configuration/retention.md" >}}) But you can configure Humio
to automatically delete some events before others,
e.g. allowing some data to be kept for several years while others get
deleted after 1 week.

For more details refer to our [Instance Sizing Reference]({{< ref "instance-sizing.md" >}}).

## Configuration Options

Please refer to the [configuration reference page]({{< ref "configuration/_index.md" >}}).
