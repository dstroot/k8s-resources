#!/bin/sh


# Setup our Variables
# -------------------------------------------------------------
PROJECT="splendid-timer-160003" 
REGION="us-west1"
ZONE="us-west1-b"
CLUSTER="thepishoppe"


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
  --image-type "COS" \
  --disk-size "100" \
  --scopes "https://www.googleapis.com/auth/compute",\
"https://www.googleapis.com/auth/devstorage.read_only",\
"https://www.googleapis.com/auth/sqlservice.admin",\
"https://www.googleapis.com/auth/logging.write",\
"https://www.googleapis.com/auth/servicecontrol",\
"https://www.googleapis.com/auth/service.management.readonly",\
"https://www.googleapis.com/auth/ndev.clouddns.readwrite",\
"https://www.googleapis.com/auth/trace.append"\
  --num-nodes "3" \
  --network "default" \
  --enable-cloud-logging \
  --no-enable-cloud-monitoring \
  --enable-autoscaling \
  --min-nodes "3" \
  --max-nodes "5" \
  --enable-autoupgrade \
  --enable-autorepair
  # --enable-kubernetes-alpha


# Connect the kubectl client to the cluster we just created.
# -------------------------------------------------------------
gcloud container clusters get-credentials $CLUSTER \
    --zone $ZONE --project $PROJECT
    

# create persistent disks
# -------------------------------------------------------------
# Use the gcloud compute disks create command to create a new persistent disk.
# If you need an SSD persistent disk for additional throughput or IOPS,
# include the --type flag and specify pd-ssd.  200GB is the smallest size to 
# acheive high IOPS.
#
# gcloud compute disks create [DISK_NAME] --size [DISK_SIZE] --type [DISK_TYPE]
#
# Compute Engine also offers always-encrypted local solid-state drive (SSD) block
# storage for virtual machine instances. Unlike persistent disks, local SSDs
# are physically attached to the server that hosts your virtual machine
# instance. This tight coupling offers superior performance, very high
# input/output operations per second (IOPS), and very low latency compared
# to persistent disks.

# # Prometheus
# gcloud compute disks create --size 200GB prometheus
# 
# # Alertmanager
# gcloud compute disks create --size 200GB alertmanager
# 
# # Grafana
# gcloud compute disks create --size 200GB grafana