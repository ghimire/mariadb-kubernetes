for i in 1 2 3 4 5
do
   echo "Stream $i"
   nohup psql -vvv -U gpadmin ssb < queries_distributed_lineorder_pgsql.sql > throughput_test_gp_distributed_lineorder_stream$i.log 2>&1 &
done
