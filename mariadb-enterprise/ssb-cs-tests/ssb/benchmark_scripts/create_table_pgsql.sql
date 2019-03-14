/*#https://github.com/greenplum-db/gpdb/issues/2025
#BLOCKSIZE={8192-2097152}
#Default BLOCKSIZE : 32768 */

CREATE TABLE orders.part (
  p_partkey     	integer     	,
  p_name        	varchar(22) 	,
  p_mfgr        	varchar(6)      ,
  p_category    	varchar(7)      ,
  p_brand1      	varchar(9)      ,
  p_color       	varchar(11) 	,
  p_type        	varchar(25) 	,
  p_size        	integer     	,
  p_container   	varchar(10)     )
  WITH (APPENDONLY=TRUE, ORIENTATION=COLUMN, COMPRESSTYPE=RLE_TYPE)
  DISTRIBUTED RANDOMLY;
  /*DISTRIBUTED BY (p_partkey);*/

CREATE TABLE orders.supplier (
  s_suppkey     	integer        , 
  s_name        	varchar(25)    ,
  s_address     	varchar(25)    ,
  s_city        	varchar(10)    ,
  s_nation      	varchar(15)    ,
  s_region      	varchar(12)    ,
  s_phone       	varchar(15)    )
  WITH (APPENDONLY=TRUE, ORIENTATION=COLUMN, COMPRESSTYPE=RLE_TYPE)
  DISTRIBUTED RANDOMLY;

CREATE TABLE orders.customer (
  c_custkey     	integer        ,
  c_name        	varchar(25)    ,
  c_address     	varchar(25)    ,
  c_city        	varchar(10)    ,
  c_nation      	varchar(15)    ,
  c_region      	varchar(12)    ,
  c_phone       	varchar(15)    ,
  c_mktsegment          varchar(10)    )
  WITH (APPENDONLY=TRUE, ORIENTATION=COLUMN, COMPRESSTYPE=RLE_TYPE)
  DISTRIBUTED RANDOMLY;

CREATE TABLE orders.dimdate (
  d_datekey            date       ,
  d_date               varchar(19)   ,
  d_dayofweek	       varchar(10)   ,
  d_month      	       varchar(10)   ,
  d_year               integer       ,
  d_yearmonthnum       integer       ,
  d_yearmonth          varchar(8)    ,
  d_daynuminweek       integer       ,
  d_daynuminmonth      integer       ,
  d_daynuminyear       integer       ,
  d_monthnuminyear     integer       ,
  d_weeknuminyear      integer       ,
  d_sellingseason      varchar(13)   ,
  d_lastdayinweekfl    boolean       ,
  d_lastdayinmonthfl   boolean       ,
  d_holidayfl          boolean       ,
  d_weekdayfl          boolean       )
  WITH (APPENDONLY=TRUE, ORIENTATION=COLUMN, COMPRESSTYPE=RLE_TYPE)
  DISTRIBUTED RANDOMLY;

CREATE TABLE orders.lineorder (
  lo_orderkey      	bigint     	, 
  /*int can hold max of 4,294,967,293 only*/
  lo_linenumber        	integer     	,
  lo_custkey           	integer     	,
  lo_partkey           	integer     	,
  lo_suppkey           	integer     	,
  lo_orderdate         	date     	,
  lo_orderpriority     	varchar(15)     ,
  lo_shippriority      	varchar(1)      ,
  lo_quantity          	integer     	,
  lo_extendedprice     	integer     	,
  lo_ordertotalprice   	integer     	,
  lo_discount          	integer     	,
  lo_revenue           	integer     	,
  lo_supplycost        	integer     	,
  lo_tax               	integer     	,
  lo_commitdate         date         ,
  lo_shipmode          	varchar(10)     
)
WITH (APPENDONLY=TRUE, ORIENTATION=COLUMN, COMPRESSTYPE=RLE_TYPE)
DISTRIBUTED RANDOMLY;
/*DISTRIBUTED BY (lo_partkey);*/

CREATE TABLE orders.lineorder_s (
  lo_orderkey      	bigint     	, 
  lo_linenumber        	integer     	,
  lo_custkey           	integer     	,
  lo_partkey           	integer     	,
  lo_suppkey           	integer     	,
  lo_orderdate         	date     	,
  lo_orderpriority     	varchar(15)     ,
  lo_shippriority      	varchar(1)      ,
  lo_quantity          	integer     	,
  lo_extendedprice     	integer     	,
  lo_ordertotalprice   	integer     	,
  lo_discount          	integer     	,
  lo_revenue           	integer     	,
  lo_supplycost        	integer     	,
  lo_tax               	integer     	,
  lo_commitdate         date         ,
  lo_shipmode          	varchar(10)     
)
WITH (APPENDONLY=TRUE, ORIENTATION=COLUMN, COMPRESSTYPE=RLE_TYPE)
DISTRIBUTED BY (lo_orderdate);

CREATE TABLE orders.lineorder_s (
  lo_orderkey           bigint          ,
  lo_linenumber         integer         ,
  lo_custkey            integer         ,
  lo_partkey            integer         ,
  lo_suppkey            integer         ,
  lo_orderdate          date            ,
  lo_orderpriority      varchar(15)     ,
  lo_shippriority       varchar(1)      ,
  lo_quantity           integer         ,
  lo_extendedprice      integer         ,
  lo_ordertotalprice    integer         ,
  lo_discount           integer         ,
  lo_revenue            integer         ,
  lo_supplycost         integer         ,
  lo_tax                integer         ,
  lo_commitdate         date         ,
  lo_shipmode           varchar(10)
)
WITH (APPENDONLY=TRUE, ORIENTATION=COLUMN, COMPRESSTYPE=RLE_TYPE)
DISTRIBUTED BY (lo_orderdate);
