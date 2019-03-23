CREATE USER IF NOT EXISTS 'zeppelin_user'@'%' IDENTIFIED BY 'zeppelin_pass';
GRANT ALL ON bookstore.* TO 'zeppelin_user'@'%';
GRANT ALL ON test.* TO 'zeppelin_user'@'%';
GRANT ALL ON benchmark.* TO 'zeppelin_user'@'%';
GRANT CREATE TEMPORARY TABLES ON infinidb_vtable.* TO 'zeppelin_user'@'%';
