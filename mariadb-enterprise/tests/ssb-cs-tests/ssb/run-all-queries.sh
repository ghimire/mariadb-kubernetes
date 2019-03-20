#!/bin/bash
MCS_DIR=/usr/local/mariadb/columnstore
for i in queries/q*.sql; do
  echo "==== $i.sql"
  $MCS_DIR/mysql/bin/mysql --defaults-extra-file=$MCS_DIR/mysql/my.cnf -u root -e "select calFlushCache()"
  for n in {1..4}; do
    $MCS_DIR/mysql/bin/mysql --defaults-extra-file=$MCS_DIR/mysql/my.cnf -u root -vvv ssb < $i
  done
done
