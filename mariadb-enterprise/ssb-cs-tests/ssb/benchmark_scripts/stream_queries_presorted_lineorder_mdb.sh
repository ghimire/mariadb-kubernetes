for i in 1 2 3 4 5
do
   echo "Stream $i"
   nohup /home/mariadb-user/mariadb/columnstore/mysql/bin/mysql --defaults-extra-file=/home/mariadb-user/mariadb/columnstore/mysql/my.cnf -u root -vvv < queries_throughput_test_presorted_lineorder_mdb.sql > throughput_test_presorted_lineorder_mdb_stream$i.log 2>&1 &
done
