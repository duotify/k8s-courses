#!/bin/bash

BASE_DIR=`dirname $0`

if [[ $(id -u) != 0 ]]; then
   echo "This script must be run as root" 
   exit 1
fi

if test -f $BASE_DIR/kubeadm_init.log; then
  echo -ne "\nEnter the following command on the worker node: \n\nsudo "
  grep -A 2 'kubeadm join' $BASE_DIR/kubeadm_init.log
  echo -e ""
  exit 0
else
  echo "File kubeadm_init.log not found."
  echo "Run initialize_master.sh to create the cluster."
  exit 1
fi
