/*#Default BLOCKSIZE : 8192 */
/* 2 = snappy compression on */
create database if not exists ssb;

set infinidb_compression_type = 2;
use ssb;

drop table if exists lineorder;
drop table if exists part;
drop table if exists supplier;
drop table if exists customer;
drop table if exists dimdate;


create table part (
        p_partkey int,
        p_name varchar(22),
        p_mfgr varchar(6),
        p_category varchar(7),
        p_brand1 varchar(9),
        p_color varchar(11),
        p_type varchar(25),
        p_size int,
        p_container varchar(10)
) engine=columnstore;

create table supplier (
        s_suppkey int,
        s_name varchar(25),
        s_address varchar(25),
        s_city varchar(10),
        s_nation varchar(15),
        s_region varchar(12),
        s_phone varchar(15)
) engine=columnstore;

create table customer (
        c_custkey int,
        c_name varchar(25),
        c_address varchar(25),
        c_city varchar(10),
        c_nation varchar(15),
        c_region varchar(12),
        c_phone varchar(15),
        c_mktsegment varchar(10)
) engine=columnstore;

create table dimdate (
        d_datekey date,
        d_date varchar(19),
        d_dayofweek varchar(10),
        d_month varchar(10),
        d_year int,
        d_yearmonthnum int,
        d_yearmonth varchar(8),
        d_daynuminweek int,
        d_daynuminmonth int,
        d_daynuminyear int,
        d_monthnuminyear int,
        d_weeknuminyear int,
        d_sellingseason varchar(13),
        d_lastdayinweekfl tinyint,
        d_lastdayinmonthfl tinyint,
        d_holidayfl tinyint,
        d_weekdayfl tinyint
) engine=columnstore;

create table lineorder (
        lo_orderkey bigint, 
        /*int can hold max of 4,294,967,293 only*/
        lo_linenumber int,
        lo_custkey int,
        lo_partkey int,
        lo_suppkey int,
        lo_orderdate date,
        lo_orderpriority varchar(15),
        lo_shippriority varchar(1),
        lo_quantity int,
        /*lo_quantity decimal(12,2),*/
        lo_extendedprice int,
        lo_ordtotalprice int,
        lo_discount int,
        lo_revenue int,
        lo_supplycost int,
        lo_tax int,
        lo_commitdate date,
        lo_shipmode varchar(10)
) engine=columnstore;
