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

DATADIR="$(_get_config 'datadir' "$@")"
# clean the target dir
rm -rf $DATADIR/*
# move the backup
mv /backup_local/* $DATADIR/
# make sure the permissions are right
chown -R mysql:mysql $DATADIR/
# needed with Mariabackup 10.2 for ensuring that the server will not attempt crash recovery with an old redo log
rm $DATADIR/ib_logfile*
