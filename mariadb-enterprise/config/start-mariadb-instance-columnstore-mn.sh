#!/usr/bin/bash
# Copyright (c) 2018-2019 MariaDB Corporation Ab
# 
# Use of this software is governed by the Business Source License included
# in the LICENSE.TXT file and at www.mariadb.com/bsl11.
#
# Change Date: 2023-04-01
# 
# On the date above, in accordance with the Business Source License, use
# of this software will be governed by version 3 or later of the General
# Public License.
#
# Starts and initializes a MariaDB columnstore instance

MASTER_HOST="<<MASTER_HOST>>"
ADMIN_USERNAME="<<ADMIN_USERNAME>>"
ADMIN_PASSWORD="<<ADMIN_PASSWORD>>"
REPLICATION_USERNAME="<<REPLICATION_USERNAME>>"
REPLICATION_PASSWORD="<<REPLICATION_PASSWORD>>"
RELEASE_NAME="<<RELEASE_NAME>>"
CLUSTER_ID="<<CLUSTER_ID>>"
export MARIADB_CS_DEBUG="<<MARIADB_CS_DEBUG>>"
export MAX_TRIES=60
#Get last digit of the hostname
MY_HOSTNAME=$(hostname)
SPLIT_HOST=(${MY_HOSTNAME//-/ }); 
CONT_INDEX=${SPLIT_HOST[(${#SPLIT_HOST[@]}-1)]}
MY_IP=$(ifconfig | grep -Eo 'inet (addr:)?([0-9]*\.){3}[0-9]*' | grep -Eo '([0-9]*\.){3}[0-9]*' | grep -v '127.0.0.1')

if [ ! -z $MARIADB_CS_DEBUG ]; then
    #set +x
    echo '-------------------------'
    echo 'Start CS Module Container'
    echo '-------------------------'
    echo 'IP:'$MY_IP
    #set -x
fi

PREFIX_REPLICATION="2\n1\nn\ny\ncolumnstore-1\n1\n" 
PREFIX_NO_REPLICATION="2\n1\nn\nn\ncolumnstore-1\n1\n"
PREFIX=$PREFIX_NO_REPLICATION
CS_SERVICE="$RELEASE_NAME-mdb-clust"
UM_COUNT={{ .Values.mariadb.columnstore.um.replicas }}
PM_COUNT={{ .Values.mariadb.columnstore.pm.replicas }}
UM_HOST="$RELEASE_NAME-mdb-cs-um-module-"
PM_HOST="$RELEASE_NAME-mdb-cs-pm-module-"

function ping_hosts() { 
    RET_CD=0
    for i in `seq 0 $(( UM_COUNT-1 ))`
    do
        if [ ! -z $MARIADB_CS_DEBUG ]; then
            ping -c 1 $UM_HOST$i.$CS_SERVICE 2>&1 >/dev/null
        else
            ping -c 1 $UM_HOST$i.$CS_SERVICE >/dev/null 2>&1 >/dev/null
        fi
        if [[ $? -gt 0 ]]; then
            RET_CD=$(( RET_CD+1 ))
        fi
    done
    for i in `seq 0 $(( PM_COUNT-1 ))`
    do
        if [ ! -z $MARIADB_CS_DEBUG ]; then
            ping -c 1 $PM_HOST$i.$CS_SERVICE 2>&1 >/dev/null
        else
            ping -c 1 $PM_HOST$i.$CS_SERVICE >/dev/null 2>&1 >/dev/null
        fi
        if [[ $? -gt 0 ]]; then
            RET_CD=$(( RET_CD+1 ))
        fi
    done
    return "$RET_CD"
}

function wait_ping_hosts() {
    ping_hosts
    hosts_down=$?
    while [[ $hosts_down -gt 0 ]]; do
        if [ ! -z $MARIADB_CS_DEBUG ]; then
            echo "$hosts_down hosts still down. Retrying ..."
        fi
        sleep 10
        ping_hosts
        hosts_down=$?
    done
    if [ ! -z $MARIADB_CS_DEBUG ]; then
        echo "All $((UM_COUNT+PM_COUNT)) hosts up ("$UM_COUNT"UM "$PM_COUNT"PM)"
    fi
}

function build_post_config_input() { 
    MODULES=""
    MODULES="$MODULES$UM_COUNT\n"
    for i in `seq 0 $(( UM_COUNT-1 ))`
    do
        IP=$(get_IP_from_ping $UM_HOST$i.$CS_SERVICE)
        MODULES="$MODULES$UM_HOST$i.$CS_SERVICE\n\n\n"
    done
    MODULES="$MODULES$PM_COUNT\n"
    for i in `seq 0 $(( PM_COUNT-1 ))`
    do
        IP=$(get_IP_from_ping $PM_HOST$i.$CS_SERVICE)
        MODULES="$MODULES$PM_HOST$i.$CS_SERVICE\n\n\n$(( i+1 ))\n"
    done
    echo "$PREFIX$MODULES"
}

function get_IP_from_ping() {
    ATTEMPT=1
    RET_IP=$(ping -q -c 1 -t 5 "$1" | grep PING | sed -e "s/).*//" | sed -e "s/.*(//")
    while [ -z "$RET_IP" ] && [ $ATTEMPT -le 5 ]; do
        PING_DEBUG="$PING_DEBUG\n-- Ping failed to resolve $ATTEMPT host ("$1")! --"
        sleep 2
        ATTEMPT=$(($ATTEMPT+1))
        RET_IP=$(ping -q -c 1 -t 5 "$1" | grep PING | sed -e "s/).*//" | sed -e "s/.*(//")
        #RET_IP=$( host $IP | sed -e "s/.*\ //" )
    done
    echo $RET_IP
}


# get server id from hostname, it will have the format <something>-<id>
[[ $(hostname) =~ -([0-9]+)$ ]] || exit 1
server_id=${BASH_REMATCH[1]}

# load backup
if [[ ! "$BACKUP_RESTORE_FROM" == "" ]]; then
    if [[ "$MASTER_HOST" == "localhost" ]]; then
        chown -R mysql:mysql /backup-storage/$RESTORE_FROM_FOLDER
    fi
fi


if [[ "$MARIADB_CS_NODE" == "UM" && -f "/mnt/config-map/master" ]]; then
    export MARIADB_CS_MASTER="$(cat /mnt/config-map/master)"
fi

#what else can it be in this file
if [[ "$CLUSTER_TOPOLOGY" == "columnstore" ]]; then
    if [ ! -z $MARIADB_CS_DEBUG ]; then
        echo "StartColumnstore"
        echo "$MARIADB_CS_NODE:$MY_IP"
        echo "Master:$MARIADB_CS_MASTER"
        echo "IP:$MY_IP"
    fi
    if [[ "$MARIADB_CS_NODE" == "UM" && -f "/mnt/config-map/master" ]]; then
        export MARIADB_CS_MASTER="$(cat /mnt/config-map/master)"
    fi

    if [[ "$MARIADB_CS_NODE" == "UM" ]]; then
        if [[ "$CONT_INDEX" -eq 0 ]]; then
            wait_ping_hosts
            #Init master
            echo "UM Master"
            sh /mnt/config-map/cs_init.sh 2>&1 &
            exec /usr/sbin/runsvdir-start
        else
            #Init slave
            echo "UM Slave"
            sh /mnt/config-map/cs_init.sh 2>&1 &
            exec /usr/sbin/runsvdir-start
        fi
    elif [[ "$MARIADB_CS_NODE" == "PM" ]]; then
        #if [[ "$CONT_INDEX" -eq $(( PM_COUNT-1 )) ]]; then
        if [[ "$CONT_INDEX" -eq 0 ]]; then
            #First PM
            echo "Frst PM"
            echo "Starting postConfiguration"
            fi
            wait_ping_hosts
            MARIADB_CS_POSTCFG_INPUT=$(build_post_config_input)
            if [ ! -z $MARIADB_CS_DEBUG ]; then
                echo $PING_DEBUG
                echo $MARIADB_CS_POSTCFG_INPUT
            fi
            sh /mnt/config-map/cs_init.sh 2>&1 &
            exec /usr/sbin/runsvdir-start
        else
            #Any other PM
            echo "PM node"
            fi
            sh /mnt/config-map/cs_init.sh 2>&1 &
            exec /usr/sbin/runsvdir-start
        fi
    fi
fi
echo "Defaulted to sleep something is wrong"
sleep 3600