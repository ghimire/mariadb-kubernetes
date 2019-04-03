#!/bin/bash

backup_dir="/backup-storage/"$RESTORE_FROM_FOLDER"/"$( hostname )
columnstore_dir="/mnt/columnstore"
# file used to track / record backup and prevent subsequent rerun
RESTORE_FLAG="$columnstore_dir/etc/backup-restored"

# check if restore was already done and pod is just restarted
if [ -e $RESTORE_FLAG ]; then
    echo "backup already restored, restore process will be skipped"
    exit 0
fi

error_counter=0

# check that the backup directories exist
if [ ! -d $backup_dir ]; then
    echo "error: backup dir $backup_dir doesn't exist"
    error_counter=$((error_counter+1))
fi

if [[ "$MARIADB_CS_NODE" == "UM" ]]; then
    declare -a directories_to_check=("etc" "data" "local" "mysql/db")
else
    declare -a directories_to_check=("etc" "data" "local")
fi
for dir in "${directories_to_check[@]}"; do
    if [ ! -d $backup_dir/$dir ]; then
        echo "error: backup directory $backup_dir/$dir does not exists."
        error_counter=$((error_counter+1))
    fi
done
if [[ "$MARIADB_CS_NODE" == "PM" ]]; then
    restore_DBRootCount=$(xmllint --xpath 'string(//DBRootCount)' $backup_dir/etc/Columnstore.xml)
    for i in $(seq 1 $restore_DBRootCount); do
        if [ ! -d $backup_dir/data$i ]; then
            echo "error: backup directory $backup_dir/data$i does not exists."
            error_counter=$((error_counter+1))
        fi
    done
fi

# check that the target directory exists
if [ ! -d $columnstore_dir ]; then
    echo "error: target directory $columnstore_dir does not exist"
    error_counter=$((error_counter+1))
fi

# check that the target directory is empty (we are not overwriting an existing instance)
declare -a directories_to_check=("etc" "data" "local" "mysql/db")
for dir in "${directories_to_check[@]}"; do
    if [ -d $columnstore_dir/$dir ]; then
        echo "error: target directory $columnstore_dir/$dir exists."
        echo "       a backup can't be restored to an already initialized pod"
        error_counter=$((error_counter+1))
    fi
done
for i in $(seq 1 $restore_DBRootCount); do
    if [ -d $columnstore_dir/data$i ]; then
        echo "error: target directory $columnstore_dir/data$i exists."
        echo "       a backup can't be restored to an already initialized pod"
        error_counter=$((error_counter+1))
    fi
done

# check that the target direcotry is writeable
if [ -d $columnstore_dir ]; then
    touch $columnstore_dir/write_test
    if [ $? -ne 0 ]; then
        echo "error: can't write to target directory $columnstore_dir"
        error_counter=$((error_counter+1))
    else
        rm -f $columnstore_dir/write_test
    fi
fi

# check that there is enough free space in the target directory
if [ -d $backup_dir ] && [ -d $columnstore_dir ]; then
    backup_size=$( du $backup_dir -s -b | cut -d$'\t' -f1 )
    target_space=$( df -B1 $columnstore_dir | awk 'NR==2 {print $4}' )
    if [ $backup_size -gt $target_space ]; then
        echo "error: not enough space available on directory $columnstore_dir to restore the backup"
        echo "       backup size: $backup_size Bytes"
        echo "       available space: $target_space Bytes"
        error_counter=$((error_counter+1))
    fi
fi

# check if the ColumnStore versions of backup and target match
source $backup_dir/releasenum
backupVersion=$version
backupRelease=$release
source /usr/local/mariadb/columnstore/releasenum
targetVersion=$version
targetRelease=$release

if [  "$backupVersion" != "$targetVersion" ] || [ "$backupRelease" != "$targetRelease" ]; then
    echo "error: you are trying to restore a backup that was taken from a different ColumnStore release"
    echo "       backup version: $backupVersion.$backupRelease"
    echo "       target version: $targetVersion.$targetRelease"
    error_counter=$((error_counter+1))
fi

# start with the restore process if all tests passed
if [ $error_counter -gt 0 ]; then
    exit $error_counter
fi

echo "All preliminary tests passed, starting the restore process."

cp -rvp $backup_dir/* $columnstore_dir
if [ $? -ne 0 ]; then
    echo "error: the backup files coulnd't be copied to the pod"
    error_counter=$((error_counter+1))
fi
rm -f $columnstore_dir/releasenum
if [ $? -ne 0 ]; then
    echo "error: the file $columnstore_dir/releasenum couldn't be deleted"
    error_counter=$((error_counter+1))
fi
if [ -d $columnstore_dir/mysql/db ]; then
    chown -R mysql:mysql $columnstore_dir/mysql/db
    if [ $? -ne 0 ]; then
        echo "error: wasn't able to transfer the ownership of $columnstore_dir/mysql/db to the user mysql:mysql"
        error_counter=$((error_counter+1))
    fi
fi
echo "restore process finished"
exit $error_counter
