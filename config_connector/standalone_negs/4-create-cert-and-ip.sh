#!/usr/bin/env bash

set -o allexport
source dev.env
set +o allexport
env


# reserve static IP
gcloud compute addresses create ${NAMESPACE}-static \
    --ip-version=IPV4 \
    --global


# assign static IP to DNS
export STATIC_IP=$(gcloud compute addresses describe ${NAMESPACE}-static --global --format="value(address)")

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
gcloud beta compute ssl-certificates create ${NAMESPACE}-cert \
    --domains "${NAMESPACE}.${DOMAIN}"
