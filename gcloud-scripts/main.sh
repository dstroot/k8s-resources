#!/bin/bash

# gcloud script

# create your kubernetes cluster  https://cloud.google.com/sdk/gcloud/reference/container/clusters/create
gcloud container clusters create cluster-1 --num-nodes 5

# Promote ephemeral to static IP
# To promote the allocated IP to static, you can update the Service manifest

kubectl patch svc nginx-ingress-lb -p '{"spec": {"loadBalancerIP": "104.154.109.191"}}'


# Get current versions of nodes and Kubernetes
$ gcloud container get-server-config --zone=us-west1-b

# Results:
# -------------------------
# Fetching server config for us-west1-b
# defaultClusterVersion: 1.5.6
# defaultImageType: COS
# validImageTypes:
# - COS
# - CONTAINER_VM
# validMasterVersions:
# - 1.5.6
# validNodeVersions:
# - 1.5.6
# - 1.5.4
# - 1.4.9
# - 1.4.8
# - 1.3.10
# - 1.2.7





# Node with local ssd: https://cloud.google.com/container-engine/docs/local-ssd
# Create a cluster with local SSD nodes

# GCLOUD
# -------------------------------------------------------------
# The following command creates a cluster of five 16-core nodes,
# each with 60GB of RAM, for a total of 80 cores and 300GB of RAM,
# each with four 375GB local SSD partitions attached. This is a
# total of 20 SSDs/7500GB with autoscaling on. Local SSD
# performance offers less than 1 ms of latency and up to 680,000
# read IOPs and 360,000 write IOPs.

# gcloud container clusters create cluster-1 --zone us-central1-b \
#   --num-nodes=5 --machine-type=n1-standard-16 --local-ssd-count=4 \
#   --enable-autoscaling --min-nodes=3 --max-nodes=10


# Update a running cluster to multi-zone
# ------------------------------------------------------------
# The following command replicates the node footprint across 3 zones.
# After the command has finished, the cluster will have 15 nodes total
# geographically dispersed wherever you specify, managed as one
# total resource. (5 in the default zone, 5 in each of the two additional
# zones). It will have 240 cores, 900GB of RAM, 60 SSD drives with
# 22,500GB of storage. You're welcome. ;)

# gcloud container clusters update cluster-1 --additional-zones=us-central1-f,us-central1-c






# Use the gcloud compute disks create command to create a new persistent disk.
# If you need an SSD persistent disk for additional throughput or IOPS,
# include the --type flag and specify pd-ssd.
#
# gcloud compute disks create [DISK_NAME] --size [DISK_SIZE] --type [DISK_TYPE]
#
# Compute Engine offers always-encrypted local solid-state drive (SSD) block
# storage for virtual machine instances. Unlike persistent disks, local SSDs
# are physically attached to the server that hosts your virtual machine
# instance. This tight coupling offers superior performance, very high
# input/output operations per second (IOPS), and very low latency compared
# to persistent disks.

# create persistent disks
gcloud compute disks create --size 10GB redis-master

# Wordpress
gcloud compute disks create --size 200GB mysql-disk
gcloud compute disks create --size 200GB wordpress-disk

# create persistent disks
gcloud compute disks create --size 10GB sqlpad

# Ghost
gcloud compute disks create --size 200GB ghost-config
gcloud compute disks create --size 200GB ghost-content

# Prometheus
gcloud compute disks create --size 200GB prometheus

# Alertmanager
gcloud compute disks create --size 200GB alertmanager

# Grafana
gcloud compute disks create --size 200GB grafana

# Elastic Search
gcloud compute disks create --size 200GB elasticsearch

gcloud compute disks create --size 10gb letsencrypt

gcloud compute disks create --size 10gb vault

#################################################################
#
#      CLEANUP - Uncomment below
#
#################################################################

# Delete your cluster:
gcloud container clusters delete cluster-1

# Delete your  disks:
gcloud compute disks delete redis-master

# Wordpress disks
gcloud compute disks delete mysql-disk
