---
title: "Cluster Setup with Ansible"
pageImage: /integrations/ansible.svg
icon: /integrations/ansible-logo.svg
categories: ["Integration", "Platform"]
---

This section describes how to install Humio with our Ansible scripts

For guidance on setting up a Humio cluster we have created a reference [Ansible Playbook](https://github.com/humio/ansible-demo).

## Prerequisites

You should have Ansible installed and have SSH and sudo access to the machines you want to deploy Humio on.

## Inventory

We have created a [Github repository](https://github.com/humio/ansible-demo) with scripts to help install and configure Humio.
The demo repository shows you how to use our [humio.ansible-humio](https://github.com/humio/ansible-humio) role together with [AnsibleShipyard.ansible-zookeeper](https://github.com/AnsibleShipyard/ansible-zookeeper) and [humio.ansible-kafka](https://github.com/humio/ansible-kafka) roles.
We suggest you read through the documentation below and have a look at the repository. Check out the scripts and modify them for your environment.

## Putting the playbook together

### ZooKeeper role

We recommend using the [AnsibleShipyard.ansible-zookeeper](https://galaxy.ansible.com/AnsibleShipyard/ansible-zookeeper/) role, since some of it's configuration properties can be reused in the Kafka and Humio plugin. Bare in mind that the role depends on Java. We have successfully tried it out with out own [Java role](https://github.com/humio/ansible-java).

The main purpose of the ZooKeeper role is as follows:

1. Create a `zookeeper` system user and group
2. Create and configure `/var/lib/zookeeper` for ZooKeeper state 
3. Create and configure `/var/log/zookeeper` for ZooKeeper logs 
4. Produce ZooKeeper configuration in `/etc/zookeeper`
5. Download and install ZooKeeper
6. Configure SystemD/InitD for running ZooKeeper


The following playbook entry should get you up and running.

```yaml
- name: Zookeeper cluster setup
  hosts: zookeepers
  sudo: yes
  roles:
    - role: humio.ansible-java
    - role: AnsibleShipyard.ansible-zookeeper
      zookeeper_hosts: "{{groups['zookeepers']}}"
```

We do however strongly recommend using fixed ZooKeeper IDs with a `zookeeper_id` parameter in your inventory

```yaml
- hosts: zookeepers
  sudo: yes
  roles:
    - role: humio.ansible-java
    - role: AnsibleShipyard.ansible-zookeeper
      zookeeper_hosts: "
       {%- set ips = [] %}
       {%- for host in groups['zookeepers'] %}
       {{- ips.append(dict(id=hostvars[host]['zookeeper_id'], host=host, ip=hostvars[host]['ansible_default_ipv4'].address)) }}
       {%- endfor %}
       {{- ips -}}"
```

For more information on using the ZooKeeper role for configuring ZooKeeper, please take a look at their [documentation on Github](https://github.com/AnsibleShipyard/ansible-zookeeper)

### Kafka role

The main purpose of the ZooKeeper role is as follows:

1. Create a `kafka` system user and group
2. Create and configure `/var/lib/kafka` for ZooKeeper state 
3. Create and configure `/var/log/kafka` for ZooKeeper logs 
4. Produce Kafka configuration in `/etc/kafka` with connections to ZooKeeper
5. Download and install Kafka
6. Configure SystemD/InitD for running Kafka

For Kafka the same `zookeeper_hosts` var can be reused as used in the [ZooKeeper role](#zookeeper-role). Just add the `kafka_listeners` with a list of objects with a `host` field, i.e.

```yaml
- hosts: kafkas
  sudo: yes
  roles:
    - role: humio.ansible-java
    - role: humio.ansible-kafka
      zookeeper_hosts: "
       {%- set ips = [] %}
       {%- for host in groups['zookeepers'] %}
       {{- ips.append(dict(id=hostvars[host]['zookeeper_id'], host=host, ip=hostvars[host]['ansible_default_ipv4'].address)) }}
       {%- endfor %}
       {{- ips -}}"
      kafka_listeners:
        - host: "{{ ansible_ens33.ipv4.address }}"
```

`host` configures where Kafka should be listening of incoming connections.

### Humio role

The main purpose of the Humio role is as follows:

1. Create a `Humio` system user and group
2. Create and configure a data directory in `/var/lib/humio` for each instance of Humio 
3. Create and configure a log directory in `/var/log/zookeeper` for each instance of Humio 
4. Produce Huio configuration in `/etc/humio`
5. Download and install Humio
6. Configure SystemD/InitD for running Humio instances, one for each CPU socket in the physical machine

Again, for the humio role the `zookeeper_hosts` can be reused. Humio just need to know where it can find the Kafka instances

```yaml
- hosts: humios
  sudo: yes
  roles:
    - role: humio.ansible-java
    - role: humio.ansible-humio
      zookeeper_hosts: "
       {%- set ips = [] %}
       {%- for host in groups['zookeepers'] %}
       {{- ips.append(dict(id=hostvars[host]['zookeeper_id'], host=host, ip=hostvars[host]['ansible_default_ipv4'].address)) }}
       {%- endfor %}
       {{- ips -}}"
      kafka_hosts: "
       {%- set ips = [] %}
       {%- for host in groups['kafkas'] %}
       {{- ips.append(dict(ip=hostvars[host]['ansible_default_ipv4'].address)) }}
       {%- endfor %}
       {{- ips -}}"
```

## Inventory

You can choose to run ZooKeeper, Kafka and Humio on the same nodes or individual nodes. Although we recommend having a separate network dedicated to ZooKeeper, Kafka and internal Humio communications.

The suggested best practice is to run 3 instances of ZooKeeper and Kafka.
The ZooKeeper and Kafka instances must run on ports, that the Humio instances can connect to.

Humio can run on the same machines as ZooKeeper and Kafka.

For a high-availability 3 node cluster the minimal inventory should look something like

```yaml
all:
  hosts:
    humio0:
      zookeeper_id: 0
      kafka_broker_id: 0
    humio1:
      zookeeper_id: 1
      kafka_broker_id: 1
    humio2:
      zookeeper_id: 2
      kafka_broker_id: 2
  children:
    zookeepers:
      hosts:
        humio0:
        humio1:
        humio2:
    kafkas:
      hosts:
        humio0:
        humio1:
        humio2:
    humios:
      hosts:
        humio0:
        humio1:
        humio2:
```

Should you want to run more instances of Humio, you can add them to to the `humios` group.

## Deploying


### Preparing your machine

First, make sure you have [Ansible installed](https://docs.ansible.com/ansible/latest/installation_guide/intro_installation.html) on your machine.

Next, create a `requirements.yml` file along with your playbook and inventory, with the following content

```yaml
- src: https://github.com/humio/ansible-java
- src: AnsibleShipyard.ansible-zookeeper
- src: https://github.com/humio/ansible-kafka
- src: https://github.com/humio/ansible-humio
```

Install the roles with

```bash
$ ansible-galaxy install -r requirements.yml
```

### Applying the playbook

This final step can be repeated multiple times

Assuming you have saved the playbook as `cluster.yml`, run the following command to install Humio

```bash
ansible-playbook --inventory-file=inventory.yml cluster.yml
```

This should install Java, ZooKeeper, Kafka, and Humio on your machines. Humio will be exposed on port 8080 on your machines.







<!-- TODO: Consider incorporating the following
Verify that ZooKeeper and Kafka is happy

1. Inspecting the log files:

- `/data/logs/zookeeper_std_out.log`
- `/data/logs/kafka_std_out.log`

2. Using "nc" to get the status of each zookeeper instance.
  The following must respond with either "Leader" or "Follower" for all instances:

```shell
echo stat | nc 192.168.1.1 2181 | grep '^Mode: '
```

3. Optionally, using your favourite Kafka tools to validate the state of your Kafka cluster.
  You could list the topics using this, expecting to get an empty list since this is a fresh install of Kafka

```shell
kafka-topics.sh --zookeeper localhost:2181 --list
```

## Configuring Humio
Please refer to the [configuration]({{< ref "configuration/_index.md" >}}) section

## Cluster Management API
Please refer to the [API page]({{< ref "cluster-management-api.md" >}})
-->