#!/bin/bash
# escape image name for sed
img=$( echo "$2" | sed -e 's/\//\\\//g' - )

if [[ "$3" == "sysbench" ]]; then
	POD_NAME="$1-sysbench-test"
else
	POD_NAME="$1-sanity-test"
fi

# delete existing resource (if any)
if kubectl delete pod "${POD_NAME}" 2> /dev/null; then
	while kubectl get pods "${POD_NAME}" >/dev/null 2>/dev/null; do
		echo -n "."
		sleep 1 
	done
	echo ""
fi

# create new resource
set -e
if [[ "$3" == "sysbench" ]]; then
	sed -e "s/\$(MARIADB_CLUSTER)/$1/g" -e "s/\$(IMAGE)/${img}/g" -e "s/\$(SYSBENCH_THREADS)/$4/g" build/sysbench-job.yaml | kubectl create -f -
else
    sed -e "s/\$(MARIADB_CLUSTER)/$1/g" -e "s/\$(IMAGE)/${img}/g" build/test-job.yaml | kubectl create -f -
fi
