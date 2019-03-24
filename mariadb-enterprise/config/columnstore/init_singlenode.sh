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
MASTER_HOST="<<MASTER_HOST>>"
ADMIN_USERNAME="<<ADMIN_USERNAME>>"
ADMIN_PASSWORD="<<ADMIN_PASSWORD>>"
REPLICATION_USERNAME="<<REPLICATION_USERNAME>>"
REPLICATION_PASSWORD="<<REPLICATION_PASSWORD>>"
RELEASE_NAME="<<RELEASE_NAME>>"
CLUSTER_ID="<<CLUSTER_ID>>"
MARIADB_CS_DEBUG="<<MARIADB_CS_DEBUG>>"

MCSDIR=/usr/local/mariadb/columnstore
export MCSDIR
# file used to track / record initialization and prevent subsequent rerun
FLAG="$MCSDIR/etc/container-initialized"

function run_tests(){
        if [  -f "/mnt/config-map/test_cs.sh" ]; then
            CUR_DIR=`pwd`
            cd /mnt/config-map/
            bash ./test_cs.sh
            cd $CUR_DIR
        fi
}

function continuous_test(){
    while true; do
        sleep 5
        $MCSDIR/bin/mcsadmin getSystemInfo
        sleep 5
        run_tests
    done
}

function print_info(){
        $MCSDIR/bin/mcsadmin getSoftwareInfo
        $MCSDIR/bin/mcsadmin getSystemMemory
}

if [ ! -z $MARIADB_CS_DEBUG ]; then
    #set +x
    echo '------------------------------'
    echo 'Starting Singlenode Install'
    echo '------------------------------'
    #set -x
    echo "Waiting for UM to respond"
fi

echo "############### init_singlenode #################"
#start the local dbinit file
/usr/sbin/dbinit 

#this check should immediately pass
ATTEMPT=1
while ! [ -e $FLAG ]; do
    echo -ne "."
    sleep 5
    ATTEMPT=$(($ATTEMPT+1))
done
echo $ATTEMPT


print_info
run_tests
