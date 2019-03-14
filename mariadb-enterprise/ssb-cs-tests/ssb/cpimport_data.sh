#!/bin/bash

cd /ssb

MCS_DIR=/usr/local/mariadb/columnstore
$MCS_DIR/bin/cpimport ssb lineorder lineorder.tbl
$MCS_DIR/bin/cpimport ssb part part.tbl
$MCS_DIR/bin/cpimport ssb supplier supplier.tbl
$MCS_DIR/bin/cpimport ssb customer customer.tbl
$MCS_DIR/bin/cpimport ssb dim_date date.tbl
