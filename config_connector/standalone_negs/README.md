### work in progress, but run these scripts to spin up a cluster with config connector enabled, deploy a K8s service, set up an external HTTPS load balancer with a certificate, and then use config connector to create a backend service and tie it to standalone network endpoint groups that were created when the service was deployed

- 1-create-cluster.sh
- 2-init-config-connector.sh
- 3-deploy-service.sh
- 4-create-cert-and-ip.sh
- 5-deploy-backend.sh
- 6-create-forward-rule.sh
