#!/bin/bash

for i in $(find -maxdepth 1 -type d -printf '%P\n')
do
	echo "Running image helloworld-$i:"
	docker run --rm helloworld-$i
	echo ""
done
