#!/bin/bash

# Retrieve Ingress IP from istio-ingressgateway
INGRESS_IP=$(kubectl get service -n istio-system istio-ingressgateway -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')
if test $INGRESS_IP = ''
then
  echo Ingress hostname not found.
  echo Are you running Kubernetes on cloud?
  exit 1
fi

# Test connection
watch -n 2 "\
echo '\n'; echo 'Connecting to nginx-v1'; curl -s -m 0.5 -H 'Host: nginx-v1.domain.com' http://$INGRESS_IP/labels.html; \
echo '\n'; echo 'Connecting to nginx-v2'; curl -s -m 0.5 -H 'Host: nginx-v2.domain.com' http://$INGRESS_IP/labels.html; \
echo '\n'; echo 'Connecting to nginx-v3'; curl -s -m 0.5 -H 'Host: nginx-v3.domain.com' http://$INGRESS_IP/labels.html; \
echo '\n'; echo 'Connecting to nginx';    curl -s -m 0.5 -H 'Host: nginx.domain.com'    http://$INGRESS_IP/labels.html"
