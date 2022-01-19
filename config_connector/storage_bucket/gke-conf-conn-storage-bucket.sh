#!/usr/bin/env bash

# ref: https://cloud.google.com/config-connector/docs/how-to/getting-started

# NOTE: Confirm all script settings before trying to run as-is, and ensure no resource name collisions
# will occur with any existing resources in your project.  If you find it beneficial to run in pieces,
# simply leave the export statements in place and comment/uncomment other segments appropriately for
# each subsequent run of the script.


export MY_PREFIX="gke-cc-demo"  # just a prefix to help with unique names such as with buckets

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


# confirm installing in correct project
while true; do
    read -p "Create Config Connector on project ${PROJECT_ID} as user ${PROJECT_USER} (y/n)? " -n 1 -r yn
    echo
    case $yn in
        [Yy]* ) break;;
        [Nn]* ) exit;;
        * ) echo "Please answer yes or no.";;
    esac
done


# enable APIs
gcloud services enable compute.googleapis.com \
    container.googleapis.com \
    logging.googleapis.com \
    stackdriver.googleapis.com \
    cloudresourcemanager.googleapis.com \
    iamcredentials.googleapis.com


# create cluster with config connector
# - set appropriate version or leave blank to use the most recent version
# - workload-pool must be set in order to enable the ConfigConnector addon
gcloud container --project $PROJECT_ID clusters create $CLUSTER_NAME \
    --region $GCP_REGION \
    --no-enable-basic-auth \
    --cluster-version "1.20.11-gke.1300" \
    --release-channel "stable" \
    --machine-type "e2-small" \
    --image-type "COS" \
    --disk-type "pd-standard" \
    --disk-size "100" \
    --metadata disable-legacy-endpoints=true \
    --scopes "https://www.googleapis.com/auth/cloud-platform" \
    --preemptible \
    --num-nodes "1" \
    --enable-stackdriver-kubernetes \
    --enable-ip-alias \
    --network "projects/${PROJECT_ID}/global/networks/default" \
    --subnetwork "projects/${PROJECT_ID}/regions/${GCP_REGION}/subnetworks/default" \
    --default-max-pods-per-node "110" \
    --enable-autoscaling --min-nodes "0" --max-nodes "3" \
    --enable-master-authorized-networks --master-authorized-networks 174.45.73.139/32 \
    --addons HorizontalPodAutoscaling,HttpLoadBalancing,NodeLocalDNS,ConfigConnector \
    --enable-autoupgrade --enable-autorepair \
    --max-surge-upgrade 2 --max-unavailable-upgrade 1 \
    --workload-pool $IDNS \
    --enable-shielded-nodes \
    --shielded-secure-boot


# create config connector identity
# ref: https://cloud.google.com/config-connector/docs/how-to/install-upgrade-uninstall#identity
gcloud iam service-accounts create $CC_SA_NAME


# grant service account desired role (owner | editor)
gcloud projects add-iam-policy-binding $PROJECT_ID \
    --member="serviceAccount:${CC_SA_NAME}@${PROJECT_ID}.iam.gserviceaccount.com" \
    --role="roles/editor"


# grant service account workload identity policy binding
gcloud iam service-accounts add-iam-policy-binding \
    ${CC_SA_NAME}@${PROJECT_ID}.iam.gserviceaccount.com \
    --member="serviceAccount:${PROJECT_ID}.svc.id.goog[cnrm-system/cnrm-controller-manager]" \
    --role="roles/iam.workloadIdentityUser"


################################

# create config connector
cat > configconnector.yaml << EOF
# configconnector.yaml
apiVersion: core.cnrm.cloud.google.com/v1beta1
kind: ConfigConnector
metadata:
  # the name is restricted to ensure that there is only one
  # ConfigConnector instance installed in your cluster
  name: configconnector.core.cnrm.cloud.google.com
spec:
  mode: cluster
  googleServiceAccount: "${CC_SA_NAME}@${PROJECT_ID}.iam.gserviceaccount.com"
EOF


kubectl apply -f configconnector.yaml

sleep 10


# create namespace
kubectl create ns $CC_NAMESPACE


# annotate namespace for config connector
kubectl annotate namespace \
    $CC_NAMESPACE cnrm.cloud.google.com/project-id=${PROJECT_ID}


# list config connector CRDs
kubectl get crds --selector cnrm.cloud.google.com/managed-by-kcc=true


# describe CRD
kubectl describe crd storagebuckets.storage.cnrm.cloud.google.com


# create manifest for storage service
cat > enable-storage.yaml << EOF
apiVersion: serviceusage.cnrm.cloud.google.com/v1beta1
kind: Service
metadata:
  name: storage.googleapis.com
EOF


# apply manifest
kubectl apply -f enable-storage.yaml -n $CC_NAMESPACE

sleep 10


################################

# create manifest for storage bucket
cat > storage-bucket.yaml << EOF
apiVersion: storage.cnrm.cloud.google.com/v1beta1
kind: StorageBucket
metadata:
  annotations:
    cnrm.cloud.google.com/project-id : $PROJECT_ID
  name: $BUCKET_NAME
spec:
  lifecycleRule:
    - action:
        type: Delete
      condition:
        age: 7
EOF


# apply manifest
kubectl apply -f storage-bucket.yaml -n $CC_NAMESPACE

sleep 10


# describe storage bucket
kubectl describe storagebuckets -n $CC_NAMESPACE


# list buckets to see if it exists
gsutil ls
