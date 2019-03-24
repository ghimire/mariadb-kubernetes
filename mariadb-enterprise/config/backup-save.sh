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

BACKUP_DIR=backup-$HOSTNAME-$(date +%Y-%m-%d-%H-%M-%S)

echo "The backup will be in $BACKUP_DIR"

BACKUP_DIR=/backup-storage/$BACKUP_DIR

mkdir -p $BACKUP_DIR

if [[ "$CLUSTER_TOPOLOGY" == "standalone" ]] || [[ "$CLUSTER_TOPOLOGY" == "masterslave" ]]; then
    mariabackup --backup --target-dir=$BACKUP_DIR --user=root
elif [[ "$CLUSTER_TOPOLOGY" == "galera" ]]; then
    mariabackup --backup --galera-info --target-dir=$BACKUP_DIR --user=root
fi

mariabackup --prepare --target-dir=$BACKUP_DIR --user=root