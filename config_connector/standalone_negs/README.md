This set of scripts is not entirely complete and still needs some TLC, so no promises at this point until I fully vet it
and tighten up the scripts.  A few things are being demonstrated here:
- spin up a GKE cluster with Config Connector enabled
- set up an external HTTPS load balancer with a certificate tied to a domain of your choice
- deploy a K8s service and echo application running in 3 pods
- use Config Connector to create a backend service that is tied to standalone network endpoint groups that were created when the K8s service was deployed

Run these scripts one at a time, but check each one first before running.  The backend-service.yaml file is hard-coded
and not generated at this point, so that will need some tweaks to match your resource names.  The env variable
file dev.env needs to be modified to suit your naming convention needs.

- 1-create-cluster.sh
- 2-init-config-connector.sh
- 3-deploy-service.sh
- 4-create-cert-and-ip.sh
- 5-deploy-backend.sh (modify backend-service.yaml first)
- 6-create-forward-rule.sh
