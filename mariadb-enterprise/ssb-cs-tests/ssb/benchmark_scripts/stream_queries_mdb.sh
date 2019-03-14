#!/bin/bash
cd /ssb/benchmark_scripts/

for i in 1 2 3 4 5

do
   echo "Stream $i"
   mysql  -vvv < queries_throughput_test_mdb.sql 
done
