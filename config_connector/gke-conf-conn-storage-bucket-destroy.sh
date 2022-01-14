#!/usr/bin/env bash

# NOTE: This script will destroy all resources created via the script gke-conf-conn-storage-bucket.sh.
# Confirm all script settings before trying to run as-is.  If you find it beneficial to run in pieces,
# simply leave the export statements in place and comment/uncomment other segments appropriately for
# each subsequent run of the script.

export MY_PREFIX="dspenard"  # just a prefix to help with unique names such as with buckets

export PROJECT_ID=$(gcloud config get-value project)
export PROJECT_USER=$(gcloud config get-value core/account)  # current user
export PROJECT_NUMBER=$(gcloud projects describe $PROJECT_ID --format="value(projectNumber)")
export IDNS=${PROJECT_ID}.svc.id.goog  # workload identity domain

export GCP_REGION="us-central1"
export GCP_ZONE="us-central1-a"
export CLUSTER_NAME="conf-conn-storage-demo"

export CC_SA_NAME="conf-conn-storage-demo-sa"
export CC_NAMESPACE="conf-conn-storage-demo" 
export BUCKET_NAME="${MY_PREFIX}-test-cc-generated-bucket1"

env


## to destroy CRD resources the K8s declarative way
##
## destroy the bucket via Config Connector
# kubectl delete -f storage-bucket.yaml -n $CC_NAMESPACE
## you can also try kubectl delete with --grace-period 0 --force
##
## destroy Config Connector
# kubectl delete -f configconnector.yaml


# destroy cluster
# https://cloud.google.com/sdk/gcloud/reference/container/clusters/delete
gcloud container clusters delete $CLUSTER_NAME --region $GCP_REGION

# destroy service account
# https://cloud.google.com/sdk/gcloud/reference/iam/service-accounts/delete
gcloud iam service-accounts delete "${CC_SA_NAME}@${PROJECT_ID}.iam.gserviceaccount.com" 

# destroy bucket
# https://cloud.google.com/storage/docs/deleting-buckets#command-line
gcloud alpha storage rm --recursive gs://${BUCKET_NAME}
