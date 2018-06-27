---
title: "Cluster Setup"
category_title: "Overview"
weight: 1000
aliases: ["/operation/installation/cluster_setup/"]
---

This section gives some high level suggestions on how to install Humio.

Please make sure you ended up here on this page, for one of the following reasons

* You want to verify that Humio actually does clustering
* Your current Humio instance is running out of resources

Clustering is very hard and we usually don't recommend running your proof-of-concept on a cluster. You will be surprised
 by the amount of data Humio can handle on a single node setup. As a general rule of thumb a decent sized developer 
 laptop can ingest around 100s GB/day

We appreciate that many of our users will be doing the same work, therefor we've gone ahead and put together a guide for installing Humio with [Docker]({{< ref "docker.md" >}}) and [Ansible]({{< ref "ansible.md" >}}).

## Requirements

Humio has a few requirements, and we will cover most of them in this section.


### System resources

Please see our page on [instance sizing]({{< ref "appendix/instance-sizing.md" >}}).

### Java

Humio depends on Java 9. We recommend using [Azul Systems' Zulu JDK](https://www.azul.com/products/zulu-and-zulu-enterprise/). It's free and is distributed as various OS packages.

### Kafka

Kafka (which then again has a dependency on ZooKeeper) is a core part of Humio. As a bare minimum Humio needs to be able to communicate with one Kafka node, although we recommend putting all Kafka and ZooKeeper nodes into the configuration, i.e.

```
ZOOKEEPER_URL=kafka01:9092,kafka02:9092,kafka03:9092
KAFKA_SERVERS=kafka01:9092,kafka02:9092,kafka03:9092
``` 

Humio can run on the same nodes as the ZooKeeper/Kafka nodes without any issues.

<!-- TODO: @MGR
## Clustering capabilities
 -->

## Recommendations

Due to the nature of the CPU L2 cache we strongly recommend limiting your Humio instances to run on a single CPU Socket

<!-- TODO: Running one Humio per CPU socket -->