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

CREATE USER IF NOT EXISTS 'zeppelin_user'@'%' IDENTIFIED BY 'zeppelin_pass';
GRANT ALL ON bookstore.* TO 'zeppelin_user'@'%';
GRANT ALL ON test.* TO 'zeppelin_user'@'%';
GRANT ALL ON benchmark.* TO 'zeppelin_user'@'%';
GRANT CREATE TEMPORARY TABLES ON infinidb_vtable.* TO 'zeppelin_user'@'%';