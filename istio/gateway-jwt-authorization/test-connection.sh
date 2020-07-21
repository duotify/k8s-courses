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
while true
do
  clear >$(tty)
  echo '> Connecting to nginx without JWT Token'
  curl -s -m 0.5 http://$INGRESS_IP/labels.html
  echo
  echo
  echo '> Connecting to nginx with invalid JWT Token'
  curl -s -m 0.5 -H "Authorization: Bearer $(cat ./bad-jwt-token.txt)" http://$INGRESS_IP/labels.html
  echo
  echo
  echo '> Connecting to nginx with valid JWT Token'
  curl -s -m 0.5 -H "Authorization: Bearer $(cat ./good-jwt-token.txt)" http://$INGRESS_IP/labels.html
  sleep 2
done
