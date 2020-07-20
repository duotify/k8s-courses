#!/bin/bash

# You can provide the domain name is the first argument
if [ $# -eq 0 ]; then
  WEBSITE=nginx.domain.com
else
  WEBSITE=$1
fi

# Retrieve Ingress IP from istio-ingressgateway
INGRESS_IP=$(kubectl get service -n istio-system istio-ingressgateway -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')
if test $INGRESS_IP = ''
then
  echo Ingress hostname not found.
  echo Are you running Kubernetes on cloud?
  exit 1
fi

# Switch Ingress IP from domain name to IP address
INGRESS_IP=`dig +short $INGRESS_IP | head -n 1`

# Test connection
watch -n 1 "\
echo '\n'; echo 'Connecting to nginx over https'; curl -s -k -m 0.5 --resolve $WEBSITE:443:$INGRESS_IP https://$WEBSITE/labels.html"
