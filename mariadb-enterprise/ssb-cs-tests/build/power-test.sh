#!/bin/bash
#set -eu -o pipefail
set -x
##################
#Power Test
#Restart the database system after load to avoid caching effects.
#Each of the 13 queries are run one after another in a sequential manner and it is a single user test.
#Time taken for each query is noted, the query execution plans and relevant monitoring metrics are captured.
#MariaDB caches data hence queries are twice, where the second run of the query is served from cache.
##################

#K8s resource names
umNode="$1-mdb-cs-um-module-0"

#SSD path
ssbDir="$2"

#1 Execute power test script

kubectl exec -it "$umNode" -- mysql -vvv <  "$ssbDir/benchmark_scripts/queries_power_test_mdb.sql" 