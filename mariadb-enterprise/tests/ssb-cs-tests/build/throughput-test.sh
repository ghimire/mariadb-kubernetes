#!/bin/bash
#set -eu -o pipefail
set -x
##################
#Power Test
#Restart the database system after load to avoid caching effects.
#Each of the 13 queries are run as concurrent 5 streams.
#Each stream makes 2 runs of each query one after another.
#Time taken for each query in all the streams are captured along with the relevant monitoring metrics.
##################

#K8s resource names
umNode="$1-mdb-cs-um-module-0"

#SSD path
ssbDir=`echo $2 | xargs`  

#1 Execute power test script

cd ssb-cs-tests/ 
kubectl exec -it "$umNode" -- bash "$ssbDir/benchmark_scripts/stream_queries_mdb.sh" 
