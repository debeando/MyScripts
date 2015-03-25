#!/bin/bash

usage()
{
  cat << EOF
  usage: $0 -h host -u user -p password -d foo

  $0 -h 127.0.0.1 -u root -p admin -d foo

  OPTIONS:
     -h Host
     -u User
     -p Password
     -d Database
EOF
}

while getopts ":h:u:p:d:" OPTION
do
  case $OPTION in
    h)
      HOST=$OPTARG
      ;;
    u)
      USER=$OPTARG
      ;;
    p)
      PASSWORD=$OPTARG
      ;;
    d)
      DATABASE=$OPTARG
      ;;
    ?)
      usage
      exit 1
      ;;
    esac
done

# Define variables:
# -----------------
if [[ ( -z $HOST || -z $USER || -z $PASSWORD || -z $DATABASE ) ]]
then
  usage
  exit 1
fi

if ( ! type -P 'mysql' > /dev/null )
then
  echo "Not exist mysql command client, please install."
  exit 1
fi

mysql -h $HOST \
      -u $USER \
      -p$PASSWORD \
      --raw \
      --skip-column-names \
      --quick \
      --silent \
      --no-auto-rehash \
      --compress \
      -e "$(cat <<-EOF
SELECT CONCAT(
'# Time: ', DATE_FORMAT(start_time, '%y%m%d %H%i:%s'), CHAR(10),
'# User@Host: ', user_host, CHAR(10),
'# Query_time: ', TIME_TO_SEC(query_time),
'  Lock_time: ', TIME_TO_SEC(lock_time),
' Rows_sent: ', rows_sent,
'  Rows_examined: ', rows_examined, CHAR(10),
'SET timestamp=', UNIX_TIMESTAMP(start_time), ';', CHAR(10),
IF(FIND_IN_SET(sql_text, 'Sleep,Quit,Init DB,Query,Field List,Create DB,Drop DB,Refresh,Shutdown,Statistics,Processlist,Connect,Kill,Debug,Ping,Time,Delayed insert,Change user,Binlog Dump,Table Dump,Connect Out,Register Slave,Prepare,Execute,Long Data,Close stmt,Reset stmt,Set option,Fetch,Daemon,Error'),
  CONCAT('# administrator command: ', sql_text), sql_text),
';'
) AS '# slow-log'
FROM mysql.slow_log
WHERE db = '$DATABASE'
  AND sql_text LIKE 'SELECT%';
EOF
)"
echo "#"
