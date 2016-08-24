#!/bin/bash
# encoding: UTF-8
#
# Title           :mysql_export_slow_log.sh
# Description     :Export slow log for percona query digest.
# Author          :Nicola Strappazzon C. nicola@swapbytes.com
# Date            :2014-05-28
# Version         :0.3
# ==============================================================================

# Set default values:
DATABASE=
LOGIN_PATH=

# ==============================================================================
# CLI for this script
# ==============================================================================

# Help message of usage this script.
usage()
{
  cat << EOF
  usage: $0

  $0 --login-path=foo --database=bar

  OPTIONS:
    --database      Name of database
    --login-path    Login Path to connect to server
EOF
}

while [ $# -gt 0 ]; do
  case "$1" in
    --database=*)
      DATABASE="${1#*=}"
      ;;
    --login-path=*)
      LOGIN_PATH="${1#*=}"
      ;;
    *)
      printf "Error: Invalid argument.\n"
      usage
      exit 1
  esac
  shift
done

# Validate de minimal arguments required.
if [[ ( ! -n "$DATABASE") ]]
then
  usage
  exit 1
fi

# Check installed basic commands to run this script:
if ( ! type -P 'mysql' > /dev/null )
then
  echo "Not exist mysql command client, please install."
  exit 1
fi

# ==============================================================================
# The script
# ==============================================================================
mysql --login-path=$LOGIN_PATH \
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