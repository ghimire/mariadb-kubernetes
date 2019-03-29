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
set -e

# temporary data store
mkdir -p /tmp/bookstore
cd /tmp/bookstore

# download online data
curl https://downloads.mariadb.com/sample-data/books5001.tar | tar -x

# expand csv files
gzip -d *.gz

# create test database
echo "DROP DATABASE IF EXISTS test; CREATE DATABASE test;" | ${MARIADB_CLIENT}

if ${MARIADB_CLIENT} -e "show variables like 'version_comment'" | grep -q 'Columnstore'; then
	MARIADB_COLUMNSTORE=1
else
	MARIADB_COLUMNSTORE=0
fi

set -ex
# create test tables
if [[ ${MARIADB_COLUMNSTORE} -eq 1 ]]; then
	# for Columnstore
	sed -e "s/%DB%/test/g" 01_load_ax_init.sql | ${MARIADB_CLIENT}
else
        # for Server
        sed -e "s/%DB%/test/g" 01_load_tx_init.sql | ${MARIADB_CLIENT}
fi

# load data from CSV
sed -e "s/%DB%/test/g" -e "s/%CSV%/$(pwd | sed -e 's/\//\\\//g')\\//g" 02_load_tx_ldi.sql | ${MARIADB_CLIENT}

# finally, run the test cases
cd /usr/share/mysql/mysql-test

if [[ ${MARIADB_COLUMNSTORE} -eq 1 ]]; then
	SKIP_TESTS=""
else
	SKIP_TESTS="--skip-test=short_sort_length"
fi

./mtr --extern host="${MARIADB_HOST}" --extern user="${MARIADB_USER}" --extern password="${MARIADB_PASSWORD}" --extern port=${MARIADB_PORT} --force --verbose --suite=bookstore --max-test-fail=0 ${SKIP_TESTS}
