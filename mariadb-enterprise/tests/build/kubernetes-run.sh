#!/bin/bash
# escape image name for sed
img=$( echo "$2" | sed -e 's/\//\\\//g' - )

if [[ "$3" == "sysbench" ]]; then
	POD_NAME="$1-sysbench-test"
elif [[ "$3" == "infrastructure" ]]; then
	POD_NAME="$1-infrastructure-test"
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

# delete existing resource (if any)
if kubectl delete pod "${POD_NAME}" --namespace=testing 2> /dev/null; then
	while kubectl get pods "${POD_NAME}" --namespace=testing >/dev/null 2>/dev/null; do
		echo -n "."
		sleep 1 
	done
	echo ""
fi

# create new resource
set -e
if [[ "$3" == "sysbench" ]]; then
    sed -e "s/\$(MARIADB_CLUSTER)/$1/g" -e "s/\$(IMAGE)/${img}/g" -e "s/\$(SYSBENCH_THREADS)/$4/g" -e "s/\$(SYSBENCH_NUMBER_OF_TABLES)/$5/g" -e "s/\$(SYSBENCH_TABLE_SIZE)/$6/g" -e "s/\$(SYSBENCH_TIME)/$7/g" -e "s/\$(SYSBENCH_DELETE_INSERTS)/$8/g" build/sysbench-job.yaml | kubectl create -f -
elif [[ "$3" == "infrastructure" ]]; then
    sed -e "s/\$(MARIADB_CLUSTER)/$1/g" -e "s/\$(IMAGE)/${img}/g" build/infrastructure-job.yaml | kubectl create -f -
else
    sed -e "s/\$(MARIADB_CLUSTER)/$1/g" -e "s/\$(IMAGE)/${img}/g" build/test-job.yaml | kubectl create -f -
fi
