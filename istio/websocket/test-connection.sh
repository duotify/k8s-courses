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

MAX=600
echo Setting value from 0 to $MAX

while true
do
  echo 
  for i in {1..9}
  do
    NUM=$((RANDOM % $MAX))

    echo -n Set $i to $NUM
    if [ $NUM -le 200 ]; then
      echo ""
    elif [ $NUM -le 500 ]; then
      echo " Yellow"
    else
      echo " Red"
    fi
 
    curl -s -m 0.5 "http://$INGRESS_IP/api?id=$i&value=$NUM"
  done
  sleep 1
done
