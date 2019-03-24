#!/bin/bash
# Copyright (c) 2018-2019 MariaDB Corporation Ab
# 
# Use of this software is governed by the Business Source License included
# in the LICENSE.TXT file and at www.mariadb.com/bsl11.
#
# Change Date: 2022-04-01
# 
# On the date above, in accordance with the Business Source License, use
# of this software will be governed by version 2 or later of the General
# Public License.

mkdir -p /tmp/bookstore-csv
MCSDIR=/usr/local/mariadb/columnstore
mysql=( $MCSDIR/mysql/bin/mysql --defaults-extra-file=$MCSDIR/mysql/my.cnf -uroot )

if [ ! -f "/docker-entrypoint-initdb.d/sandboxdata.tar" ]; then
  echo "Getting the bookstore sandbox archive ..."
  curl https://downloads.mariadb.com/sample-data/books5001.tar --output /docker-entrypoint-initdb.d/sandboxdata.tar
fi

echo "Extracting bookstore files ..."
tar -xf /docker-entrypoint-initdb.d/sandboxdata.tar --directory /tmp/bookstore-csv

# gunzip cover.csv.gz as will use LDI for innodb table later and simplifies
# for loop below.
currentDir=$(pwd)
cd /tmp/bookstore-csv
echo "Creating tables ..."
sed -i 's/%DB%/bookstore/g'  /tmp/bookstore-csv/01_load_ax_init.sql

"${mysql[@]}" < /tmp/bookstore-csv/01_load_ax_init.sql
if [ $? -gt 0 ]; then 
  echo "Problem creating columnstore tables. Possible cause reusing old PVC."
  exit 1
fi
echo "Loading bookstore data ..."
start=`date +%s`
for i in *.mcs.csv.gz; do
    table=$(echo $i | cut -f 1 -d '.')
    zcat  $table.mcs.csv.gz | /usr/local/mariadb/columnstore/bin/cpimport -s ',' -E "'" bookstore $table
    rm -f $table.mcs.csv.gz
done

for i in *.inno.csv.gz; do
    gunzip $i
    table=$(echo $i | cut -f 1 -d '.')
    "${mysql[@]}" bookstore -e "load data local infile '$table.inno.csv' into table bookstore.$table fields terminated by ',' enclosed by '''';"
    rm -f $table.inno.csv.gz
done
end=`date +%s`
runtime=$((end-start))
echo "Load time: "$runtime"sec"

# now load the covers table which is innodb so use load data local infile
cat readme.md
cd $currentDir
rm -rf /tmp/bookstore-csv
