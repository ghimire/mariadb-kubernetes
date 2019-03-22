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

RESET MASTER;
STOP SLAVE;
CHANGE MASTER TO 
    MASTER_HOST='<<MASTER_HOST>>', 
	MASTER_PORT=3306, 
	MASTER_USER='<<REPLICATION_USERNAME>>', 
	MASTER_PASSWORD='<<REPLICATION_PASSWORD>>', 
	MASTER_USE_GTID=current_pos,
	MASTER_CONNECT_RETRY=0;

START SLAVE;

SET GLOBAL max_connections=10000;
SET GLOBAL gtid_strict_mode=ON;
