#!/usr/bin/env bash

set -o allexport
source dev.env
set +o allexport
env


## run this after the URL map was set up with config connector
#
# create target HTTPS proxy
gcloud compute target-https-proxies create ${NAMESPACE}-https-proxy \
    --ssl-certificates=${NAMESPACE}-cert \
    --url-map=test-conf-conn-url-map
    # --url-map=${NAMESPACE}-url-map
#
# create forwarding rule
gcloud compute forwarding-rules create ${NAMESPACE}-fw-rule \
    --target-https-proxy=${NAMESPACE}-https-proxy \
    --global \
    --ports=443 \
    --address=${NAMESPACE}-static




# todo add some curls and some simple test scripts
#
# # verify backend is healthy
# gcloud compute backend-services get-health \
#     --global backend-service-${NAMESPACE}

