#!/bin/bash
# encoding: UTF-8
#
# Title           :mysql_skip_replication_error.sh
# Description     :MySQL Skip Replication Error.
# Author          :Nicola Strappazzon C. nicola@swapbytes.com
# Date            :2016-02-26
# Version         :0.1
# ==============================================================================

# Set default values:
LOGIN_PATH=

# ==============================================================================
# CLI for this script
# ==============================================================================

# Help message of usage this script.
usage()
{
  cat << EOF
  usage: $0

  $0 --login-path=foo

  OPTIONS:
    --login-path Login Path to connect to server
EOF
}

log()
{
  MESSAGE=$1
  echo "$(date '+%Y-%m-%d %H:%M:%S') - ${MESSAGE}"
}

while [ $# -gt 0 ]; do
  case "$1" in
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

# Check installed basic commands to run this script:
if ( ! type -P 'mysql' > /dev/null )
then
  echo "Can't find the mysql client command, please install."
  exit 1
fi

# ==============================================================================
# The script
# ==============================================================================

# Skip Repl Error in Prod Slave05:
ERROR=$(mysql --login-path="$LOGIN_PATH" \
             -Bse 'SHOW SLAVE STATUS\G' \
        | \
        grep 'Last_SQL_Error:' \
        | \
        sed -e 's/ *Last_SQL_Error: //')

if [ -n "$ERROR" ]; then
  log "$ERROR"

  mysql --login-path="$LOGIN_PATH" \
        -Bse 'STOP SLAVE; SET GLOBAL SQL_SLAVE_SKIP_COUNTER = 1; START SLAVE;'
else
  SBM=$(mysql --login-path="$LOGIN_PATH" \
           -Bse 'SHOW SLAVE STATUS\G' \
       | \
       grep Seconds_Behind_Master \
       | \
       sed -e 's/ *Seconds_Behind_Master: //')
  log "Seconds Behind Master: ${SBM}"
fi