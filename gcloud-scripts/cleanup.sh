#!/bin/bash


# Setup our Variables
# -------------------------------------------------------------
PROJECT="splendid-timer-160003" 
REGION="us-west1"
ZONE="us-west1-b"
CLUSTER="thepishoppe"


# Cleanup cluster
# -------------------------------------------------------------
gcloud --project $PROJECT container clusters delete $CLUSTER --async