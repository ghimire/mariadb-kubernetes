RED_CD="\033[0;31m"
GREEN_CD="\033[0;32m"
NORMAL_CD="\033[0m"
export FAIL_STRING="@@failure@@"
export PASS_MSG="$GREEN_CD ✔ Pass $NORMAL_CD"
export FAIL_MSG="$RED_CD ✘ Fail $NORMAL_CD"
start_tst()
{
    FAILED=0
    declare -a tsts=("${!1}")
    spacer=''
    echo ""
    if [ ! -z "$2" ]; then
        for ((i=0;i<=$2;i++));do spacer="$spacer "; done;
    fi
    for (( i=0; i<${#tsts[@]}; i=$i+2 ));
    do
        test=${tsts[$i]}
        test_name=${tsts[$i+1]}
        echo -ne "$spacer"[$(($i/2+1))/$((${#tsts[@]}/2))] ${test_name} ""
        if eval "$test"; then
            echo -ne "$PASS_MSG\r\n"
        else
            FAILED=$(($FAILED+1))
            echo -ne "$FAIL_MSG\r\n"
        fi
    done
    if [[ $FAILED -gt 0 ]]; then
        echo "$FAILED failed tests."
        if [ -z $MARIADB_CS_DEBUG ]; then
            exit 1
        fi
    fi
}

export MCSDIR=/usr/local/mariadb/columnstore

export MARIADB_ROOT_PASSWORD='this is an example test password'
export MARIADB_USER='0123456789012345'
export MARIADB_PASSWORD='my cool mariadb password'
export MARIADB_DATABASE='bookstore'
sed -i s/\#\#test_db_name\#\#/"$MARIADB_DATABASE"/g ./initdb.sql
sed -i s/\#\#test_user_name\#\#/"$MARIADB_USER"/g ./initdb.sql
sed -i s/\#\#test_user_pass\#\#/"$MARIADB_PASSWORD"/g ./initdb.sql
sed -i s/\#\#test_bookstore_db\#\#/"$MARIADB_DATABASE"/g ./initdb.sql

echo "Running tests"
FAIL_STRING="@@failure@@"
mysql() {
    res=$($MCSDIR/mysql/bin/mysql --defaults-extra-file=$MCSDIR/mysql/my.cnf \
    --host="$MARIADB_HOST" \
    --user=''"${MARIADB_USER}"'' \
    --password=''"${MARIADB_PASSWORD}"''  \
    --silent \
    --protocol=TCP \
    ''"$1"'' \
    -e "$2" )
    if [ $? -eq 0 ]; then
        echo $res
    else
        echo $FAIL_STRING
    fi
}
if [ ! -z $MARIADB_CS_DEBUG ]; then
    #set +x
    echo '-------------------------'
    echo 'Running test suite'
    echo '-------------------------'
    echo 'IP:'$MY_IP
    #set -x
fi
if [ ! -z $MARIADB_CS_DEBUG ]; then
    $MCSDIR/mysql/bin/mysql --defaults-extra-file=$MCSDIR/mysql/my.cnf -uroot < ./initdb.sql -v
else
    $MCSDIR/mysql/bin/mysql --defaults-extra-file=$MCSDIR/mysql/my.cnf -uroot < ./initdb.sql
fi


tests+=( "[ \$(mysql \"$MARIADB_DATABASE\" 'SELECT CURRENT_USER();') = \"$MARIADB_USER@localhost\" ]" "Testing SELECT CURRENT_USER();. Expected: $MARIADB_USER@localhost" )
tests+=( "[ \$(mysql \"$MARIADB_DATABASE\" 'SELECT 1') = 1 ]" "Testing SELECT 1. Expected: 1" )
tests+=( "[ \$(mysql \"$MARIADB_DATABASE\" 'SELECT 1') = 1 ]" "Testing SELECT 1. Expected: 1" )
tests+=( "[ \$(mysql \"$MARIADB_DATABASE\" 'SELECT 1') = 1 ]" "Testing SELECT 1. Expected: 1" )
tests+=( "[ \$(mysql \"$MARIADB_DATABASE\" 'SELECT COUNT(*) FROM test') = 1 ]" "Testing SELECT COUNT(*) FROM test. Expected: 1" )
tests+=( "[ \$(mysql \"$MARIADB_DATABASE\" 'SELECT c FROM test') == 'goodbye!' ]" "Testing SELECT c FROM test. Expected: goodbye!" )
{{- if .Values.mariadb.columnstore.sandbox}}
tests+=( "[ \$(mysql \"$MARIADB_DATABASE\" 'SELECT price from transactions WHERE transaction_type = 1 ORDER BY price LIMIT 1') == "1.49" ]" "Testing SELECT price from transactions WHERE transaction_type = 1 ORDER BY price LIMIT 1;. Expected: 1.49" )
tests+=( "[ \$(mysql \"$MARIADB_DATABASE\" 'SELECT COUNT(*) FROM addresses') = 2666749 ]" "Testing SELECT COUNT(*) FROM addresses. Expected: 2666749" )
tests+=( "[ \$(mysql \"$MARIADB_DATABASE\" 'SELECT COUNT(*) FROM books') = 5001 ]" "Testing SELECT COUNT(*) FROM books. Expected: 5001" )
tests+=( "[ \$(mysql \"$MARIADB_DATABASE\" 'SELECT COUNT(*) FROM cards') = 1604661 ]" "Testing SELECT COUNT(*) FROM cards. Expected: 1604661" )
tests+=( "[ \$(mysql \"$MARIADB_DATABASE\" 'SELECT COUNT(*) FROM covers') = 20 ]" "Testing SELECT COUNT(*) FROM covers. Expected: 20" )
tests+=( "[ \$(mysql \"$MARIADB_DATABASE\" 'SELECT COUNT(*) FROM customers') = 2005397 ]" "Testing SELECT COUNT(*) FROM customers. Expected: 2005397" )
tests+=( "[ \$(mysql \"$MARIADB_DATABASE\" 'SELECT COUNT(*) FROM emails') = 2566571 ]" "Testing SELECT COUNT(*) FROM emails. Expected: 2566571" )
tests+=( "[ \$(mysql \"$MARIADB_DATABASE\" 'SELECT COUNT(*) FROM loyaltypoints') = 923008 ]" "Testing SELECT COUNT(*) FROM loyaltypoints. Expected: 923008" )
tests+=( "[ \$(mysql \"$MARIADB_DATABASE\" 'SELECT COUNT(*) FROM maritalstatuses') = 5 ]" "Testing SELECT COUNT(*) FROM maritalstatuses. Expected: 5" )
tests+=( "[ \$(mysql \"$MARIADB_DATABASE\" 'SELECT COUNT(*) FROM phones') = 2427033 ]" "Testing SELECT COUNT(*) FROM phones. Expected: 2427033" )
tests+=( "[ \$(mysql \"$MARIADB_DATABASE\" 'SELECT COUNT(*) FROM transactions') = 11279171 ]" "Testing SELECT COUNT(*) FROM transactions. Expected: 11279171" )
tests+=( "[ \$(mysql \"$MARIADB_DATABASE\" 'SELECT COUNT(*) FROM transactiontypes') = 3 ]" "Testing SELECT COUNT(*) FROM transactiontypes. Expected: 3" )
tests+=( "[ \$(mysql \"$MARIADB_DATABASE\" 'SELECT price from transactions WHERE transaction_type = 1 ORDER BY price LIMIT 1') == "1.49" ]" "Testing SELECT price from transactions WHERE transaction_type = 1 ORDER BY price LIMIT 1;. Expected: 1.49" )
tests+=( "[ \$(mysql \"$MARIADB_DATABASE\" 'SELECT sum(price) FROM transactions') == "115003016.41" ]" "Testing SELECT sum(price) FROM transactions. Expected: 115003016.41" )
tests+=( "[ \$(mysql \"$MARIADB_DATABASE\" 'SELECT DISTINCT count(customer_id) from transactions') == "11279171" ]" "Testing SELECT DISTINCT count(customer_id) from transactions. Expected: 11279171" )
tests+=( "[ \$(mysql \"$MARIADB_DATABASE\" 'SET @@max_length_for_sort_data = 501;SELECT p.p FROM (SELECT bookname,category, sum(cover_price) p from books group by bookname,category) p ORDER BY category LIMIT 1') == $FAIL_STRING ]" "Testing limited sort. Expected: FAIL" )
tests+=( "[ \$(mysql \"$MARIADB_DATABASE\" 'SET @@max_length_for_sort_data = 5001;SELECT p.p FROM (SELECT bookname,category, sum(cover_price) p from books group by bookname,category) p ORDER BY bookname,category LIMIT 1') == "11.89" ]" "Testing within the limit. Expected: 11.89" )

#TODO: replace this test with kubectl exec 
#tests+=( "[ \$(docker exec -i $cname_um1 wc -l /var/log/mariadb/columnstore/info.log | cut -d ' ' -f 1) -gt 0 ]" "Testing log at /var/log/mariadb/columnstore/info.log. Expected: some rows" )
{{- end}}
start_tst tests[@] 3


if [ ! -z $MARIADB_CS_DEBUG ]; then
    TEST_TIMOUT=15
    while true; do 
    echo ""
    echo "Repeat test in $TEST_TIMOUT ...."
    echo ""
    
    sleep $TEST_TIMOUT
    $MCSDIR/bin/mcsadmin getSoftwareInfo
    $MCSDIR/bin/mcsadmin getSystemMemory
    start_tst tests[@] 3
    done
fi