#!/bin/bash


# Setup our Variables
# -------------------------------------------------------------
PROJECT="splendid-timer-160003" 
REGION="us-west1"
ZONE="us-west1-b"
CLUSTER="thepishoppe"


# Get gcloud configured and authenticated
# -------------------------------------------------------------
gcloud init
gcloud auth login

# Ensure kubectl has authentication credentials:
# -------------------------------------------------------------
gcloud auth application-default login


# Configure gcloud
# -------------------------------------------------------------
gcloud config set project $PROJECT
gcloud config set compute/region $REGION
gcloud config set compute/zone $ZONE


# Create a project
# -------------------------------------------------------------
# Project IDs must start with a lowercase letter and can have 
# lowercase ASCII letters, digits or hyphens. Project IDs must 
# be between 6 and 30 characters.
# -------------------------------------------------------------
# NOTE: if we create a new project it makes the creation
# of a static IP a little more challenging.  You can only let
# the system assign one and then promote it to a static address.
# It's easier to manually create a project and manually
# create a static IP and the use it later.  Note you also need
# to enable billing of new projects.
# -------------------------------------------------------------
# https://cloud.google.com/sdk/gcloud/reference/projects/
# -------------------------------------------------------------
# gcloud projects create $PROJECT \
#   --enable-cloud-apis \
#   --set-as-default







# Reserve an IP address for your company
# -------------------------------------------------------------
# NOTE: Make a note of the IP address we will need it later. 
# From the commend line you can only have GCE assign an address
# and then "promote" it to be a static address.
# -------------------------------------------------------------
# https://cloud.google.com/sdk/gcloud/reference/compute/addresses/create
# -------------------------------------------------------------
gcloud compute --project $PROJECT \
  addresses create $CLUSTER \
  --addresses 104.154.109.191  
  --description "Reserve a static IP for my company" \
  --region $REGION


# Create a Kubernetes cluster 
# -------------------------------------------------------------
# NOTE: The scopes provide access to SQL and we have DNS rights
# so we can manage DNS automatically via:
# "https://www.googleapis.com/auth/ndev.clouddns.readwrite"
# -------------------------------------------------------------
# https://cloud.google.com/sdk/gcloud/reference/container/clusters/create
# -------------------------------------------------------------
gcloud container --project $PROJECT \
  clusters create $CLUSTER \
  --zone $ZONE \
  --machine-type "n1-standard-1" \
  --image-type "GCI" \
  --disk-size "100" \
  --scopes "https://www.googleapis.com/auth/compute",\
  "https://www.googleapis.com/auth/devstorage.read_only",\
  "https://www.googleapis.com/auth/sqlservice.admin",\
  "https://www.googleapis.com/auth/logging.write",\
  "https://www.googleapis.com/auth/servicecontrol",\
  "https://www.googleapis.com/auth/service.management.readonly",\
  "https://www.googleapis.com/auth/ndev.clouddns.readwrite",\
  "https://www.googleapis.com/auth/trace.append" \
  --num-nodes "3" \
  --network "default" \
  --enable-cloud-logging \
  --no-enable-cloud-monitoring \
  --enable-autoscaling \
  --min-nodes "3" \
  --max-nodes "5" \
  --enable-autoupgrade \
  --enable-autorepair
  
  

# Connect the kubectl client to the cluster you just created.
# -------------------------------------------------------------
gcloud container clusters get-credentials $CLUSTER \
    --zone $ZONE --project $PROJECT


# Then start a proxy to connect to the Kubernetes control plane:
# -------------------------------------------------------------
kubectl proxy


# Scale a deployment:
# -------------------------------------------------------------
kubectl scale --replicas=3 deployment/hello



  
# Create a DNS zone which will contain managed DNS records.
# -------------------------------------------------------------
$ gcloud dns managed-zones create "thepishoppe" \
    --dns-name "external-dns-test.gcp.zalan.do." \
    --description "Automatically managed zone by kubernetes.io/external-dns"


# Make a note of the nameservers that were assigned to your new zone.
# -------------------------------------------------------------
gcloud dns record-sets list \
    --zone "external-dns-test-gcp-zalan-do" \
    --name "external-dns-test.gcp.zalan.do." \
    --type NS

# 
# NAME                             TYPE  TTL    DATA
# external-dns-test.gcp.zalan.do.  NS    21600  ns-cloud-e1.googledomains.com.,ns-cloud-e2.googledomains.com.,ns-cloud-e3.googledomains.com.,ns-cloud-e4.googledomains.com.
# 







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

# 
# 
# References
# https://github.com/kubernetes-incubator/external-dns/blob/master/docs/tutorials/gke.md