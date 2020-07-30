#!/bin/bash

echo
echo testing docker registry...
CODE=$(curl -m 5 -s -o /dev/null -w "%{http_code}\n" -k https://10.20.131.61:30000)
if [ $CODE -eq "200" ]; then
  echo $CODE OK
else
  echo $CODE Error
fi

echo
echo testing linux web server...
CODE=$(curl -m 5 -s -o /dev/null -w "%{http_code}\n" http://10.20.131.61:30010)
if [ $CODE -eq "200" ]; then
  echo $CODE OK
else
  echo $CODE Error
fi

echo
echo testing windows web server...
CODE=$(curl -m 5 -s -o /dev/null -w "%{http_code}\n" http://10.20.131.61:30020)
if [ $CODE -eq "200" ]; then
  echo $CODE OK
else
  echo $CODE Error
fi

echo
echo testing windows web server with hostpath...
CODE=$(curl -m 5 -s -o /dev/null -w "%{http_code}\n" http://10.20.131.61:30030)
if [ $CODE -eq "200" ]; then
  echo $CODE OK
else
  echo $CODE Error
fi

echo
