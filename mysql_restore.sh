#!/bin/bash 

## Today's date
DMY=$(date | awk '{ print $3"-"$2"-"$6 }')
EMAIL="abc@xyz.com"

## Credentials & paths ##
DBUSER=""
DBPASS=""
DBNAME=""
TEMPDIR="/opt/infra/backups/sql_temp"
BACKUPDIR="/opt/infra/backups/compressed_temp"
FILENAME=$DBNAME-$DMY

## Bucket details:
BUCKET_NAME="xyz"

## Downloading tar files in compressed folder
aws s3 cp s3://$BUCKET_NAME/$FILENAME.tar.gz $BACKUPDIR/

## Extracting the backup to a directory.
tar -xvf $BACKUPDIR/$FILENAME.tar.gz -C $TEMPDIR/

## Greping DBs list that we want to restore ##

for DATABASE in $(mysql -u$DBUSER -p$DBPASS -e"show databases" | grep -wE "($DBNAME)")
do
	mysql -u$DBUSER -p$DBPASS $DATABASE < $TEMPDIR/$DBNAME.sql

	RESTORE=$?
	if [ $RESTORE -eq 0 ]
        then
                echo "Restore was successful for $DATABASE"
        else
                echo "Mysql Restore failed for $DATABASE" | mail -s "Mysql Restore failed" $EMAIL
        fi
done
