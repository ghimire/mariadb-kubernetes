#!/bin/bash

if [[ "${MARIADB_HOST}" == "" ]]; then
	echo "MARIADB_HOST expected"
	exit 1
fi

if [[ "${MARIADB_USER}" == "" ]]; then
	echo "MARIADB_USER expected"
	exit 1
fi

if [[ "${MARIADB_PASSWORD}" == "" ]]; then
	echo "MARIADB_PASSWORD expected"
	exit 1
fi

if mysql -h ${MARIADB_HOST} -P4006 -u ${MARIADB_USER} -p${MARIADB_PASSWORD} -e "SELECT 1" 2>&1 >/dev/null; then
	MARIADB_PORT="4006"
else
	if mysql -h ${MARIADB_HOST} -P3306 -u ${MARIADB_USER} -p${MARIADB_PASSWORD} -e "SELECT 1" 2>&1 >/dev/null; then
		MARIADB_PORT="3306"
	else
		echo "Cannot determine MariaDB Server port"
		exit 1
	fi
fi
MARIADB_CLIENT="mysql -h ${MARIADB_HOST} -P ${MARIADB_PORT} -u ${MARIADB_USER} -p${MARIADB_PASSWORD}"

set -ex

# create the sysbench database
echo "DROP DATABASE IF EXISTS sbtest; CREATE DATABASE sbtest;" | ${MARIADB_CLIENT}

# create sysbench tables and load them with data
# TODO add environment variables for the scale
sysbench \
	/usr/share/sysbench/oltp_read_write.lua \
	--threads=4 \
	--mysql-host=${MARIADB_HOST} \
	--mysql-user=${MARIADB_USER} \
	--mysql-password=${MARIADB_PASSWORD} \
	--mysql-port=${MARIADB_PORT} \
	--tables=${SYSBENCH_NUMBER_OF_TABLES} \
	--table-size=${SYSBENCH_TABLE_SIZE} \
	prepare

# give slaves a chance to catch up
sleep 30

# finally, run sysbench
# TODO add control to adjust read-write mix
# TODO add control to cover different workloads, e.g. for analytics
sysbench \
	/usr/share/sysbench/oltp_read_write.lua \
	--threads=${SYSBENCH_THREADS} \
	--events=0 \
	--time=${SYSBENCH_TIME} \
	--mysql-host=${MARIADB_HOST} \
	--mysql-user=${MARIADB_USER} \
    --mysql-password=${MARIADB_PASSWORD} \
	--mysql-port=${MARIADB_PORT} \
	--tables=${SYSBENCH_NUMBER_OF_TABLES} \
	--delete_inserts=${SYSBENCH_DELETE_INSERTS} \
	--table-size=${SYSBENCH_TABLE_SIZE} \
	--db-ps-mode=disable \
	--report-interval=1 \
	--histogram \
	--point_selects=10 \
	--simple_ranges=8 \
	--sum_ranges=3 \
	--order_ranges=3 \
	--distinct_ranges=2 \
	--index_updates=0 \
	--non_index_updates=1 \
	--skip_trx=true \
	--mysql-ignore-errors=1062,1213 \
	run
