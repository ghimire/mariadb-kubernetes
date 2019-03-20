mcsmysql -u root 
select mcsSystemReady();
select mcsSystemReadOnly();

create database if not exists ssb;

/*drop table if exists lineorder;
drop table if exists part;
drop table if exists supplier;
drop table if exists customer;
drop table if exists dim_date; */

mcsadmin help
mcsadmin getsystemstatus
mcsadmin getsysteminfo
mcsadmin getsystemi

