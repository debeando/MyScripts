#!/bin/bash

usage()
{
  cat << EOF
  usage: $0 -h host -u user -p password

  $0 -h 127.0.0.1 -u root -p admin

  OPTIONS:
     -h Host
     -u User
     -p Password
EOF
}

while getopts ":h:u:p:" OPTION
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
    ?)
      usage
      exit 1
      ;;
    esac
done

# Define variables:
# -----------------
if [[ ( -z $HOST || -z $USER || -z $PASSWORD ) ]]
then
  usage
  exit 1
fi

if ( ! type -P 'mysql' > /dev/null )
then
  echo "Not exist mysql command client, please install."
  exit 1
fi

# Skip Repl Error in Prod Slave05:
ERROR=`mysql -h $HOST -u $USER -p$PASSWORD -e 'SHOW SLAVE STATUS\G' | grep Last_SQL_Error | sed -e 's/ *Last_SQL_Error: //'`
if [ -n "$ERROR" ]; then
  echo $(date '+%Y-%m-%d %H:%M:%S')" - MySQL Skip Repl Error: $ERROR"

  mysql -h $HOST \
        -u $USER \
        -p$PASSWORD \
        -e 'CALL mysql.rds_skip_repl_error'
fi
