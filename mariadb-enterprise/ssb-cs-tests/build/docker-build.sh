#!/bin/bash

set -e
if [[ "$(docker images -q $1:$2 2> /dev/null)" == "" ]]; then
	sed -e "s/\$(sf)/$3/g" build/Dockerfile.tempalte > Dockerfile
	docker build --no-cache . -t $1:$2
else
	echo "Image already available locally"
fi
