#Date values must be specified in the format 'yyyy-mm-dd' for cpimport 
#!/bin/bash

cd /ssb/benchmark_scripts/

MCS_DIR=/usr/local/mariadb/columnstore

$MCS_DIR/bin/cpimport ssb part ../part.tbl
$MCS_DIR/bin/cpimport ssb supplier ../supplier.tbl
$MCS_DIR/bin/cpimport ssb customer ../customer.tbl
$MCS_DIR/bin/cpimport ssb dimdate ../date.tbl
$MCS_DIR/bin/cpimport ssb lineorder ../lineorder.tbl
