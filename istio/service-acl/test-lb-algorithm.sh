#!/bin/bash

# Retrieve Ingress IP from istio-ingressgateway
INGRESS_IP=$(kubectl get service -n istio-system istio-ingressgateway -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')
if test $INGRESS_IP = ""
then
  echo Ingress hostname not found.
  echo Are you running Kubernetes on cloud?
  exit 1
fi

# Test connection and display version
while true
do
  curl -s -m 0.5 -o /dev/null http://$INGRESS_IP/productpage
  sleep 0.5
done
