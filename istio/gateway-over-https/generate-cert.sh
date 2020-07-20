#!/bin/bash

# You can provide custom domain name is the first argument
if [ $# -eq 0 ]; then
  X509_CN='*.domain.com'
else
  X509_CN=$1
fi

openssl req -x509 -newkey rsa:4096 -keyout cert.key -nodes -out cert.pem -days 3652 -subj "/C=TW/ST=Taipei/O=Istio Test/CN=${X509_CN}"
