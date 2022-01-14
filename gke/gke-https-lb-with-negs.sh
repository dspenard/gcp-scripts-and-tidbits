#!/usr/bin/env bash

# Deploys HTTPS load balancer in front of a GKE cluster using network endpoint groups.
# then do an echo server test: https://gke-lb-negs-demo-1.dspenard.com/echo/test

# NOTE: Confirm all script settings before trying to run as-is, and ensure no resource name collisions
# will occur with any existing resources in your project.  If you find it beneficial to run in pieces,
# simply leave the export statements in place and comment/uncomment other segments appropriately for
# each subsequent run of the script.

export MY_PREFIX="gke-lb-negs-demo"  # just a prefix to help with unique names such as with buckets

export PROJECT_ID=$(gcloud config get-value project)
export PROJECT_USER=$(gcloud config get-value core/account)  # current user
export PROJECT_NUMBER=$(gcloud projects describe $PROJECT_ID --format="value(projectNumber)")
export IDNS=${PROJECT_ID}.svc.id.goog  # workflow identity domain

export GCP_REGION="us-west1"
export GKE_CLUSTER_NAME="test-cluster-1"
export GKE_CLUSTER_VERSION="1.20.11-gke.1300"
export GKE_CLUSTER_CHANNEL="stable"
export TEST_NS_1="${MY_PREFIX}-1"
export TEST_NS_2="${MY_PREFIX}-2"
export NETWORK_NAME="default"

export DOMAIN="dspenard.com"  # change to some domain you control

env


# confirm installing in correct project
while true; do
    read -p "Create Cluster ${GKE_CLUSTER_NAME} in Project ${PROJECT_ID} (y/n)? " -n 1 -r yn
    echo
    case $yn in
        [Yy]* ) break;;
        [Nn]* ) exit;;
        * ) echo "Please answer yes or no.";;
    esac
done


# enable APIs
gcloud services enable compute.googleapis.com \
    container.googleapis.com

# create cluster
gcloud container --project $PROJECT_ID clusters create $GKE_CLUSTER_NAME \
    --region $GCP_REGION \
    --num-nodes 1 \
    --enable-ip-alias \
    --cluster-version $GKE_CLUSTER_VERSION \
    --release-channel $GKE_CLUSTER_CHANNEL

# create namespace
kubectl create ns $TEST_NS_1

# create echo server deployment
kubectl create deployment echo --image=k8s.gcr.io/echoserver:1.4 -n $TEST_NS_1

# scale to 3 replicas
kubectl scale deployment echo --replicas 3 -n $TEST_NS_1

# expose deployment with ClusterIP (for external access)
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Service
metadata:
  name: ilb-service
  namespace: $TEST_NS_1
  annotations:
    cloud.google.com/neg: '{"exposed_ports": {"80":{}}}'
    #networking.gke.io/load-balancer-type: "Internal"
  labels:
    app: echo
spec:
  type: ClusterIP
  selector:
    app: echo
  ports:
  - port: 80
    targetPort: 8080
    protocol: TCP
EOF


# create health check
gcloud compute health-checks create http health-check-${TEST_NS_1} \
    --use-serving-port \
    --request-path="/healthz"

# create backend service
gcloud compute backend-services create backend-service-default \
    --global
gcloud compute backend-services create backend-service-${TEST_NS_1} \
    --global \
    --health-checks health-check-${TEST_NS_1}

# create URL map
gcloud compute url-maps create ${TEST_NS_1}-url-map \
    --global \
    --default-service backend-service-default
sleep 10

# add path rules to URL map
gcloud compute url-maps add-path-matcher ${TEST_NS_1}-url-map \
    --global \
    --path-matcher-name=${TEST_NS_1}-matcher \
    --default-service=backend-service-default \
    --backend-service-path-rules="/echo/*=backend-service-${TEST_NS_1}"

# reserve static IP
gcloud compute addresses create ${TEST_NS_1}-static \
    --ip-version=IPV4 \
    --global


# assign static IP to DNS
export STATIC_IP=$(gcloud compute addresses describe ${TEST_NS_1}-static --global --format="value(address)")

# confirm assigned IP to DNS to continue
while true; do
    read -p "Did you create DNS record for ${DOMAIN} with ${STATIC_IP}? " -n 1 -r yn
    echo
    case $yn in
        [Yy]* ) break;;
        [Nn]* ) exit;;
        * ) echo "Please answer yes or no.";;
    esac
done

# create managed SSL cert
gcloud beta compute ssl-certificates create ${TEST_NS_1}-cert \
    --domains "${TEST_NS_1}.${DOMAIN}"

# create target HTTPS proxy
gcloud compute target-https-proxies create ${TEST_NS_1}-https-proxy \
    --ssl-certificates=${TEST_NS_1}-cert \
    --url-map=${TEST_NS_1}-url-map

# create forwarding rule
gcloud compute forwarding-rules create ${TEST_NS_1}-fw-rule \
    --target-https-proxy=${TEST_NS_1}-https-proxy \
    --global \
    --ports=443 \
    --address=${TEST_NS_1}-static


# verify cert (may take 10-20 minutes)
gcloud beta compute ssl-certificates describe ${TEST_NS_1}-cert


# get provisioned NEG (note neg name and zones)
export NEG_NAME=$(kubectl get svc ilb-service -n $TEST_NS_1 -o jsonpath="{.metadata.annotations.cloud\.google\.com/neg-status}" | jq '.network_endpoint_groups | {name: .["80"]}' | jq .name -r)

# add NEG to backend service for each zone
kubectl get svc ilb-service -n $TEST_NS_1 -o jsonpath="{.metadata.annotations.cloud\.google\.com/neg-status}" \
    | jq '.zones | {name: .[]}' | jq .name \
    | xargs -I {} gcloud compute backend-services add-backend backend-service-${TEST_NS_1} \
        --global \
        --network-endpoint-group $NEG_NAME \
        --network-endpoint-group-zone={} \
        --balancing-mode=RATE \
        --max-rate-per-endpoint=100

# create firewall rules for health checks
gcloud compute firewall-rules create fw-allow-health-checks \
    --network=$NETWORK_NAME \
    --action=ALLOW \
    --direction=INGRESS \
    --source-ranges=35.191.0.0/16,130.211.0.0/22 \
    --rules=tcp

# verify backend is healthy
gcloud compute backend-services get-health \
    --global backend-service-${TEST_NS_1}



# ----------- NOW TEST IF ILB CAN WORK IN CLUSTER ---------------

# create namespace
kubectl create ns $TEST_NS_2

# create echo deployment
kubectl create deployment echo --image=k8s.gcr.io/echoserver:1.4 -n $TEST_NS_2

# scale to 3 replicas
kubectl scale deployment echo --replicas 3 -n $TEST_NS_2

# expose deployment with ILB for internal access
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Service
metadata:
  name: ilb-service
  namespace: $TEST_NS_2
  annotations:
    #cloud.google.com/neg: '{"exposed_ports": {"80":{}}}'
    networking.gke.io/load-balancer-type: "Internal"
  labels:
    app: echo
spec:
  type: LoadBalancer
  selector:
    app: echo
  ports:
  - port: 80
    targetPort: 8080
    protocol: TCP
EOF
