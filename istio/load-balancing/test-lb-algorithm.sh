#!/bin/bash

# Retrieve Ingress IP from istio-ingressgateway
INGRESS_IP=$(kubectl get service -n istio-system istio-ingressgateway -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')
if test $INGRESS_IP = ""
then
  echo Ingress hostname not found.
  echo Are you running Kubernetes on cloud?
  exit 1
fi

# Parse arguments - $1 - hostname
if test "$1" != ""
then
  echo Connecting to http://nginx.domain.com ...
  echo
else
  echo Please provide hostname in the argument.
  echo "  Example: $0 nginx.domain.com"
  echo You can also provided query parameters after the website
  echo "  Example: $0 nginx.domain.com a=1,b=2"
  exit 2
fi

# Test connection and display version
while true
do
  curl -s -m 0.5 -H "Host: $1" http://$INGRESS_IP/labels.html?$2 | grep version
  sleep 1
done
